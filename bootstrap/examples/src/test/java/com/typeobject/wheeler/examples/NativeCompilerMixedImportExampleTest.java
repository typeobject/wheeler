package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for direct mixed helper and constant imports. */
final class NativeCompilerMixedImportExampleTest {
  @Test
  void compilesOneHelperBesideOneConstantInEitherFrameOrder() throws Exception {
    String constants = """
        module example.constants;
        classical class Constants {
          public const long VALUE = 7;
        }
        """;
    String helper = """
        module example.helper;
        classical class Helper {
          public boolean selected(long value) {
            return value == 8;
          }
        }
        """;
    String root = """
        module example.mixed_root;
        import example.constants;
        import example.helper;
        classical class MixedRoot {
          public boolean accepted(long value) {
            if (selected(value)) {
              return true;
            }

            return value == VALUE;
          }
        }
        """;

    Program compiler = NativeModuleCompilerHarness.program();
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("Constants.w", constants, "Helper.w", helper, "MixedRoot.w", root),
            "example.mixed_root"));
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(constants, helper), root));
    assertArrayEquals(
        expected,
        NativeModuleCompilerHarness.compile(compiler, List.of(helper, constants), root));
  }
}
