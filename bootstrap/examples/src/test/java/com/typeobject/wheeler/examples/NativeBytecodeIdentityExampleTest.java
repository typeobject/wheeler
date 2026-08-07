package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical bytecode identities. */
final class NativeBytecodeIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/compiler/NativeBytecodeIdentity.w");

  @Test
  void verifiesBeforePublishingTheCanonicalArtifactIdentity() throws Exception {
    Program program = program();
    byte[] artifact = new WheelerCompiler().compileToBytecode(
        "classical class IdentitySubject { state long value = 3; "
            + "entry void main() { value += 4; assert(value == 7); } }");
    VirtualMachine machine = vm(program, artifact);
    var initial = machine.snapshot();

    machine.run();

    byte[] expected = MessageDigest.getInstance("SHA-256").digest(artifact);
    assertArrayEquals(expected, machine.hostOutput());
    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(artifact.length, machine.global("verifiedLength"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] malformed = artifact.clone();
    malformed[0] = 0;
    assertNoIdentity(program, malformed);
    assertNoIdentity(program, new byte[4097]);
  }

  private static Program program() throws Exception {
    var modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.codec"));
    CoreSources.addBinaryClosure(modules);
    modules.put("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"));
    modules.put("NativeBytecodeIdentity.w", Files.readString(FIXTURE));
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.compiler.native_bytecode_identity");
  }

  private static VirtualMachine vm(Program program, byte[] source) {
    return VirtualMachine.withBinaryInput(program, source, 32);
  }

  private static void assertNoIdentity(Program program, byte[] source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
  }
}
