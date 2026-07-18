package com.typeobject.wheeler.compiler;

import com.typeobject.wheeler.compiler.SourceToken.Type;
import java.util.List;
import java.util.Set;

/** Shared bounded token cursor and source-located expectation diagnostics. */
abstract class SourceTokenCursor {
  private List<SourceToken> tokens = List.of();
  private int current;

  protected final void reset(String source) {
    tokens = new SourceLexer(source).lex();
    current = 0;
  }

  protected final boolean matchText(String text) {
    if (!checkText(text)) {
      return false;
    }
    advance();
    return true;
  }

  protected final SourceToken expectText(String text) {
    if (!checkText(text)) {
      fail(peek(), "expected '" + text + "'");
    }
    return advance();
  }

  protected final boolean checkText(String text) {
    return peek().type() == Type.IDENTIFIER && peek().text().equals(text);
  }

  protected final boolean checkTextIn(Set<String> values) {
    return peek().type() == Type.IDENTIFIER && values.contains(peek().text());
  }

  protected final boolean match(Type... types) {
    for (Type type : types) {
      if (check(type)) {
        advance();
        return true;
      }
    }
    return false;
  }

  protected final SourceToken expect(Type type, String description) {
    if (!check(type)) {
      fail(peek(), "expected " + description + ", got '" + peek().text() + "'");
    }
    return advance();
  }

  protected final boolean check(Type type) {
    return peek().type() == type;
  }

  protected final Type lookaheadType(int distance) {
    int index = current + distance;
    return index < tokens.size() ? tokens.get(index).type() : Type.END;
  }

  protected final SourceToken advance() {
    if (!check(Type.END)) {
      current++;
    }
    return previous();
  }

  protected final SourceToken peek() {
    return tokens.get(current);
  }

  protected final SourceToken previous() {
    return tokens.get(current - 1);
  }

  protected static void fail(SourceToken token, String message) {
    throw new CompilerException(token.line(), message + " at column " + token.column());
  }
}
