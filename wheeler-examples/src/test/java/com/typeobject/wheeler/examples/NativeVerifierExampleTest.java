package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

class NativeVerifierExampleTest {
  @Test
  void wheelerVerifiesACanonicalBinaryArtifactAndRewinds() throws Exception {
    Path root = Path.of("src/main/wheeler");
    var verifier = new WheelerCompiler().compileModuleFiles(
        Map.of(
            "AggregateVerifier.w",
            Files.readString(root.resolve("compiler/AggregateVerifier.w")),
            "Binary.w", Files.readString(root.resolve("packages/Binary.w")),
            "FunctionVerifier.w",
            Files.readString(root.resolve("compiler/FunctionVerifier.w")),
            "InstructionVerifier.w",
            Files.readString(root.resolve("compiler/InstructionVerifier.w")),
            "NativeVerifier.w", Files.readString(root.resolve("NativeVerifier.w")),
            "Opcodes.w", Files.readString(root.resolve("compiler/Opcodes.w")),
            "ProofRules.w", Files.readString(root.resolve("compiler/ProofRules.w")),
            "ProofVerifier.w", Files.readString(root.resolve("compiler/ProofVerifier.w")),
            "TypeCodes.w", Files.readString(root.resolve("compiler/TypeCodes.w")),
            "Verifier.w", Files.readString(root.resolve("compiler/Verifier.w"))),
        "examples.compiler.native_verifier");
    byte[] artifact = new WheelerCompiler().compileToBytecode(
        "classical class NativeSubject { state long value = 4; "
            + "entry void main() { value += 3; assert value == 7; } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(verifier, artifact);
    var initial = machine.snapshot();

    machine.run();

    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("verification"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    byte[] malformed = artifact.clone();
    malformed[0] = 0;
    VirtualMachine rejected = VirtualMachine.withBinaryInput(verifier, malformed);
    assertThrows(VmTrap.class, rejected::run);
  }
}
