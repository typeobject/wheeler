package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.ArrayList;
import java.util.List;

/** Formatting-independent lexer with stable line, column, and source-character offsets. */
final class SourceLexer {
  static final int MAX_SOURCE_CHARS = 16 * 1024 * 1024;
  static final long MAX_SOURCE_BYTES = 4L * MAX_SOURCE_CHARS;
  static final int MAX_TOKEN_CHARS = 4_096;
  static final int MAX_TOKENS = 1_000_000;
  static final int MAX_LINES = 1_000_000;

  private final String source;
  private final List<SourceToken> tokens = new ArrayList<>();
  private int offset;
  private int line = 1;
  private int column = 1;

  SourceLexer(String source) {
    if (source == null || source.length() > MAX_SOURCE_CHARS) {
      throw new CompilerException(1, "source exceeds the 16 Mi-character limit");
    }
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
      } else if (isIdentifierStart(current)) {
        identifier();
      } else if (Character.isDigit(current)) {
        number();
      } else if (current == '"') {
        asciiString();
      } else {
        symbol();
      }
    }
    emit(new SourceToken(Type.END, "", line, column, offset));
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
    while (!atEnd() && isIdentifierPart(peek())) {
      advance();
    }
    add(Type.IDENTIFIER, start, startLine, startColumn);
  }

  private void number() {
    int start = offset;
    int startLine = line;
    int startColumn = column;
    advance();
    boolean exponent = false;
    while (!atEnd()) {
      char value = peek();
      if (Character.isLetterOrDigit(value) || value == '_' || value == '.') {
        exponent = value == 'e' || value == 'E';
        advance();
      } else if ((value == '+' || value == '-') && exponent) {
        exponent = false;
        advance();
      } else {
        break;
      }
    }
    add(Type.NUMBER, start, startLine, startColumn);
  }

  private void asciiString() {
    int start = offset;
    int startLine = line;
    int startColumn = column;
    advance();
    int contentStart = offset;
    while (!atEnd() && peek() != '"') {
      char value = peek();
      if (value < 0x20 || value > 0x7e) {
        throw new CompilerException(startLine, "ASCII literal contains a non-ASCII character");
      }
      advance();
    }
    if (atEnd()) {
      throw new CompilerException(startLine, "unclosed ASCII literal");
    }
    String text = source.substring(contentStart, offset);
    advance();
    if (text.length() > MAX_TOKEN_CHARS) {
      throw new CompilerException(startLine, "token exceeds the 4,096-character limit");
    }
    emit(new SourceToken(Type.STRING, text, startLine, startColumn, start));
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
      case ':' -> doubleColon(startLine);
      case '-' -> match('=') ? Type.MINUS_ASSIGN : Type.MINUS;
      case '+' -> match('=') ? Type.PLUS_ASSIGN : Type.PLUS;
      case '*' -> Type.STAR;
      case '/' -> Type.SLASH;
      case '%' -> Type.PERCENT;
      case '&' -> Type.AND;
      case '^' -> match('=') ? Type.XOR_ASSIGN : Type.XOR;
      case '<' -> Type.LESS;
      case '=' -> match('=') ? Type.EQUAL : Type.ASSIGN;
      default -> throw new CompilerException(startLine, "unexpected character: " + value);
    };
    add(type, start, startLine, startColumn);
  }

  private Type doubleColon(int startLine) {
    if (!match(':')) {
      throw new CompilerException(startLine, "expected '::'");
    }
    return Type.DOUBLE_COLON;
  }

  private void add(Type type, int start, int startLine, int startColumn) {
    int length = offset - start;
    if (length > MAX_TOKEN_CHARS) {
      throw new CompilerException(startLine, "token exceeds the 4,096-character limit");
    }
    emit(new SourceToken(
        type, source.substring(start, offset), startLine, startColumn, start));
  }

  private void emit(SourceToken token) {
    if (tokens.size() >= MAX_TOKENS) {
      throw new CompilerException(token.line(), "source exceeds the 1,000,000-token limit");
    }
    tokens.add(token);
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
      if (line > MAX_LINES) {
        throw new CompilerException(line, "source exceeds the 1,000,000-line limit");
      }
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

  private static boolean isIdentifierStart(char value) {
    return value == '_'
        || value >= 'A' && value <= 'Z'
        || value >= 'a' && value <= 'z';
  }

  private static boolean isIdentifierPart(char value) {
    return isIdentifierStart(value) || value >= '0' && value <= '9';
  }
}
