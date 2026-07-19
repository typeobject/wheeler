package com.typeobject.wheeler.compiler;

/** One formatting-independent source token with its exact source location. */
record SourceToken(Type type, String text, int line, int column, int offset) {
  enum Type {
    IDENTIFIER,
    NUMBER,
    STRING,
    LEFT_BRACE,
    RIGHT_BRACE,
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACKET,
    RIGHT_BRACKET,
    SEMICOLON,
    COMMA,
    DOT,
    DOUBLE_COLON,
    ASSIGN,
    EQUAL,
    PLUS_ASSIGN,
    MINUS_ASSIGN,
    XOR_ASSIGN,
    PLUS,
    MINUS,
    STAR,
    SLASH,
    PERCENT,
    NOT,
    AND,
    XOR,
    LESS,
    END
  }
}
