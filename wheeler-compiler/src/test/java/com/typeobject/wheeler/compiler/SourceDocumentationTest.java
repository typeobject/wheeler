package com.typeobject.wheeler.compiler;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class SourceDocumentationTest {
  @Test
  void acceptsAFirstContentSummaryWithParagraphs() {
    assertTrue(SourceDocumentation.checkFile("""
        //! Bounded source formatter boundary.
        //!
        //! Comments are evidence, not decoration.

        classical class Documented { entry void main() {} }
        """).isEmpty());
    assertTrue(SourceDocumentation.checkFile(
        "\ufeff//! BOM is transport trivia.\nclassical class Marked {}\n").isEmpty());
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
