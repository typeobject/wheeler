package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Global;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ValueType;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Embedded capsule startup identity, capability, I/O, and execution evidence. */
final class ApplicationCapsuleLauncherTest {
  @Test
  void executesOneVerifiedNoAuthorityRootExactlyOnce() {
    ApplicationCapsule capsule = capsule(counter(), List.of(), List.of());
    ApplicationCapsuleLauncher.LaunchContext context = context(
        capsule,
        List.of(),
        ApplicationCapsuleLauncher.InputMode.NONE,
        null,
        -1);

    ApplicationCapsuleLauncher.CapsuleExecution result =
        ApplicationCapsuleLauncher.launch(capsule.canonicalBytes(), context);

    assertEquals(capsule.identity(), result.capsuleIdentity());
    assertEquals(hash(1), result.packageInstance());
    assertEquals("app", result.target());
    assertEquals("example.app::main", result.entryFunction());
    assertEquals(7, result.execution().globals().get("count"));
    assertEquals(2, result.execution().workflowSteps());
  }

  @Test
  void bindsExactUtf8BinaryAndOutputCapabilities() {
    byte[] utf8 = "A¢".getBytes(StandardCharsets.UTF_8);
    ApplicationCapsule utf8Capsule = capsule(
        effectProgram(ValueType.UTF8_BORROW), List.of("io:stdin/1"), List.of());
    ApplicationCapsule binaryCapsule = capsule(
        effectProgram(ValueType.BYTE_VIEW), List.of("io:stdin/1"), List.of());
    ApplicationCapsule outputCapsule = capsule(
        effectProgram(ValueType.BYTES_BORROW), List.of("io:stdout/1"), List.of());
    ApplicationCapsule duplexCapsule = capsule(
        effectProgram(List.of(ValueType.UTF8_BORROW, ValueType.BYTES_BORROW)),
        List.of("io:stdin/1", "io:stdout/1"),
        List.of());

    ApplicationCapsuleLauncher.LaunchContext utf8Context = context(
        utf8Capsule,
        List.of("io:stdin/1"),
        ApplicationCapsuleLauncher.InputMode.UTF8,
        utf8,
        -1);
    utf8[0] = 'Z';
    assertArrayEquals("A¢".getBytes(StandardCharsets.UTF_8), utf8Context.input());
    assertEquals(1, ApplicationCapsuleLauncher.launch(
        utf8Capsule.canonicalBytes(), utf8Context).execution().workflowSteps());
    assertEquals(1, ApplicationCapsuleLauncher.launch(
        binaryCapsule.canonicalBytes(),
        context(
            binaryCapsule,
            List.of("io:stdin/1"),
            ApplicationCapsuleLauncher.InputMode.BINARY,
            utf8,
            -1)).execution().workflowSteps());
    ApplicationCapsuleLauncher.CapsuleExecution output = ApplicationCapsuleLauncher.launch(
        outputCapsule.canonicalBytes(),
        context(
            outputCapsule,
            List.of("io:stdout/1"),
            ApplicationCapsuleLauncher.InputMode.NONE,
            null,
            4));
    assertArrayEquals(new byte[4], output.execution().output());
    ApplicationCapsuleLauncher.CapsuleExecution duplex = ApplicationCapsuleLauncher.launch(
        duplexCapsule.canonicalBytes(),
        context(
            duplexCapsule,
            List.of("io:stdin/1", "io:stdout/1"),
            ApplicationCapsuleLauncher.InputMode.UTF8,
            utf8,
            4));
    assertArrayEquals(new byte[4], duplex.execution().output());
  }

