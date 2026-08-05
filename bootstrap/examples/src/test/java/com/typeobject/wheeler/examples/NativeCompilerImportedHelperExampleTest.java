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

/** Differential evidence for bounded native imported scalar helpers. */
final class NativeCompilerImportedHelperExampleTest {
  @Test
  void compilesSevenDirectImportedHelpersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String dependency = sevenHelperDependency();
    String root = String.join("\n",
        "module example.use;",
        "import example.predicates;",
        "classical class Use {",
        "  public boolean accepted(long value) {",
        "    if (below(value)) {",
        "      return true;",
        "    }",
        "",
        "    return below(value);",
        "  }",
        "}",
        "");

    byte[] artifact = NativeModuleCompilerHarness.compile(compiler, List.of(dependency), root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", dependency, "Use.w", root),
        "example.use");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    assertArrayEquals(expectedArtifact, artifact);
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals("example.predicates::below", decoded.functions().getFirst().name());
    assertEquals("example.predicates::nonzero", decoded.functions().get(6).name());
    assertEquals("example.use::accepted", decoded.functions().get(7).name());
    assertEquals(8, decoded.functions().get(7).localCount());
    assertEquals(11, decoded.functions().get(7).forward().size());
    assertEquals("$library", decoded.functions().getLast().name());

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency.replace("public boolean below", "private boolean below")),
        root);
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(dependency.replace(
            "  }\n}\n",
            "  }\n\n"
                + "  private boolean spare(long value) {\n"
                + "    return value == 8;\n"
                + "  }\n"
                + "}\n")),
        root);
  }

  @Test
  void compilesCanonicalImportedComparisonHelpersByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    String constants = CompilerSources.read("compiler/ir/ResolvedStatements.w");
    String dependency = CompilerSources.read(
        "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w");
    String root = CompilerSources.read("compiler/syntax/returns/EarlyComparisonForms.w");

    byte[] artifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(constants, dependency),
        root);
    Program expected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of(
            "compiler/ir/ResolvedStatements.w", constants,
            "compiler/syntax/returns/ResolvedEarlyComparisonKinds.w", dependency,
            "compiler/syntax/returns/EarlyComparisonForms.w", root),
        "wheeler.compiler.early_comparison_forms");
    byte[] expectedArtifact = new BytecodeWriter().write(expected);
    assertArrayEquals(expectedArtifact, artifact);
    assertArrayEquals(
        expectedArtifact,
        NativeModuleCompilerHarness.compile(compiler, List.of(dependency, constants), root));
    Program decoded = new BytecodeReader().read(artifact);
    assertEquals(
        "wheeler.compiler.resolved_early_comparison_kinds::resolvedEarlyEqualityReturn",
        decoded.functions().getFirst().name());
    assertEquals(
        "wheeler.compiler.early_comparison_forms::resolvedEarlyComparisonReturn",
        decoded.functions().get(2).name());
    assertEquals(8, decoded.functions().get(2).localCount());
    assertEquals(11, decoded.functions().get(2).forward().size());
    assertEquals("$library", decoded.functions().getLast().name());

    String privateDependency = dependency.replace(
        "public boolean resolvedEarlyLessReturn",
        "private boolean resolvedEarlyLessReturn");
    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(constants, privateDependency),
        root);
  }

  private static String sevenHelperDependency() {
    return String.join("\n",
        "module example.predicates;",
        "classical class Predicates {",
        "  public boolean below(long value) {",
        "    return value < 4;",
        "  }",
        "",
        "  private boolean ready() {",
        "    return true;",
        "  }",
        "",
        "  private boolean ordered(long left, long right) {",
        "    return left < right;",
        "  }",
        "",
        "  private boolean same(long value) {",
        "    return value == 4;",
        "  }",
        "",
        "  private boolean different(long value) {",
        "    return value != 5;",
        "  }",
        "",
        "  private boolean negative(long value) {",
        "    return value < 0;",
        "  }",
        "",
        "  private boolean nonzero(long value) {",
        "    return value != 0;",
        "  }",
        "}",
        "");
  }
}
