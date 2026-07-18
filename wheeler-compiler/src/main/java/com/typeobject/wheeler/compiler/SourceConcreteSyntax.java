package com.typeobject.wheeler.compiler;

import java.util.List;

/** Lossless parser-owned source ranges shared by formatting and documentation tools. */
public final class SourceConcreteSyntax {
  /** Concrete lexical range kind. */
  public enum Kind {
    TOKEN,
    WHITESPACE,
    LINE_COMMENT,
    BLOCK_COMMENT
  }

  /** One exact source range with a one-based start location. */
  public record Element(
      Kind kind,
      String text,
      int offset,
      int line,
      int column) {
    public Element {
      if (kind == null || text == null || offset < 0 || line < 1 || column < 1) {
        throw new IllegalArgumentException("Invalid concrete source element");
      }
    }
  }

  /** Stable parser-owned concrete node kinds. */
  public enum NodeKind {
    COMPILATION_UNIT,
    MODULE_DECLARATION,
    IMPORT_DECLARATION,
    TYPE_DECLARATION,
    STATE_DECLARATION,
    CONSTANT_DECLARATION,
    QUANTUM_REGISTER_DECLARATION,
    RECORD_DECLARATION,
    VARIANT_DECLARATION,
    ENUM_DECLARATION,
    THEOREM_DECLARATION,
    EXPERIMENT_DECLARATION,
    METHOD_DECLARATION,
    BLOCK;

    /** Whether this node is a class member declaration. */
    public boolean declaration() {
      return switch (this) {
        case STATE_DECLARATION, CONSTANT_DECLARATION, QUANTUM_REGISTER_DECLARATION,
            RECORD_DECLARATION, VARIANT_DECLARATION, ENUM_DECLARATION,
            THEOREM_DECLARATION, EXPERIMENT_DECLARATION, METHOD_DECLARATION -> true;
        default -> false;
      };
    }
  }

  /** One parser-owned inclusive element range. */
  public record SyntaxNode(
      NodeKind kind,
      int startElement,
      int endElement,
      String name,
      List<String> modifiers) {
    public SyntaxNode {
      if (kind == null || startElement < 0 || endElement < startElement
          || name == null || modifiers == null) {
        throw new IllegalArgumentException("Invalid concrete syntax node");
      }
      modifiers = List.copyOf(modifiers);
    }
  }

  /** One structural parser recovery that prevents source publication. */
  public record Recovery(
      int element,
      int line,
      int column,
      String message) {
    public Recovery {
      if (element < 0 || line < 1 || column < 1 || message == null || message.isBlank()) {
        throw new IllegalArgumentException("Invalid concrete syntax recovery");
      }
    }
  }

  /** Stable placement of a comment relative to a parser-owned range. */
  public enum Placement {
    LEADING,
    TRAILING,
    INNER,
    DETACHED
  }

  /** One comment attachment, indexed into document element and syntax-node lists. */
  public record CommentAttachment(
      int commentElement,
      Placement placement,
      int targetElement,
      int targetNode) {
    public CommentAttachment {
      if (commentElement < 0 || placement == null || targetElement < -1 || targetNode < -1) {
        throw new IllegalArgumentException("Invalid comment attachment");
      }
      if (placement != Placement.DETACHED && (targetElement < 0 || targetNode < 0)) {
        throw new IllegalArgumentException("Attached comment requires parser-owned targets");
      }
      if (placement == Placement.DETACHED && (targetElement >= 0 || targetNode >= 0)) {
        throw new IllegalArgumentException("Detached comment must not have a target");
      }
    }
  }

  /** A lossless structural document in source order. */
  public record Document(
      String source,
      List<Element> elements,
      List<SyntaxNode> nodes,
      List<Recovery> recoveries,
      List<CommentAttachment> comments) {
    public Document {
      if (source == null || elements == null || nodes == null
          || recoveries == null || comments == null) {
        throw new IllegalArgumentException("Source document is required");
      }
      elements = List.copyOf(elements);
      nodes = List.copyOf(nodes);
      recoveries = List.copyOf(recoveries);
      comments = List.copyOf(comments);
    }

    /** Reconstructs the input exactly, including comments and whitespace. */
    public String reconstruct() {
      StringBuilder result = new StringBuilder(source.length());
      elements.forEach(element -> result.append(element.text()));
      return result.toString();
    }
  }

