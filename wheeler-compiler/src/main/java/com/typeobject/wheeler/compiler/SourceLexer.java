package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.List;

/** Formatting-independent lexer with stable line, column, and byte-offset locations. */
final class SourceLexer {
  private final String source;
  private final List<SourceToken> tokens = new ArrayList<>();
  private int offset;
  private int line = 1;
  private int column = 1;

  SourceLexer(String source) {
    this.source = source;
  }

  List<SourceToken> lex() {
    while (!atEnd()) {
      char current = peek();
      if (Character.isWhitespace(current)) {
        whitespace();
      } else if (current == '/' && peekNext() == '/') {
        lineComment();
      } else if (current == '/' && peekNext() == '*') {
        blockComment();
      } else if (Character.isJavaIdentifierStart(current)) {
        identifier();
      } else if (Character.isDigit(current)) {
        number();
      } else {
        symbol();
      }
    }
    tokens.add(new SourceToken(Type.END, "", line, column, offset));
    return List.copyOf(tokens);
  }

  private void whitespace() {
    while (!atEnd() && Character.isWhitespace(peek())) {
      advance();
    }
  }

  private void lineComment() {
    while (!atEnd() && peek() != '\n') {
      advance();
    }
  }

  private void blockComment() {
    int startLine = line;
    advance();
    advance();
    while (!atEnd() && !(peek() == '*' && peekNext() == '/')) {
      advance();
    }
    if (atEnd()) {
      throw new CompilerException(startLine, "unclosed block comment");
    }
    advance();
    advance();
  }

  private void identifier() {
    int start = offset;
    int startLine = line;
    int startColumn = column;
    advance();
    while (!atEnd() && Character.isJavaIdentifierPart(peek())) {
      advance();
    }
    add(Type.IDENTIFIER, start, startLine, startColumn);
  }

  private void number() {
    int start = offset;
    int startLine = line;
    int startColumn = column;
    advance();
    while (!atEnd() && isNumberPart(peek())) {
      advance();
    }
    add(Type.NUMBER, start, startLine, startColumn);
  }

  private static boolean isNumberPart(char value) {
    return Character.isLetterOrDigit(value)
        || value == '_'
        || value == '.'
        || value == '+'
        || value == '-';
  }

  private void symbol() {
    int start = offset;
    int startLine = line;
    int startColumn = column;
    char value = advance();
    Type type = switch (value) {
      case '{' -> Type.LEFT_BRACE;
      case '}' -> Type.RIGHT_BRACE;
      case '(' -> Type.LEFT_PAREN;
      case ')' -> Type.RIGHT_PAREN;
      case '[' -> Type.LEFT_BRACKET;
      case ']' -> Type.RIGHT_BRACKET;
      case ';' -> Type.SEMICOLON;
      case ',' -> Type.COMMA;
      case '.' -> Type.DOT;
      case '-' -> match('=') ? Type.MINUS_ASSIGN : Type.MINUS;
      case '+' -> requiredCompound('=', Type.PLUS_ASSIGN, startLine, "+");
      case '^' -> requiredCompound('=', Type.XOR_ASSIGN, startLine, "^");
      case '=' -> match('=') ? Type.EQUAL : Type.ASSIGN;
      default -> throw new CompilerException(startLine, "unexpected character: " + value);
    };
    tokens.add(new SourceToken(type, source.substring(start, offset), startLine, startColumn, start));
  }

  private Type requiredCompound(char expected, Type type, int sourceLine, String operator) {
    if (!match(expected)) {
      throw new CompilerException(sourceLine, "expected " + operator + expected);
    }
    return type;
  }

  private void add(Type type, int start, int startLine, int startColumn) {
    tokens.add(new SourceToken(type, source.substring(start, offset), startLine, startColumn, start));
  }

  private boolean match(char expected) {
    if (atEnd() || peek() != expected) {
      return false;
    }
    advance();
    return true;
  }

  private char advance() {
    char value = source.charAt(offset++);
    if (value == '\n') {
      line++;
      column = 1;
    } else {
      column++;
    }
    return value;
  }

  private char peek() {
    return source.charAt(offset);
  }

  private char peekNext() {
    return offset + 1 < source.length() ? source.charAt(offset + 1) : '\0';
  }

  private boolean atEnd() {
    return offset >= source.length();
  }
}
