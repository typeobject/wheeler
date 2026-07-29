package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.vm.VmTrap;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import org.junit.jupiter.api.Test;

/** Differential tests for Wheeler-native canonical bytecode re-encoding. */
final class NativeBytecodeCodecExampleTest {
  @Test
  void verifiedArtifactsReencodeByteForByteAndMalformedInputPublishesNothing()
      throws Exception {
    var modules = new LinkedHashMap<>(
        CompilerSources.moduleClosure("wheeler.compiler.codec"));
    modules.put("Binary.w", CoreSources.read("encoding/Binary.w"));
    modules.put(
        "NativeBytecodeCodec.w",
        Files.readString(Path.of("src/main/wheeler/native/NativeBytecodeCodec.w")));
    var codec = new WheelerCompiler().compileModuleFiles(
        modules, "examples.compiler.native_bytecode_codec");
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
