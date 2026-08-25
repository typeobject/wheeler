package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.ElfImage;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import com.typeobject.wheeler.packageformat.PlatformAbi;
import com.typeobject.wheeler.runtime.ApplicationCapsuleLauncher;
import com.typeobject.wheeler.runtime.ApplicationCapsuleVerifier;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Builds one closed application capsule and binds it into a native image plan. */
final class ApplicationCapsuleExampleTest {
  @Test
  void bindsOneVerifiedCapsuleWithoutAdjacentFiles() {
    String source = """
        module example.hello;
        classical class Hello {
          entry void main() {}
        }
        """;
    byte[] artifact = new WheelerCompiler().compileModulesToBytecode(
        Map.of("example.hello", source), "example.hello");
    byte[] greeting = "hello from Wheeler\n".getBytes(StandardCharsets.UTF_8);
    byte[] runtimeText = {
        (byte) 0xb8, 0x3c, 0, 0, 0, 0x31, (byte) 0xff, 0x0f, 0x05
    };
    PlatformAbi abi = platformAbi();
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "hello",
        "bin/hello.wbc",
        "example.hello::main",
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        abi.identity(),
        hash(7),
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        List.of());
    CapsulePackageReceipt receipt = new CapsulePackageReceipt(
        hash(8),
        "wheeler.hello@1.0.0",
        hash(9),
        "release",
        hash(10),
        hash(11),
        "hello",
        hash(1));
    CapsuleEntry wbc = new CapsuleEntry(
        CapsuleEntry.Kind.WBC,
        "bin/hello.wbc",
        4096,
        CapsuleEntry.REQUIRED | CapsuleEntry.STARTUP,
        artifact);
    CapsuleEntry resource = new CapsuleEntry(
        CapsuleEntry.Kind.RESOURCE,
        "resources/greeting.txt",
        64,
        CapsuleEntry.REQUIRED,
        greeting);
    ApplicationCapsule capsule =
        new ApplicationCapsule(root, List.of(receipt), List.of(resource, wbc));

    ApplicationCapsuleVerifier.VerifiedCapsule verified =
        ApplicationCapsuleVerifier.verify(capsule.canonicalBytes());
    NativeImagePlan plan = new NativeImagePlan(
        PlatformAbi.Format.ELF,
        "x86_64-unknown-linux-gnu",
        NativeImagePlan.RuntimeMode.EMBEDDED_VM,
        true,
        true,
        wbc.identity(),
        root.platformAbi(),
        verified.capsule().identity(),
        hash(13),
        identity(runtimeText),
        hash(15),
        hash(16),
        hash(17),
        hash(18),
        hash(19));

    byte[] elfBytes = ElfImage.build(plan, abi, capsule, runtimeText, 0);
    ElfImage.VerifiedImage elf = ElfImage.verify(elfBytes, plan, abi);
    ApplicationCapsuleLauncher.CapsuleExecution execution =
        ApplicationCapsuleLauncher.launch(
            capsule.canonicalBytes(),
            new ApplicationCapsuleLauncher.LaunchContext(
                capsule.identity(),
                root.runtimeProfile(),
                root.bytecodeProfile(),
                root.proofProfile(),
                root.targetProfile(),
                root.platformAbi(),
                root.executionLimits(),
                List.of(),
                ApplicationCapsuleLauncher.InputMode.NONE,
                null,
                -1));

    assertEquals(verified.capsule().identity(), plan.capsule());
    assertEquals(capsule.identity(), elf.capsule().identity());
    assertArrayEquals(runtimeText, elf.runtimeText());
    assertEquals(1, execution.execution().workflowSteps());
    assertEquals("bin/hello.wbc", verified.capsule().entries().getFirst().name());
    assertEquals("example.hello::main",
        verified.rootProgram().function(verified.rootProgram().entryFunctionId()).name());
    assertArrayEquals(greeting, verified.capsule().entries().get(1).bytes());
  }

  private static PlatformAbi platformAbi() {
    return new PlatformAbi(
        PlatformAbi.Format.ELF,
        "x86_64",
        "linux-gnu",
        64,
        PlatformAbi.Endianness.LITTLE,
        4096,
        16,
        256,
        1024 * 1024,
        4096,
        1024,
        64L * 1024 * 1024,
        List.of("baseline"),
        List.of("libc.so.6"),
        List.of(
            PlatformAbi.Service.CAPABILITY_FILE_OPEN,
            PlatformAbi.Service.DIRECTORY_MANIFEST,
            PlatformAbi.Service.FILE_ATOMIC_REPLACE,
            PlatformAbi.Service.FILE_READ_AT,
            PlatformAbi.Service.MEMORY_PROTECT,
            PlatformAbi.Service.MEMORY_RELEASE,
            PlatformAbi.Service.MEMORY_RESERVE,
            PlatformAbi.Service.PROCESS_ARGUMENTS,
            PlatformAbi.Service.PROCESS_EXIT,
            PlatformAbi.Service.STDERR_WRITE,
            PlatformAbi.Service.STDIN_READ,
            PlatformAbi.Service.STDOUT_WRITE));
  }

  private static String identity(byte[] bytes) {
    try {
      return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(bytes));
    } catch (NoSuchAlgorithmException exception) {
      throw new IllegalStateException(exception);
    }
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }
}
