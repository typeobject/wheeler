package com.typeobject.wheeler.compiler;

/** A source diagnostic with a stable line number. */
public final class CompilerException extends RuntimeException {
  private static final long serialVersionUID = 1L;

  private final int line;

  public CompilerException(int line, String message) {
    super("line " + line + ": " + message);
    this.line = line;
  }

  public int line() {
    return line;
  }
}
