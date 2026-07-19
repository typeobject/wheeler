package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConcreteSyntax.CommentAttachment;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Element;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.NodeKind;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Placement;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.SyntaxNode;
import com.typeobject.wheeler.compiler.SourceDocumentation.Diagnostic;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Declaration coverage and facet checks over parser-owned declaration ranges. */
final class SourceDeclarationDocumentation {
  private static final List<String> FACETS = List.of(
      "Inputs", "Returns", "Effects", "Inverse", "Coherent", "Adjoint",
      "Traps", "Bounds", "Proof", "See also");

  private record Declaration(
      int node,
      String name,
      int line,
      int column,
      boolean required,
      boolean entry,
      boolean reversible,
      boolean coherent,
      boolean unitary) {}

  private SourceDeclarationDocumentation() {}

  static List<Diagnostic> check(SourceConcreteSyntax.Document document) {
    List<Declaration> declarations = declarations(document);
    Map<Integer, Declaration> targets = new HashMap<>();
    declarations.forEach(declaration -> targets.put(declaration.node(), declaration));
    Map<Integer, List<Element>> documentation = attachedDocumentation(document, targets);
    List<Diagnostic> diagnostics = new ArrayList<>();

    for (CommentAttachment attachment : document.comments()) {
      Element comment = document.elements().get(attachment.commentElement());
      if (!comment.text().startsWith("///")) {
        continue;
      }
      if (attachment.placement() != Placement.LEADING
          || !targets.containsKey(attachment.targetNode())) {
        diagnostics.add(new Diagnostic(
            "WDOC004",
            comment.line(),
            comment.column(),
            "/// documentation must be adjacent to a declaration"));
      }
    }

    for (Declaration declaration : declarations) {
      List<Element> comments = documentation.getOrDefault(declaration.node(), List.of());
      if (comments.isEmpty()) {
        if (declaration.required()) {
          diagnostics.add(new Diagnostic(
              "WDOC002",
              declaration.line(),
              declaration.column(),
              "declaration '" + declaration.name() + "' requires /// documentation"));
        }
        continue;
      }
      if (comments.stream().noneMatch(SourceDeclarationDocumentation::nonemptyPayload)) {
        Element first = comments.getFirst();
        diagnostics.add(new Diagnostic(
            "WDOC003",
            first.line(),
            first.column(),
            "documentation block requires a nonempty summary"));
      }
      Set<String> facets = checkFacets(comments, diagnostics);
      requireFacet(declaration, facets, "Effects", "WDOC010", declaration.entry(), diagnostics);
      requireFacet(declaration, facets, "Inverse", "WDOC007", declaration.reversible(), diagnostics);
      requireFacet(declaration, facets, "Coherent", "WDOC008", declaration.coherent(), diagnostics);
      requireFacet(declaration, facets, "Adjoint", "WDOC009", declaration.unitary(), diagnostics);
    }

    diagnostics.sort(Comparator.comparingInt(Diagnostic::line)
        .thenComparingInt(Diagnostic::column)
        .thenComparing(Diagnostic::code));
    return List.copyOf(diagnostics);
  }

  private static Map<Integer, List<Element>> attachedDocumentation(
      SourceConcreteSyntax.Document document,
      Map<Integer, Declaration> targets) {
    Map<Integer, List<Element>> result = new HashMap<>();
    for (CommentAttachment attachment : document.comments()) {
      Element comment = document.elements().get(attachment.commentElement());
      if (attachment.placement() == Placement.LEADING
          && comment.text().startsWith("///")
          && targets.containsKey(attachment.targetNode())) {
        result.computeIfAbsent(attachment.targetNode(), ignored -> new ArrayList<>())
            .add(comment);
      }
    }
    return result;
  }

  private static Set<String> checkFacets(
      List<Element> comments,
      List<Diagnostic> diagnostics) {
    Set<String> result = new HashSet<>();
    int previous = -1;
    for (Element comment : comments) {
      String payload = comment.text().substring(3).trim();
      if (!payload.startsWith("- ") || !payload.contains(":")) {
        continue;
      }
      String label = payload.substring(2, payload.indexOf(':')).trim();
      int order = FACETS.indexOf(label);
      if (order < 0) {
        continue;
      }
      if (!result.add(label) || order < previous) {
        diagnostics.add(new Diagnostic(
            "WDOC006",
            comment.line(),
            comment.column(),
            "duplicate or out-of-order documentation facet '" + label + "'"));
      }
      previous = Math.max(previous, order);
    }
    return result;
  }

  private static void requireFacet(
      Declaration declaration,
      Set<String> facets,
      String facet,
      String code,
      boolean required,
      List<Diagnostic> diagnostics) {
    if (!required || facets.contains(facet)) {
      return;
    }
    String kind = switch (facet) {
      case "Inverse" -> "rev";
      case "Coherent" -> "coherent";
      case "Adjoint" -> "unitary";
      case "Effects" -> "entry";
      default -> throw new IllegalArgumentException("Unknown required facet");
    };
    diagnostics.add(new Diagnostic(
        code,
        declaration.line(),
        declaration.column(),
        kind + " declaration '" + declaration.name() + "' requires a " + facet + " facet"));
  }

  private static boolean nonemptyPayload(Element comment) {
    String payload = comment.text().substring(3).trim();
    return !payload.isEmpty() && !payload.startsWith("-");
  }

  private static List<Declaration> declarations(SourceConcreteSyntax.Document document) {
    List<Declaration> result = new ArrayList<>();
    for (int index = 0; index < document.nodes().size(); index++) {
      SyntaxNode node = document.nodes().get(index);
      if (!node.kind().declaration()) {
        continue;
      }
      Element start = document.elements().get(node.startElement());
      boolean entry = node.modifiers().contains("entry");
      boolean reversible = node.modifiers().contains("rev");
      boolean coherent = node.modifiers().contains("coherent");
      boolean unitary = node.modifiers().contains("unitary");
      boolean semantic = entry || reversible || coherent || unitary
          || node.modifiers().contains("test")
          || node.kind() == NodeKind.THEOREM_DECLARATION
          || node.kind() == NodeKind.EXPERIMENT_DECLARATION;
      result.add(new Declaration(
          index,
          node.name(),
          start.line(),
          start.column(),
          node.modifiers().contains("public") || semantic,
          entry,
          reversible,
          coherent,
          unitary));
    }
    return List.copyOf(result);
  }
}
