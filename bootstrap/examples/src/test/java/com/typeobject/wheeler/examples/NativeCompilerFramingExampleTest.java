package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;
import static org.junit.jupiter.api.Assertions.assertEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for bounded Wheeler-native source framing. */
final class NativeCompilerFramingExampleTest {
  private static final int MAX_SOURCE_BYTES = 32_768;

  @Test
  void acceptsOneCompleteSourceFrame() throws Exception {
    String prefix = "module examples.frame_boundary; "
        + "classical class FrameBoundary { public const long VALUE = 1; }";
    String source = prefix + " ".repeat(MAX_SOURCE_BYTES - prefix.length());
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(), source);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("FrameBoundary.w", source), "examples.frame_boundary");
    assertArrayEquals(new BytecodeWriter().write(expected), artifact);

    NativeModuleCompilerHarness.assertTrap(compiler, List.of(), source + " ");
  }

  @Test
  void compilesCanonicalHelperValueKindsByteForByte() throws Exception {
    Program decoded = NativeCompilerSelfSourceExampleTest.assertImportedConstantCompilerLibrary(
        "compiler/syntax/helpers/HelperValueKinds.w",
        "wheeler.compiler.helper_value_kinds",
        "compiler/syntax/intrinsics/BorrowedIntrinsicKinds.w",
        "compiler/ir/StatementKinds.w",
        "compiler/syntax/calls/VoidCallSourceKinds.w");
    assertEquals(
        1,
        decoded.functions().stream()
            .filter(function -> function.name().equals(
                "wheeler.compiler.void_call_source_kinds::voidCallSourceStatement"))
            .count());
    assertEquals(
        1,
        decoded.functions().stream()
            .filter(function -> function.name().equals(
                "wheeler.compiler.helper_value_kinds::helperValueStatement"))
            .count());
    assertEquals("$library", decoded.functions().getLast().name());
  }
}
