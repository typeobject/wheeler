package com.typeobject.wheeler.compiler;

record CompilerError(String message, int line, int column) {
  CompilerError(String message) {
    this(message, -1, -1);
  }

  @Override
  public String toString() {
    if (line >= 0) {
      return String.format("Error at %d:%d: %s", line, column, message);
    }
    return "Error: " + message;
  }
}
