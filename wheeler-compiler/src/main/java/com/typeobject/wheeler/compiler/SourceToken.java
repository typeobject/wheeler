package com.typeobject.wheeler.compiler;

record SourceToken(Type type, String text, int line, int column, int offset) {
  enum Type {
    IDENTIFIER,
    NUMBER,
    LEFT_BRACE,
    RIGHT_BRACE,
    LEFT_PAREN,
    RIGHT_PAREN,
    LEFT_BRACKET,
    RIGHT_BRACKET,
    SEMICOLON,
    COMMA,
    DOT,
    ASSIGN,
    EQUAL,
    PLUS_ASSIGN,
    MINUS_ASSIGN,
    XOR_ASSIGN,
    MINUS,
    END
  }
}
