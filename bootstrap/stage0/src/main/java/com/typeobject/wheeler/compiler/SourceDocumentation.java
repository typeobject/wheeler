package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConcreteSyntax.CommentAttachment;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Element;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Placement;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.SyntaxNode;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Deterministic documentation checks over Wheeler's lossless source boundary. */
public final class SourceDocumentation {
  /** Stable compiler-owned documentation for one selected Wheeler declaration. */
  public record Declaration(
      String kind,
      String name,
      int line,
      int column,
      List<String> modifiers,
      String summary,
      Map<String, String> facets) {
    public Declaration {
      modifiers = List.copyOf(modifiers);
      facets = Collections.unmodifiableMap(new LinkedHashMap<>(facets));
    }
  }

  /** Compiler-owned file and declaration documentation exported to bundle generators. */
  public record FileDocumentation(
      String module, String summary, List<Declaration> declarations) {
    public FileDocumentation {
      declarations = List.copyOf(declarations);
    }
  }

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

  /** Exports parser-owned module and selected declaration documentation without reparsing syntax. */
  public static FileDocumentation extract(String source) {
    SourceConcreteSyntax.Document document = SourceConcreteSyntax.scan(source);
    Map<Integer, List<Element>> comments = leadingDeclarationDocumentation(document);
    String module = "";
    List<Declaration> declarations = new ArrayList<>();
    for (int index = 0; index < document.nodes().size(); index++) {
      SyntaxNode node = document.nodes().get(index);
      if (node.kind() == SourceConcreteSyntax.NodeKind.MODULE_DECLARATION) {
        module = node.name();
      }
      if (!node.kind().declaration()) {
        continue;
      }
      boolean selected = node.modifiers().contains("public")
          || node.modifiers().stream().anyMatch(
              modifier -> List.of("entry", "rev", "coherent", "unitary").contains(modifier))
          || node.kind() == SourceConcreteSyntax.NodeKind.THEOREM_DECLARATION
          || node.kind() == SourceConcreteSyntax.NodeKind.EXPERIMENT_DECLARATION;
      if (!selected) {
        continue;
      }
      Element start = document.elements().get(node.startElement());
      DocumentationPayload payload = payload(comments.getOrDefault(index, List.of()));
      declarations.add(new Declaration(
          node.kind().name().toLowerCase(java.util.Locale.ROOT),
          node.name(),
          start.line(),
          start.column(),
          node.modifiers(),
          payload.summary(),
          payload.facets()));
    }
    return new FileDocumentation(module, fileSummary(document.elements()), declarations);
  }

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
    return SourceDeclarationDocumentation.check(document);
  }

  private record DocumentationPayload(String summary, Map<String, String> facets) {}

  private static Map<Integer, List<Element>> leadingDeclarationDocumentation(
      SourceConcreteSyntax.Document document) {
    Map<Integer, List<Element>> result = new LinkedHashMap<>();
    for (CommentAttachment attachment : document.comments()) {
      Element comment = document.elements().get(attachment.commentElement());
      if (attachment.placement() == Placement.LEADING && comment.text().startsWith("///")) {
        result.computeIfAbsent(attachment.targetNode(), ignored -> new ArrayList<>()).add(comment);
      }
    }
    return result;
  }

  private static DocumentationPayload payload(List<Element> comments) {
    String summary = "";
    Map<String, String> facets = new LinkedHashMap<>();
    for (Element comment : comments) {
      String text = comment.text().substring(3).trim();
      if (text.startsWith("- ") && text.contains(":")) {
        int colon = text.indexOf(':');
        facets.put(text.substring(2, colon).trim(), text.substring(colon + 1).trim());
      } else if (summary.isEmpty() && !text.isEmpty()) {
        summary = text;
      }
    }
    return new DocumentationPayload(summary, facets);
  }

  private static String fileSummary(List<Element> elements) {
    for (Element element : elements) {
      if (element.kind() == SourceConcreteSyntax.Kind.LINE_COMMENT
          && element.text().startsWith("//!")) {
        String summary = element.text().substring(3).trim();
        if (!summary.isEmpty()) {
          return summary;
        }
      }
    }
    return "";
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
