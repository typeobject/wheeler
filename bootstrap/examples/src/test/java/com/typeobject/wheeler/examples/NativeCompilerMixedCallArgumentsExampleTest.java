package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Differential evidence for mixed signed and Boolean wide-call sources. */
final class NativeCompilerMixedCallArgumentsExampleTest {
  @Test
  void compilesImportedMixedThreeArgumentCallsByteForByte() throws Exception {
    String dependency = """
        module example.mixed_three_dependency;
        classical class MixedThreeDependency {
          public long select(long value, boolean selected, boolean fallback) {
            return value;
          }
        }
        """;
    String root = """
        module example.mixed_three;
        import example.mixed_three_dependency;
        classical class MixedThree {
          public long relay(long value, boolean selected, boolean fallback) {
            long result = select(value, selected, fallback);
            return result;
          }
        }
        """;
    var compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of("MixedThreeDependency.w", dependency, "MixedThree.w", root),
            "example.mixed_three"));

    assertArrayEquals(expected, actual);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency.replace("boolean selected", "long selected")),
        root);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency),
        root.replace("select(value, selected, fallback)", "select(value, selected, missing)"));
  }

  @Test
  void compilesImportedMixedBooleanThreeArgumentCallsByteForByte() throws Exception {
    String dependency = """
        module example.mixed_boolean_three_dependency;
        classical class MixedBooleanThreeDependency {
          public boolean select(long value, boolean selected, boolean fallback) {
            if (value == 0) {
              return selected;
            }
            return fallback;
          }
        }
        """;
    String root = """
        module example.mixed_boolean_three;
        import example.mixed_boolean_three_dependency;
        classical class MixedBooleanThree {
          public boolean relay(long value, boolean selected, boolean fallback) {
            boolean result = select(value, selected, fallback);
            return result;
          }
        }
        """;
    var compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(
            Map.of(
                "MixedBooleanThreeDependency.w", dependency,
                "MixedBooleanThree.w", root),
            "example.mixed_boolean_three"));

    assertArrayEquals(expected, actual);
    String signedDependency = """
        module example.mixed_boolean_three_dependency;
        classical class MixedBooleanThreeDependency {
          public long select(long value, boolean selected, boolean fallback) {
            return value;
          }
        }
        """;
    NativeModuleCompilerHarness.assertTrap(compiler, List.of(signedDependency), root);
  }

  @Test
  void compilesMixedFourArgumentCallsByteForByte() throws Exception {
    String source = """
        module example.mixed_four;
        classical class MixedFour {
          private long select(
            long value,
            boolean selected,
            boolean fallback,
            long limit
          ) {
            return value;
          }

          public long relay(
            long value,
            boolean selected,
            boolean fallback,
            long limit
          ) {
            long result = select(value, selected, fallback, limit);
            return result;
          }
        }
        """;

    assertLocalLibrary(source, "example.mixed_four");
  }

  @Test
  void compilesMixedFiveThroughSevenArgumentCallsByteForByte() throws Exception {
    String source = """
        module example.mixed_wide;
        classical class MixedWide {
          private long five(long a, boolean b, long c, boolean d, long e) {
            return a;
          }

          private long six(long a, boolean b, long c, boolean d, long e, boolean f) {
            return c;
          }

          private long seven(
            long a,
            boolean b,
            long c,
            boolean d,
            long e,
            boolean f,
            long g
          ) {
            return g;
          }

          public long relayFive(long a, boolean b, long c, boolean d, long e) {
            long result = five(a, b, c, d, e);
            return result;
          }

          public long relaySix(
            long a,
            boolean b,
            long c,
            boolean d,
            long e,
            boolean f
          ) {
            long result = six(a, b, c, d, e, f);
            return result;
          }

          public long relaySeven(
            long a,
            boolean b,
            long c,
            boolean d,
            long e,
            boolean f,
            long g
          ) {
            long result = seven(a, b, c, d, e, f, g);
            return result;
          }
        }
        """;

    assertLocalLibrary(source, "example.mixed_wide");
  }

  @Test
  void compilesBooleanLocalWideCallSourcesByteForByte() throws Exception {
    String source = """
        module example.mixed_boolean_locals;
        classical class MixedBooleanLocals {
          private long signedSelect(
            long value,
            boolean selected,
            boolean fallback,
            long limit
          ) {
            return value;
          }

          private boolean booleanSelect(long value, boolean selected, boolean fallback) {
            return selected;
          }

          public long signedRelay(long value, boolean selected, long limit) {
            boolean copied = selected;
            boolean fallback = false;
            long result = signedSelect(value, copied, fallback, limit);
            return result;
          }

          public boolean booleanRelay(long value, boolean selected) {
            boolean copied = selected;
            boolean fallback = false;
            boolean result = booleanSelect(value, copied, fallback);
            return result;
          }
        }
        """;

    Program compiler = assertLocalLibrary(source, "example.mixed_boolean_locals");
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(),
        source.replace("boolean fallback = false;", "long fallback = 0;"));
  }

  @Test
  void compilesMixedBooleanFourThroughSevenArgumentCallsByteForByte() throws Exception {
    String source = """
        module example.mixed_boolean_wide;
        classical class MixedBooleanWide {
          private boolean four(long a, boolean b, long c, boolean d) {
            return b;
          }

          private boolean five(long a, boolean b, long c, boolean d, long e) {
            return d;
          }

          private boolean six(long a, boolean b, long c, boolean d, long e, boolean f) {
            return f;
          }

          private boolean seven(
            long a,
            boolean b,
            long c,
            boolean d,
            long e,
            boolean f,
            long g
          ) {
            return b;
          }

          public boolean relayFour(long a, boolean b, long c, boolean d) {
            boolean result = four(a, b, c, d);
            return result;
          }

          public boolean relayFive(long a, boolean b, long c, boolean d, long e) {
            boolean result = five(a, b, c, d, e);
            return result;
          }

          public boolean relaySix(
            long a,
            boolean b,
            long c,
            boolean d,
            long e,
            boolean f
          ) {
            boolean result = six(a, b, c, d, e, f);
            return result;
          }

          public boolean relaySeven(
            long a,
            boolean b,
            long c,
            boolean d,
            long e,
            boolean f,
            long g
          ) {
            boolean result = seven(a, b, c, d, e, f, g);
            return result;
          }
        }
        """;

    assertLocalLibrary(source, "example.mixed_boolean_wide");
  }

  private static Program assertLocalLibrary(String source, String module) throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    byte[] actual = NativeModuleCompilerHarness.compile(compiler, List.of(), source);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(Map.of("MixedCalls.w", source), module));
    assertArrayEquals(expected, actual);
    return compiler;
  }
}
