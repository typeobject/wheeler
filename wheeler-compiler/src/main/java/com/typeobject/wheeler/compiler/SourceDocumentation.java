package com.typeobject.wheeler.compiler;

import java.util.List;

/** Deterministic documentation checks over Wheeler's lossless source boundary. */
public final class SourceDocumentation {
  /** Stable source documentation diagnostic. */
  public record Diagnostic(
      String code,
      int line,
      int column,
      String message) {
    public Diagnostic {
      if (code == null || line < 1 || column < 1 || message == null) {
        throw new IllegalArgumentException("Invalid documentation diagnostic");
      }
    }
  }

  private SourceDocumentation() {}

  /** Checks file documentation rules implemented by the initial concrete-syntax slice. */
  public static List<Diagnostic> checkFile(String source) {
    SourceConcreteSyntax.Document document = SourceConcreteSyntax.scan(source);
    List<SourceConcreteSyntax.Element> elements = document.elements();
    int first = firstContent(elements);
    int documentation = findFileDocumentation(elements);
    if (first < 0) {
      return List.of(missingFileDocumentation());
    }
    if (documentation != first) {
      if (documentation < 0) {
        return List.of(missingFileDocumentation());
      }
      SourceConcreteSyntax.Element misplaced = elements.get(documentation);
      return List.of(new Diagnostic(
          "WDOC005",
          misplaced.line(),
          misplaced.column(),
          "//! documentation must be the first source content"));
    }
    if (!hasSummary(elements, documentation)) {
      SourceConcreteSyntax.Element empty = elements.get(documentation);
      return List.of(new Diagnostic(
          "WDOC003",
          empty.line(),
          empty.column(),
          "documentation block requires a nonempty summary"));
    }
    return List.of();
  }

  private static int firstContent(List<SourceConcreteSyntax.Element> elements) {
    for (int index = 0; index < elements.size(); index++) {
      if (elements.get(index).kind() != SourceConcreteSyntax.Kind.WHITESPACE) {
        return index;
      }
    }
    return -1;
  }

  private static int findFileDocumentation(List<SourceConcreteSyntax.Element> elements) {
    for (int index = 0; index < elements.size(); index++) {
      SourceConcreteSyntax.Element element = elements.get(index);
      if (element.kind() == SourceConcreteSyntax.Kind.LINE_COMMENT
          && element.text().startsWith("//!")) {
        return index;
      }
    }
    return -1;
  }

  private static boolean hasSummary(
      List<SourceConcreteSyntax.Element> elements,
      int start) {
    int index = start;
    while (index < elements.size()) {
      SourceConcreteSyntax.Element comment = elements.get(index);
      if (comment.kind() != SourceConcreteSyntax.Kind.LINE_COMMENT
          || !comment.text().startsWith("//!")) {
        return false;
      }
      if (!comment.text().substring(3).trim().isEmpty()) {
        return true;
      }
      index++;
      if (index >= elements.size()
          || elements.get(index).kind() != SourceConcreteSyntax.Kind.WHITESPACE
          || lineBreaks(elements.get(index).text()) != 1) {
        return false;
      }
      index++;
    }
    return false;
  }

  private static int lineBreaks(String text) {
    int result = 0;
    for (int index = 0; index < text.length(); index++) {
      if (text.charAt(index) == '\n') {
        result++;
      }
    }
    return result;
  }

  private static Diagnostic missingFileDocumentation() {
    return new Diagnostic(
        "WDOC001",
        1,
        1,
        "source file requires nonempty //! documentation");
  }
}