  private SourceConcreteSyntax() {}

  /** Scans and structurally parses one bounded Wheeler source document. */
  public static Document scan(String source) {
    List<Element> elements = new SourceLexer(source).lexPieces().stream()
        .map(piece -> new Element(
            Kind.valueOf(piece.kind().name()),
            piece.text(),
            piece.offset(),
            piece.line(),
            piece.column()))
        .toList();
    SourceSyntaxParser.Result syntax = SourceSyntaxParser.parse(elements);
    return new Document(
        source,
        elements,
        syntax.nodes(),
        syntax.recoveries(),
        attachComments(elements, syntax.nodes()));
  }

  private static List<CommentAttachment> attachComments(
      List<Element> elements, List<SyntaxNode> nodes) {
    int[] previousToken = new int[elements.size()];
    int[] nextToken = new int[elements.size()];
    int[] blankTrivia = new int[elements.size() + 1];
    int previous = -1;
    for (int index = 0; index < elements.size(); index++) {
      previousToken[index] = previous;
      Element element = elements.get(index);
      if (element.kind() == Kind.TOKEN) {
        previous = index;
      }
      blankTrivia[index + 1] = blankTrivia[index]
          + (element.kind() == Kind.WHITESPACE && lineBreaks(element.text()) > 1 ? 1 : 0);
    }
    int next = -1;
    for (int index = elements.size() - 1; index >= 0; index--) {
      nextToken[index] = next;
      if (elements.get(index).kind() == Kind.TOKEN) {
        next = index;
      }
    }

    java.util.ArrayList<CommentAttachment> result = new java.util.ArrayList<>();
    for (int index = 0; index < elements.size(); index++) {
      Element comment = elements.get(index);
      if (comment.kind() != Kind.LINE_COMMENT && comment.kind() != Kind.BLOCK_COMMENT) {
        continue;
      }
      int before = previousToken[index];
      int after = nextToken[index];
      if (before >= 0
          && after >= 0
          && elements.get(before).text().equals("{")
          && elements.get(after).text().equals("}")) {
        result.add(attachment(index, Placement.INNER, before, nodes));
      } else if (before >= 0 && elements.get(before).line() == comment.line()) {
        result.add(attachment(index, Placement.TRAILING, before, nodes));
      } else if (after >= 0 && blankTrivia[after] == blankTrivia[index + 1]) {
        result.add(attachment(index, Placement.LEADING, after, nodes));
      } else {
        result.add(new CommentAttachment(index, Placement.DETACHED, -1, -1));
      }
    }
    return List.copyOf(result);
  }

  private static CommentAttachment attachment(
      int comment, Placement placement, int target, List<SyntaxNode> nodes) {
    int node = targetNode(placement, target, nodes);
    if (node < 0) {
      return new CommentAttachment(comment, Placement.DETACHED, -1, -1);
    }
    return new CommentAttachment(comment, placement, target, node);
  }

  private static int targetNode(
      Placement placement, int target, List<SyntaxNode> nodes) {
    int exact = -1;
    int exactWidth = Integer.MAX_VALUE;
    int containing = -1;
    int containingWidth = Integer.MAX_VALUE;
    for (int index = 0; index < nodes.size(); index++) {
      SyntaxNode node = nodes.get(index);
      int width = node.endElement() - node.startElement();
      if ((placement == Placement.LEADING || placement == Placement.INNER)
          && node.startElement() == target
          && (placement != Placement.INNER || node.kind() == NodeKind.BLOCK)
          && width < exactWidth) {
        exact = index;
        exactWidth = width;
      }
      if (node.startElement() <= target && node.endElement() >= target
          && width < containingWidth) {
        containing = index;
        containingWidth = width;
      }
    }
    return exact >= 0 ? exact : containing;
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
}
