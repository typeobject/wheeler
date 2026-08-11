package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeReader;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for Wheeler-native verifier source modules. */
final class NativeCompilerVerifierSourceExampleTest {
  @Test
  void compilesCanonicalFixedBinaryReadersByteForByte() throws Exception {
    String source = CoreSources.read("encoding/FixedBinary.w");
    byte[] expected = compileWithStageZero(
        Map.of("FixedBinary.w", source),
        "wheeler.core.encoding.fixed_binary");
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    assertArrayEquals(expected, actual);

    Program decoded = new BytecodeReader().read(actual);
    assertEquals(
        "wheeler.core.encoding.fixed_binary::readUnsignedFour",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.core.encoding.fixed_binary::readUnsignedEight",
        decoded.functions().get(1).name());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        NativeModuleCompilerHarness.program(),
        List.of(),
        source.replace(
            "readUnsignedFour(source, offset)",
            "readUnsignedFour(offset, offset)"));
  }

  @Test
  void compilesCanonicalResultSlotVerifierByteForByte() throws Exception {
    String path = "compiler/verification/ResultSlotVerifier.w";
    String root = CompilerSources.read(path);
    byte[] expected = compileWithStageZero(
        Map.of(path, root),
        "wheeler.compiler.result_slot_verifier");
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), root);
    assertArrayEquals(expected, actual);
  }

  private static byte[] compileWithStageZero(
      Map<String, String> sources,
      String rootModule) {
    return new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(sources, rootModule));
  }
}
