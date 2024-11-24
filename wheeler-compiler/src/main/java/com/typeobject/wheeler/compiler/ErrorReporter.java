package com.typeobject.wheeler.compiler;

import java.util.List;

public class ErrorReporter {
  private final List<CompilerError> errors = new ArrayList<>();

  public void reportError(String message) {
    errors.add(new CompilerError(message));
  }

  public void reportError(String message, int line, int column) {
    errors.add(new CompilerError(message, line, column));
  }

  public boolean hasErrors() {
    return !errors.isEmpty();
  }

  public void printErrors() {
    errors.forEach(System.err::println);
  }
}
