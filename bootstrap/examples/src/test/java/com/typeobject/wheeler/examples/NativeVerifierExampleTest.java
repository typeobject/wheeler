package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Conformance tests for Wheeler-native canonical bytecode verification. */
class NativeVerifierExampleTest {
  @Test
  void wheelerVerifiesACanonicalBinaryArtifactAndRewinds() throws Exception {
    Path root = Path.of("src/main/wheeler/native");
    var modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.verifier"));
    modules.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    modules.put("NativeVerifier.w", Files.readString(root.resolve("NativeVerifier.w")));
    var verifier = new WheelerCompiler().compileModuleFiles(
        modules, "examples.compiler.native_verifier");
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] artifact = compiler.compileToBytecode(
        "classical class NativeSubject { state long value = 4; "
            + "entry void main() { value += 3; assert(value == 7); } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(verifier, artifact);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("verification"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] binaryInputArtifact = compiler.compileToBytecode(
        "classical class BinarySubject { state long length = 0; "
            + "entry void main(borrow byteview source) { length = bufferLength(source); } }");
    VirtualMachine binaryInputVerification = VirtualMachine.withBinaryInput(
        verifier, binaryInputArtifact);
    binaryInputVerification.run();
    assertEquals(1, binaryInputVerification.global("verification"));

    byte[] logicalNegationArtifact = compiler.compileToBytecode(
        "classical class NegationSubject { state long selected = 0; "
            + "entry void main() { boolean enabled = !false; "
            + "if (enabled) { selected = 1; } } }");
    VirtualMachine logicalNegationVerification = VirtualMachine.withBinaryInput(
        verifier, logicalNegationArtifact);
    logicalNegationVerification.run();
    assertEquals(1, logicalNegationVerification.global("verification"));

    byte[] malformed = artifact.clone();
    malformed[0] = 0;
    VirtualMachine rejected = VirtualMachine.withBinaryInput(verifier, malformed);
    assertThrows(VmTrap.class, rejected::run);
  }
}
