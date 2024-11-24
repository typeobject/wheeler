package com.typeobject.wheeler.compiler.ast;

public record Position(String sourceFile, int line, int column) {
  public static final Position UNKNOWN = new Position("<unknown>", 0, 0);

  @Override
  public String toString() {
    return String.format("%s:%d:%d", sourceFile, line, column);
  }
}