  @Test
  void rejectsChangedIdentityProfileGrantAndInputModeBeforeExecution() {
    ApplicationCapsule capsule = capsule(
        effectProgram(ValueType.UTF8_BORROW), List.of("io:stdin/1"), List.of());
    ApplicationCapsuleLauncher.LaunchContext valid = context(
        capsule,
        List.of("io:stdin/1"),
        ApplicationCapsuleLauncher.InputMode.UTF8,
        new byte[0],
        -1);
    CapsuleRoot root = capsule.root();

    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            capsule.canonicalBytes(),
            new ApplicationCapsuleLauncher.LaunchContext(
                hash(99),
                root.runtimeProfile(),
                root.bytecodeProfile(),
                root.proofProfile(),
                root.targetProfile(),
                root.platformAbi(),
                root.executionLimits(),
                valid.grantedCapabilities(),
                valid.inputMode(),
                valid.input(),
                valid.outputBytes())));
    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            capsule.canonicalBytes(),
            new ApplicationCapsuleLauncher.LaunchContext(
                valid.capsuleIdentity(),
                hash(98),
                root.bytecodeProfile(),
                root.proofProfile(),
                root.targetProfile(),
                root.platformAbi(),
                root.executionLimits(),
                valid.grantedCapabilities(),
                valid.inputMode(),
                valid.input(),
                valid.outputBytes())));
    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            capsule.canonicalBytes(),
            context(
                capsule,
                List.of(),
                ApplicationCapsuleLauncher.InputMode.UTF8,
                new byte[0],
                -1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            capsule.canonicalBytes(),
            context(
                capsule,
                List.of("io:stdin/1"),
                ApplicationCapsuleLauncher.InputMode.BINARY,
                new byte[0],
                -1)));
  }

  @Test
  void rejectsAotUnverifiedPayloadKindsAndCapabilityDrift() {
    ApplicationCapsule aot = capsule(
        counter(), List.of(), List.of(), NativeImagePlan.RuntimeMode.AOT);
    CapsuleEntry provider = new CapsuleEntry(
        CapsuleEntry.Kind.NATIVE_PROVIDER,
        "providers/native.a",
        8,
        CapsuleEntry.REQUIRED,
        new byte[] {1});
    ApplicationCapsule providerCapsule = capsule(counter(), List.of(), List.of(provider));
    ApplicationCapsule excessCapability = capsule(
        counter(), List.of("io:stdout/1"), List.of());

    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            aot.canonicalBytes(),
            context(aot, List.of(), ApplicationCapsuleLauncher.InputMode.NONE, null, -1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            providerCapsule.canonicalBytes(),
            context(
                providerCapsule,
                List.of(),
                ApplicationCapsuleLauncher.InputMode.NONE,
                null,
                -1)));
    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleLauncher.launch(
            excessCapability.canonicalBytes(),
            context(
                excessCapability,
                List.of("io:stdout/1"),
                ApplicationCapsuleLauncher.InputMode.NONE,
                null,
                -1)));
  }

  private static ApplicationCapsule capsule(
      Program program,
      List<String> capabilities,
      List<CapsuleEntry> additions) {
    return capsule(program, capabilities, additions, NativeImagePlan.RuntimeMode.EMBEDDED_VM);
  }

  private static ApplicationCapsule capsule(
      Program program,
      List<String> capabilities,
      List<CapsuleEntry> additions,
      NativeImagePlan.RuntimeMode mode) {
    byte[] wbc = new BytecodeWriter().write(program);
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "app",
        "bin/app.wbc",
        program.function(program.entryFunctionId()).name(),
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
        hash(7),
        mode,
        capabilities);
    CapsulePackageReceipt receipt = new CapsulePackageReceipt(
        hash(8),
        "wheeler.app@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "app",
        hash(1));
    ArrayList<CapsuleEntry> entries = new ArrayList<>(additions);
    entries.add(new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        "bin/app.wbc",
        8,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        wbc));
    return new ApplicationCapsule(root, List.of(receipt), entries);
  }

  private static ApplicationCapsuleLauncher.LaunchContext context(
      ApplicationCapsule capsule,
      List<String> capabilities,
      ApplicationCapsuleLauncher.InputMode inputMode,
      byte[] input,
      int outputBytes) {
    CapsuleRoot root = capsule.root();
    return new ApplicationCapsuleLauncher.LaunchContext(
        capsule.identity(),
        root.runtimeProfile(),
        root.bytecodeProfile(),
        root.proofProfile(),
        root.targetProfile(),
        root.platformAbi(),
        root.executionLimits(),
        capabilities,
        inputMode,
        input,
        outputBytes);
  }

  private static Program counter() {
    FunctionBody main = new FunctionBody(
        0,
        "example.app::main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.ADD_CONST, 0, 7), Instruction.of(Opcode.HALT)),
        List.of());
    return new Program(
        "example.app", 0, List.of(new Global("count", 0)), List.of(main));
  }

  private static Program effectProgram(ValueType parameter) {
    return effectProgram(List.of(parameter));
  }

  private static Program effectProgram(List<ValueType> parameters) {
    FunctionBody main = new FunctionBody(
        0,
        "example.app::main",
        false,
        parameters.size(),
        parameters,
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    return new Program("example.app", 0, List.of(), List.of(main));
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }
}
