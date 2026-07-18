package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceConcreteSyntax.CommentAttachment;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Element;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Kind;
import com.typeobject.wheeler.compiler.SourceConcreteSyntax.Placement;
import com.typeobject.wheeler.compiler.SourceDocumentation.Diagnostic;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

/** Declaration coverage and facet checks over lexical declaration boundaries. */
final class SourceDeclarationDocumentation {
  private static final List<String> FACETS = List.of(
      "Inputs", "Returns", "Effects", "Inverse", "Coherent", "Adjoint",
      "Traps", "Bounds", "Proof", "See also");
  private static final Set<String> MODIFIERS = Set.of(
      "public", "private", "protected", "entry", "coherent", "rev", "unitary");
  private static final Set<String> NAMED_TYPES = Set.of(
      "state", "const", "qreg", "record", "variant", "enum", "theorem", "experiment");

  private record Declaration(
      int element,
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
    List<Element> elements = document.elements();
    List<Declaration> declarations = declarations(elements);
    Map<Integer, Declaration> targets = new HashMap<>();
    declarations.forEach(declaration -> targets.put(declaration.element(), declaration));
    Map<Integer, List<Element>> documentation = attachedDocumentation(document, targets);
    List<Diagnostic> diagnostics = new ArrayList<>();

    for (CommentAttachment attachment : document.comments()) {
      Element comment = elements.get(attachment.commentElement());
      if (!comment.text().startsWith("///")) {
        continue;
      }
      if (attachment.placement() != Placement.LEADING
          || !targets.containsKey(attachment.targetElement())) {
        diagnostics.add(new Diagnostic(
            "WDOC004",
            comment.line(),
            comment.column(),
            "/// documentation must be adjacent to a declaration"));
      }
    }

    for (Declaration declaration : declarations) {
      List<Element> comments = documentation.getOrDefault(declaration.element(), List.of());
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
          && targets.containsKey(attachment.targetElement())) {
        result.computeIfAbsent(attachment.targetElement(), ignored -> new ArrayList<>())
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

  private static List<Declaration> declarations(List<Element> elements) {
    List<Integer> tokens = new ArrayList<>();
    for (int index = 0; index < elements.size(); index++) {
      if (elements.get(index).kind() == Kind.TOKEN) {
        tokens.add(index);
      }
    }
    List<Declaration> result = new ArrayList<>();
    int depth = 0;
    boolean memberBoundary = false;
    for (int token = 0; token < tokens.size(); token++) {
      String text = elements.get(tokens.get(token)).text();
      if (text.equals("{")) {
        depth++;
        if (depth == 1) {
          memberBoundary = true;
        }
        continue;
      }
      if (text.equals("}")) {
        depth--;
        if (depth == 1) {
          memberBoundary = true;
        }
        continue;
      }
      if (depth == 1 && text.equals(";")) {
        memberBoundary = true;
        continue;
      }
      if (depth != 1 || !memberBoundary) {
        continue;
      }
      memberBoundary = false;
      Declaration declaration = declarationAt(elements, tokens, token);
      if (declaration != null) {
        result.add(declaration);
      }
    }
    return List.copyOf(result);
  }

  private static Declaration declarationAt(
      List<Element> elements,
      List<Integer> tokens,
      int start) {
    boolean exported = false;
    boolean entry = false;
    boolean reversible = false;
    boolean coherent = false;
    boolean unitary = false;
    int cursor = start;
    while (cursor < tokens.size() && MODIFIERS.contains(text(elements, tokens, cursor))) {
      String modifier = text(elements, tokens, cursor);
      exported |= modifier.equals("public");
      entry |= modifier.equals("entry");
      reversible |= modifier.equals("rev");
      coherent |= modifier.equals("coherent");
      unitary |= modifier.equals("unitary");
      cursor++;
    }
    if (cursor >= tokens.size()) {
      return null;
    }
    String kind = text(elements, tokens, cursor);
    String name;
    if (NAMED_TYPES.contains(kind)) {
      name = namedDeclarationName(elements, tokens, cursor, kind);
    } else {
      int opener = findSignatureOpener(elements, tokens, cursor);
      if (opener <= cursor) {
        return null;
      }
      name = text(elements, tokens, opener - 1);
    }
    Element element = elements.get(tokens.get(start));
    boolean semantic = entry || reversible || coherent || unitary
        || kind.equals("theorem") || kind.equals("experiment");
    return new Declaration(
        tokens.get(start), name, element.line(), element.column(), exported || semantic,
        entry, reversible, coherent, unitary);
  }

  private static String namedDeclarationName(
      List<Element> elements,
      List<Integer> tokens,
      int cursor,
      String kind) {
    if (kind.equals("state") || kind.equals("const")) {
      int assignment = cursor + 1;
      while (assignment < tokens.size()
          && !text(elements, tokens, assignment).equals("=")
          && !text(elements, tokens, assignment).equals(";")) {
        assignment++;
      }
      return assignment > cursor + 1 ? text(elements, tokens, assignment - 1) : kind;
    }
    return cursor + 1 < tokens.size() ? text(elements, tokens, cursor + 1) : kind;
  }

  private static int findSignatureOpener(
      List<Element> elements,
      List<Integer> tokens,
      int cursor) {
    int limit = Math.min(tokens.size(), cursor + 16);
    for (int index = cursor; index < limit; index++) {
      String text = text(elements, tokens, index);
      if (text.equals("(")) {
        return index;
      }
      if (text.equals(";") || text.equals("{") || text.equals("=")) {
        return -1;
      }
    }
    return -1;
  }

  private static String text(
      List<Element> elements,
      List<Integer> tokens,
      int token) {
    return elements.get(tokens.get(token)).text();
  }
}
