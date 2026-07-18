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

  /** A lossless lexical document in source order. */
  public record Document(String source, List<Element> elements) {
    public Document {
      if (source == null || elements == null) {
        throw new IllegalArgumentException("Source document is required");
      }
      elements = List.copyOf(elements);
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
    return new Document(source, elements);
  }
}
