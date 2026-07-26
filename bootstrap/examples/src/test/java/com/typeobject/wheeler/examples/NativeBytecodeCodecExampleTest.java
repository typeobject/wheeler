package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical bytecode re-encoding. */
final class NativeBytecodeCodecExampleTest {
  @Test
  void verifiedArtifactsReencodeByteForByteAndMalformedInputPublishesNothing()
      throws Exception {
    var codec = new WheelerCompiler().compileModuleFiles(
        Map.ofEntries(
            Map.entry(
                "AggregateVerifier.w",
                CompilerSources.read("compiler/verification/AggregateVerifier.w")),
            Map.entry("Binary.w", CoreSources.read("encoding/Binary.w")),
            Map.entry("Codec.w", CompilerSources.read("compiler/verification/Codec.w")),
            Map.entry(
                "FunctionVerifier.w",
                CompilerSources.read("compiler/verification/FunctionVerifier.w")),
            Map.entry(
                "InstructionVerifier.w",
                CompilerSources.read("compiler/verification/InstructionVerifier.w")),
            Map.entry(
                "NativeBytecodeCodec.w",
                Files.readString(Path.of(
                    "src/main/wheeler/native/NativeBytecodeCodec.w"))),
            Map.entry("Opcodes.w", CompilerSources.read("compiler/ir/Opcodes.w")),
            Map.entry("ProofRules.w", CompilerSources.read("compiler/ir/ProofRules.w")),
            Map.entry(
                "ProofVerifier.w",
                CompilerSources.read("compiler/verification/ProofVerifier.w")),
            Map.entry(
                "StorageVerifier.w",
                CompilerSources.read("compiler/verification/StorageVerifier.w")),
            Map.entry("TypeCodes.w", CompilerSources.read("compiler/ir/TypeCodes.w")),
            Map.entry("Verifier.w", CompilerSources.read("compiler/verification/Verifier.w"))),
        "examples.compiler.native_bytecode_codec");
    WheelerCompiler compiler = new WheelerCompiler();
    byte[] artifact = compiler.compileToBytecode(
        "classical class CodecSubject { state long value = 2; "
            + "entry void main() { value += 5; assert(value == 7); } }");
    VirtualMachine machine = VirtualMachine.withBinaryInput(codec, artifact, artifact.length);
    var initial = machine.snapshot();

    machine.run();

    assertArrayEquals(artifact, machine.hostOutput());
    assertEquals(artifact.length, machine.global("artifactLength"));
    assertEquals(1, machine.global("verification"));
    while (machine.historySize() > 0) {
      machine.rewindOne();
    }
    assertEquals(initial, machine.snapshot());

    VirtualMachine undersized = VirtualMachine.withBinaryInput(
        codec, artifact, artifact.length - 1);
    assertThrows(VmTrap.class, undersized::run);
    assertArrayEquals(new byte[artifact.length - 1], undersized.hostOutput());

    byte[] malformed = artifact.clone();
    malformed[0] = 0;
    VirtualMachine rejected = VirtualMachine.withBinaryInput(codec, malformed, artifact.length);
    assertThrows(VmTrap.class, rejected::run);
    assertArrayEquals(new byte[artifact.length], rejected.hostOutput());
  }
}
