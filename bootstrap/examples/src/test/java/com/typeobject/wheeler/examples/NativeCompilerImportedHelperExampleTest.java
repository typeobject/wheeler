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
  void compilesEveryTwentyTwoHelperOwnerSplitByteForByte() throws Exception {
    Program compiler = NativeModuleCompilerHarness.program();
    for (int importedCount = 1; importedCount < 16; importedCount += 1) {
      String dependency = splitDependency(importedCount);
      String root = splitRoot(22 - importedCount);
      byte[] artifact = NativeModuleCompilerHarness.compile(
          compiler,
          List.of(dependency),
          root);
      Program expected = new WheelerCompiler().compileLibraryModuleFiles(
          Map.of("Dependency.w", dependency, "Root.w", root),
          "example.root");
      assertArrayEquals(
          new BytecodeWriter().write(expected),
          artifact,
          "owner split " + importedCount + "+" + (22 - importedCount));
      Program decoded = new BytecodeReader().read(artifact);
      assertEquals("example.split::dep0", decoded.functions().getFirst().name());
      assertEquals("example.root::root0", decoded.functions().get(importedCount).name());
      assertEquals("$library", decoded.functions().getLast().name());
    }

    NativeModuleCompilerHarness.assertTrap(
        compiler,
        List.of(splitDependency(22)),
        splitRoot(1));
  }

  @Test
  void compilesDirectImportedVisibilityByteForByte() throws Exception {
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
    String eightHelpers = dependency.replace(
        "  }\n}\n",
        "  }\n\n"
            + "  private boolean spare(long value) {\n"
            + "    return value == 8;\n"
            + "  }\n"
            + "}\n");
    byte[] eightArtifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(eightHelpers),
        root);
    Program eightExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", eightHelpers, "Use.w", root),
        "example.use");
    assertArrayEquals(new BytecodeWriter().write(eightExpected), eightArtifact);

    String nineHelpers = eightHelpers.replace(
        "  }\n}\n",
        "  }\n\n"
            + "  private boolean overflow(long value) {\n"
            + "    return value == 9;\n"
            + "  }\n"
            + "}\n");
    byte[] nineArtifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(nineHelpers),
        root);
    Program nineExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", nineHelpers, "Use.w", root),
        "example.use");
    assertArrayEquals(new BytecodeWriter().write(nineExpected), nineArtifact);

    String tenHelpers = nineHelpers.replace(
        "  }\n}\n",
        "  }\n\n"
            + "  private boolean capacity(long value) {\n"
            + "    return value == 10;\n"
            + "  }\n"
            + "}\n");
    byte[] tenArtifact = NativeModuleCompilerHarness.compile(
        compiler,
        List.of(tenHelpers),
        root);
    Program tenExpected = new WheelerCompiler().compileLibraryModuleFiles(
        Map.of("Predicates.w", tenHelpers, "Use.w", root),
        "example.use");
    assertArrayEquals(new BytecodeWriter().write(tenExpected), tenArtifact);

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

  private static String splitDependency(int count) {
    StringBuilder source = new StringBuilder(
        "module example.split;\nclassical class Dependency {\n");
    for (int index = 0; index < count; index += 1) {
      source.append("  public boolean dep")
          .append(index)
          .append("(long value) {\n    return value == ")
          .append(index)
          .append(";\n  }\n\n");
    }
    return source.append("}\n").toString();
  }

  private static String splitRoot(int count) {
    StringBuilder source = new StringBuilder(
        "module example.root;\nimport example.split;\nclassical class Root {\n");
    for (int index = 0; index < count; index += 1) {
      source.append("  public boolean root")
          .append(index)
          .append("(long value) {\n    return ");
      if (index == 0) {
        source.append("dep0(value)");
      } else {
        source.append("value == ").append(index + 8);
      }
      source.append(";\n  }\n\n");
    }
    return source.append("}\n").toString();
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
