package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import org.junit.jupiter.api.Test;

class SourceDocumentationTest {
  @Test
  void acceptsAFirstContentSummaryWithParagraphs() {
    assertTrue(SourceDocumentation.checkFile("""
        //! Bounded source formatter boundary.
        //!
        //! Comments are evidence, not decoration.

        classical class Documented {
            /// Runs the documented entry.
            ///
            /// - Effects: Mutates no state.
            entry void main() {}
        }
        """).isEmpty());
    assertTrue(SourceDocumentation.checkFile(
        "\ufeff//! BOM is transport trivia.\nclassical class Marked {}\n").isEmpty());
  }

  @Test
  void checksRequiredDeclarationsAndSemanticFacets() {
    assertTrue(SourceDocumentation.checkFile("""
        //! Complete declaration documentation fixture.

        classical class Complete {
            /// Stores the visible state.
            public state long value = 0;

            /// Returns `value`.
            public long read() { return value; }

            /// Steps the reversible state.
            ///
            /// - Inverse: Applies the generated inverse.
            rev void step() {}

            /// Permutes one coherent basis bit.
            ///
            /// - Inverse: Applies the same permutation.
            /// - Coherent: Acts on one clean basis bit.
            coherent rev void flip() {}

            /// Applies the unitary body.
            ///
            /// - Adjoint: Reverses semantic gate order.
            unitary void oracle() {}

            private long helper() { return 0; }

            /// Runs the program.
            ///
            /// - Effects: Mutates `value`.
            entry void main() {}
        }
        """).isEmpty());
  }

  @Test
  void reportsDeclarationCoverageAdjacencyAndFacetDiagnostics() {
    var missing = SourceDocumentation.checkFile("""
        //! Missing entry documentation.
        classical class MissingEntry { entry void main() {} }
        """);
    assertEquals(List.of("WDOC002"), missing.stream()
        .map(SourceDocumentation.Diagnostic::code)
        .toList());

    var detached = SourceDocumentation.checkFile("""
        //! Detached declaration documentation.
        classical class Detached {
            /// Not attached.

            entry void main() {}
        }
        """);
    assertEquals(List.of("WDOC004", "WDOC002"), detached.stream()
        .map(SourceDocumentation.Diagnostic::code)
        .toList());

    var facets = SourceDocumentation.checkFile("""
        //! Broken facet fixture.
        classical class Facets {
            /// Runs the program.
            ///
            /// - Bounds: One step.
            /// - Effects: First declaration.
            /// - Effects: Duplicate declaration.
            entry void main() {}
        }
        """);
    assertEquals(List.of("WDOC006", "WDOC006"), facets.stream()
        .map(SourceDocumentation.Diagnostic::code)
        .toList());
  }

  @Test
  void everyCheckedExampleCarriesValidFileAndDeclarationDocumentation() throws Exception {
    Path examples = Path.of("../wheeler-examples/src/main/wheeler");
    try (var paths = Files.walk(examples)) {
      for (Path source : paths.filter(path -> path.toString().endsWith(".w")).toList()) {
        assertEquals(List.of(), SourceDocumentation.checkFile(Files.readString(source)),
            source.toString());
      }
    }
  }

  @Test
  void reportsStableMissingEmptyAndMisplacedDiagnostics() {
    assertDiagnostic(
        "classical class Missing { entry void main() {} }\n",
        "WDOC001",
        1,
        1,
        "source file requires nonempty //! documentation");
    assertDiagnostic(
        "//!\n//!   \nclassical class Empty { entry void main() {} }\n",
        "WDOC003",
        1,
        1,
        "documentation block requires a nonempty summary");
    assertDiagnostic(
        "// ordinary\n//! Too late.\nclassical class Late { entry void main() {} }\n",
        "WDOC005",
        2,
        1,
        "//! documentation must be the first source content");
    assertDiagnostic(
        "\n\t\n",
        "WDOC001",
        1,
        1,
        "source file requires nonempty //! documentation");
  }

  private static void assertDiagnostic(
      String source,
      String code,
      int line,
      int column,
      String message) {
    var diagnostics = SourceDocumentation.checkFile(source);
    assertEquals(1, diagnostics.size());
    assertEquals(code, diagnostics.getFirst().code());
    assertEquals(line, diagnostics.getFirst().line());
    assertEquals(column, diagnostics.getFirst().column());
    assertEquals(message, diagnostics.getFirst().message());
  }
}
