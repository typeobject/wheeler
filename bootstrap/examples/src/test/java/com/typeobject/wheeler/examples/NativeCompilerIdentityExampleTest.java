package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native compiler output identities. */
final class NativeCompilerIdentityExampleTest {
  private static final Path FIXTURE = Path.of(
      "../wheeler-conformance/src/main/wheeler/compiler/NativeCompilerIdentity.w");

  @Test
  void compilesBeforePublishingTheVerifiedArtifactIdentity() throws Exception {
    Program program = program();
    String source = "module examples.identity; classical class IdentitySubject { state long value = 3; "
        + "entry void main() { value += 4; assert(value == 7); } }";
    byte[] expectedArtifact = new BytecodeWriter().write(
        new WheelerCompiler().compileModuleFiles(
            Map.of("IdentitySubject.w", source), "examples.identity"));
    VirtualMachine machine = vm(program, source);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(
        MessageDigest.getInstance("SHA-256").digest(expectedArtifact),
        machine.hostOutput());
    assertEquals(source.getBytes(StandardCharsets.UTF_8).length,
        machine.global("sourceLength"));
    assertEquals(expectedArtifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("published"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    assertNoIdentity(program, source.replace("value += 4", "value += nope"));
    assertNoIdentity(program, "/* padding */".repeat(400) + source);
  }

  private static Program program() throws Exception {
    Map<String, String> modules = CompilerSources.compilerDriverModules();
    CoreSources.addBinaryClosure(modules);
    modules.put("ContentIdentity.w", CoreSources.read("crypto/ContentIdentity.w"));
    modules.put("Sha256.w", CoreSources.read("crypto/Sha256.w"));
    modules.put("NativeCompilerIdentity.w", Files.readString(FIXTURE));
    return new WheelerCompiler().compileModuleFiles(
        modules, "wheeler.conformance.compiler.native_compiler_identity");
  }

  private static VirtualMachine vm(Program program, String source) {
    return new VirtualMachine(program, source.getBytes(StandardCharsets.UTF_8), 32);
  }

  private static void assertNoIdentity(Program program, String source) {
    VirtualMachine machine = vm(program, source);
    assertThrows(VmTrap.class, machine::run);
    assertArrayEquals(new byte[32], machine.hostOutput());
  }
}
