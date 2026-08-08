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

  @Test
  void compilesThreeHelpersBesideFourConstantsAcrossSevenFrames() throws Exception {
    String alpha = "module example.alpha; classical class Alpha { "
        + "public boolean alpha(long value) { return value == 1; } }";
    String beta = "module example.beta; classical class Beta { public const long BETA = 2; }";
    String delta = "module example.delta; classical class Delta { public const long DELTA = 4; }";
    String epsilon = "module example.epsilon; classical class Epsilon { "
        + "public boolean epsilon(long value) { return value == 5; } }";
    String gamma = "module example.gamma; classical class Gamma { "
        + "public const long GAMMA = 3; }";
    String theta = "module example.theta; classical class Theta { "
        + "public boolean theta(long value) { return value == 8; } }";
    String zeta = "module example.zeta; classical class Zeta { public const long ZETA = 6; }";
    List<String> imported = List.of(alpha, beta, delta, epsilon, gamma, theta, zeta);
    String root = """
        module example.mixed_seven;
        import example.alpha;
        import example.beta;
        import example.delta;
        import example.epsilon;
        import example.gamma;
        import example.theta;
        import example.zeta;
        classical class MixedSeven {
          public boolean accepted(long value) {
            if (alpha(value)) { return true; }
            if (epsilon(value)) { return false; }
            if (theta(value)) { return true; }
            if (value == BETA) { return false; }
            if (value == DELTA) { return true; }
            if (value == GAMMA) { return false; }
            return value == ZETA;
          }
        }
        """;

    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of(
                "Alpha.w", alpha,
                "Beta.w", beta,
                "Delta.w", delta,
                "Epsilon.w", epsilon,
                "Gamma.w", gamma,
                "Theta.w", theta,
                "Zeta.w", zeta,
                "MixedSeven.w", root),
            "example.mixed_seven"));
    Program compiler = NativeModuleCompilerHarness.program();
    List<List<String>> orders =
        NativeImportedConstantGraphSupport.rotationsAndReversals(imported);
    for (List<String> order : orders) {
      assertArrayEquals(expected, NativeModuleCompilerHarness.compile(compiler, order, root));
    }
  }
}
