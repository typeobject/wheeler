package com.typeobject.wheeler.compiler;

public class CompilerError {
  private final String message;
  private final int line;
  private final int column;

  public CompilerError(String message) {
    this(message, -1, -1);
  }

  public CompilerError(String message, int line, int column) {
    this.message = message;
    this.line = line;
    this.column = column;
  }

  public String getMessage() {
    return message;
  }

  public int getLine() {
    return line;
  }

  public int getColumn() {
    return column;
  }

  @Override
  public String toString() {
    if (line >= 0) {
      return String.format("Error at %d:%d: %s", line, column, message);
    }
    return "Error: " + message;
  }
}