package com.typeobject.wheeler.compiler;

/** Exact source range emitted by the authoritative Wheeler lexer. */
record SourcePiece(Kind kind, String text, int offset, int line, int column) {
  enum Kind {
    TOKEN,
    WHITESPACE,
    LINE_COMMENT,
    BLOCK_COMMENT
  }
}
