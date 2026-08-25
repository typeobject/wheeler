package com.typeobject.wheeler.examples;

import static org.junit.jupiter.api.Assertions.assertArrayEquals;

import com.typeobject.wheeler.compiler.WheelerCompiler;
import com.typeobject.wheeler.core.bytecode.BytecodeWriter;
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

  private static void assertLocalLibrary(String source, String module) throws Exception {
    byte[] actual = NativeModuleCompilerHarness.compile(
        NativeModuleCompilerHarness.program(), List.of(), source);
    byte[] expected = new BytecodeWriter().write(
        new WheelerCompiler().compileLibraryModuleFiles(Map.of("MixedCalls.w", source), module));
    assertArrayEquals(expected, actual);
  }
}
