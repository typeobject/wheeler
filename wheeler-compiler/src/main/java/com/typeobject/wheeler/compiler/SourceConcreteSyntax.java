package com.typeobject.wheeler.compiler;

import java.util.List;

/** Lossless lexical source ranges shared by formatting and documentation tools. */
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

  /** Stable lexical placement of a comment relative to a token. */
  public enum Placement {
    LEADING,
    TRAILING,
    INNER,
    DETACHED
  }

  /** One comment attachment, indexed into the document element list. */
  public record CommentAttachment(
      int commentElement,
      Placement placement,
      int targetElement) {
    public CommentAttachment {
      if (commentElement < 0 || placement == null || targetElement < -1) {
        throw new IllegalArgumentException("Invalid comment attachment");
      }
      if (placement != Placement.DETACHED && targetElement < 0) {
        throw new IllegalArgumentException("Attached comment requires a target");
      }
    }
  }

  /** A lossless lexical document in source order. */
  public record Document(
      String source,
      List<Element> elements,
      List<CommentAttachment> comments) {
    public Document {
      if (source == null || elements == null || comments == null) {
        throw new IllegalArgumentException("Source document is required");
      }
      elements = List.copyOf(elements);
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

  /** Scans one bounded Wheeler source document with the compiler lexer. */
  public static Document scan(String source) {
    List<Element> elements = new SourceLexer(source).lexPieces().stream()
        .map(piece -> new Element(
            Kind.valueOf(piece.kind().name()),
            piece.text(),
            piece.offset(),
            piece.line(),
            piece.column()))
        .toList();
    return new Document(source, elements, attachComments(elements));
  }

  private static List<CommentAttachment> attachComments(List<Element> elements) {
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
        result.add(new CommentAttachment(index, Placement.INNER, before));
      } else if (before >= 0 && elements.get(before).line() == comment.line()) {
        result.add(new CommentAttachment(index, Placement.TRAILING, before));
      } else if (after >= 0 && blankTrivia[after] == blankTrivia[index + 1]) {
        result.add(new CommentAttachment(index, Placement.LEADING, after));
      } else {
        result.add(new CommentAttachment(index, Placement.DETACHED, -1));
      }
    }
    return List.copyOf(result);
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
