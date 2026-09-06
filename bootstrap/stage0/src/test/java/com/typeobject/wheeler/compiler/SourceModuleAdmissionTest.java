package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.List;
import java.util.Map;
import org.junit.jupiter.api.Test;

/** Module admission must precede empty test selection and preserve nominal visibility. */
final class SourceModuleAdmissionTest {
  @Test
  void bindsEmptyTestSuitesWithOrWithoutAnEntry() {
    for (String entry : List.of("", "entry void main() {}")) {
      String prefix = "module pkg.test; classical class Tests { ";
      String suffix = entry + " }";
      var compiler = new WheelerCompiler();
      assertEquals(List.of(), compiler.compilePackageTests(
          Map.of("Test.w", prefix + "void helper() {} " + suffix), Map.of(), "pkg.test"));
      for (String member : List.of(
          "vojE helper() {} ",
          "void helper(vojE value) {} ",
          "Missing[] helper() {} ",
          "pkg.test::Missing helper() {} ",
          "void helper(pkg.test::Missing value) {} ",
          "record Box(pkg.test::Missing value) {} ",
          "variant Box { case Value(pkg.test::Missing value); } ")) {
        var error = assertThrows(CompilerException.class, () -> compiler.compilePackageTests(
            Map.of("Test.w", prefix + member + suffix), Map.of(), "pkg.test"), member);
        assertTrue(error.getMessage().contains("unresolved or non-public module type"), error::getMessage);
      }
    }
  }

  @Test
  void preservesDependencyEntryRulesForEmptyTestSuites() {
    Map<String, String> modules = Map.of(
        "Test.w", "module pkg.test; import dep; classical class Tests {}",
        "Dep.w", "module dep; classical class Dependency { entry void main() {} }");
    var error = assertThrows(CompilerException.class, () -> new WheelerCompiler()
        .compilePackageTests(modules, Map.of(), "pkg.test"));
    assertTrue(error.getMessage().contains("dependency module cannot declare an entry"), error::getMessage);
  }

  @Test
  void rejectsVoidValuePositionsBeforeEmptyTestSelection() {
    for (String member : List.of(
        "void helper(void value) {}",
        "record Box(void value) {}",
        "variant Box { case Value(void value); }",
        "void helper(void[] values) {}")) {
      String source = "module pkg.test; classical class Tests { " + member + " }";
      var error = assertThrows(CompilerException.class, () -> new WheelerCompiler().compilePackageTests(
          Map.of("Test.w", source), Map.of(), "pkg.test"), member);
      assertTrue(error.getMessage().contains("void is not a value type"), error::getMessage);
    }
  }

  @Test
  void bindsDeclaredNamesWithoutACapitalizationGate() {
    var compiler = new WheelerCompiler();
    var modules = Map.of(
        "Types.w", """
            module types;
            classical class Types { public enum vojE { case Value; } }
            """,
        "Test.w", """
            module pkg.test;
            import types;
            classical class Tests {
              leaf forward(leaf value) { return value; }
              variant leaf { case End(); case Next(leaf value); }
              vojE imported(vojE value) { return value; }
              variant void { case Value(); }
              pkg.test::void namedVoid(pkg.test::void value) { return value; }
              entry void main() {}
            }
            """);
    compiler.compileModuleFiles(modules, "pkg.test");
    assertEquals(List.of(), compiler.compilePackageTests(modules, Map.of(), "pkg.test"));
  }

  @Test
  void rejectsQualifiedPrivateTypesInPublicModuleApis() {
    for (String declaration : List.of(
        "private record Hidden(long value) {} ",
        "private variant Hidden { case Value(long value); } ")) {
      for (String member : List.of(
          "public pkg.test::Hidden echo(pkg.test::Hidden value) { return value; }",
          "public void helper(pkg.test::Hidden value) {}",
          "public void helper(pkg.test::Hidden[] values) {}",
          "public void helper(pkg.test::Hidden[2] values) {}",
          "public record Visible(pkg.test::Hidden value) {}",
          "public variant Visible { case Value(pkg.test::Hidden value); }")) {
        String source = "module pkg.test; classical class Tests { "
            + declaration + member + " entry void main() {} }";
        var error = assertThrows(CompilerException.class,
            () -> new WheelerCompiler().compileModuleFiles(Map.of("Test.w", source), "pkg.test"), member);
        assertTrue(error.getMessage().contains("public API exposes private "), error::getMessage);
      }
    }
  }
}
