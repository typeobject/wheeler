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

/** Differential evidence for helper calls returned behind imported helper guards. */
final class NativeCompilerImportedEarlyCallExampleTest {
  private static final String ALPHA = """
      module example.alpha;
      classical class Alpha {
        public boolean alpha(long value) { return value == 0; }
      }
      """;
  private static final String BETA = """
      module example.beta;
      classical class Beta {
        public boolean beta(long value) { return value == 1; }
      }
      """;

  @Test
  void forwardsAnImportedCallBehindAnImportedGuardByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String root = rootWithForwardingGuards(1);
    byte[] expectedArtifact = expected(root);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, List.of(ALPHA, BETA), root));
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, List.of(BETA, ALPHA), root));

    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals(8, decoded.functions().get(2).localCount());
    assertEquals(11, decoded.functions().get(2).forward().size());
    assertEquals("example.calls::accepted", decoded.functions().get(2).name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(ALPHA, BETA.replace("public boolean beta", "private boolean beta")),
        root);
  }

  @Test
  void forwardsADifferentPriorLocalToTheReturnedCall() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String root = String.join("\n",
        "module example.calls;",
        "import example.alpha;",
        "import example.beta;",
        "classical class Calls {",
        "  public boolean accepted(long first, long second) {",
        "    if (alpha(first)) { return beta(second); }",
        "    return false;",
        "  }",
        "}",
        "");
    byte[] expectedArtifact = expected(root);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, List.of(BETA, ALPHA), root));
    Program decoded = new BytecodeReader().read(expectedArtifact);
    assertEquals(9, decoded.functions().get(2).localCount());
    assertEquals(2, decoded.functions().get(2).parameterCount());
  }

  @Test
  void fillsTheCallTableWithThirtyTwoGuardedForwardingPairs() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String accepted = rootWithForwardingGuards(32);
    assertArrayEquals(
        expected(accepted),
        NativeModuleCompilerHarness.compile(compiler, List.of(BETA, ALPHA), accepted));

    Program decoded = new BytecodeReader().read(expected(accepted));
    assertEquals(194, decoded.functions().get(2).localCount());
    assertEquals(290, decoded.functions().get(2).forward().size());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(ALPHA, BETA),
        rootWithForwardingGuards(33));
  }

  private static byte[] expected(String root) {
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Alpha.w", ALPHA, "Beta.w", BETA, "Calls.w", root),
        "example.calls");
    return new BytecodeWriter().write(expected);
  }

  private static String rootWithForwardingGuards(int guardCount) {
    StringBuilder source = new StringBuilder(String.join("\n",
        "module example.calls;",
        "import example.alpha;",
        "import example.beta;",
        "classical class Calls {",
        "  public boolean accepted(long value) {"));
    for (int guard = 0; guard < guardCount; guard += 1) {
      source.append("\n    if (alpha(value)) { return beta(value); }");
    }
    return source.append("\n    return false;\n  }\n}\n").toString();
  }
}
