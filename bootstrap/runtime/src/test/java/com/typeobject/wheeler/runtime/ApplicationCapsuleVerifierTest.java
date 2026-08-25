package com.typeobject.wheeler.runtime;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.FunctionBody;
import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.packageformat.ApplicationCapsule;
import com.typeobject.wheeler.packageformat.CapsuleEntry;
import com.typeobject.wheeler.packageformat.CapsulePackageReceipt;
import com.typeobject.wheeler.packageformat.CapsuleRoot;
import com.typeobject.wheeler.packageformat.NativeImagePlan;
import java.util.List;
import org.junit.jupiter.api.Test;

/** Runtime authority for complete application capsule WBC verification. */
final class ApplicationCapsuleVerifierTest {
  @Test
  void verifiesEveryCanonicalWbcAndBindsTheRoot() {
    byte[] wbc = canonicalWbc();
    ApplicationCapsule capsule = capsule(
        "example.hello::main",
        List.of(
            wbc("bin/hello.wbc", wbc, true),
            wbc("lib/support.wbc", wbc, false)));

    ApplicationCapsuleVerifier.VerifiedCapsule verified =
        ApplicationCapsuleVerifier.verify(capsule.canonicalBytes());

    assertEquals(capsule.identity(), verified.capsule().identity());
    assertEquals(List.of("bin/hello.wbc", "lib/support.wbc"),
        verified.programs().keySet().stream().toList());
    assertEquals("example.hello::main",
        verified.rootProgram().function(verified.rootProgram().entryFunctionId()).name());
    assertThrows(
        UnsupportedOperationException.class,
        () -> verified.programs().put("other", verified.rootProgram()));
  }

  @Test
  void rejectsMalformedSecondaryWbcAndWrongRootFunction() {
    byte[] valid = canonicalWbc();
    ApplicationCapsule malformed = capsule(
        "example.hello::main",
        List.of(
            wbc("bin/hello.wbc", valid, true),
            wbc("lib/broken.wbc", new byte[] {'W', 'B', 'C', 1}, false)));
    ApplicationCapsule wrongRoot = capsule(
        "example.hello::other",
        List.of(wbc("bin/hello.wbc", valid, true)));

    assertThrows(
        BytecodeException.class,
        () -> ApplicationCapsuleVerifier.verify(malformed));
    assertThrows(
        IllegalArgumentException.class,
        () -> ApplicationCapsuleVerifier.verify(wrongRoot));
  }

  private static ApplicationCapsule capsule(String entry, List<CapsuleEntry> entries) {
    CapsuleRoot root = new CapsuleRoot(
        hash(1),
        "hello",
        "bin/hello.wbc",
        entry,
        hash(2),
        hash(3),
        hash(4),
        hash(5),
        hash(6),
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
    return new ApplicationCapsule(root, List.of(receipt), entries);
  }

  private static CapsuleEntry wbc(String name, byte[] bytes, boolean startup) {
    int flags = CapsuleEntry.REQUIRED | (startup ? CapsuleEntry.STARTUP : 0);
    return new CapsuleEntry(CapsuleEntry.Kind.WBC, name, 8, flags, bytes);
  }

  private static byte[] canonicalWbc() {
    FunctionBody main = new FunctionBody(
        0,
        "example.hello::main",
        false,
        0,
        List.of(),
        null,
        List.of(Instruction.of(Opcode.HALT)),
        List.of());
    return new BytecodeWriter().write(
        new Program("example.hello", 0, List.of(), List.of(main)));
  }

  private static String hash(int value) {
    return "%064x".formatted(value);
  }
}
