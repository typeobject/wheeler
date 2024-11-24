
// ErrorReporter.java
package com.typeobject.wheeler.compiler;

import java.util.ArrayList;
import java.util.List;
import com.typeobject.wheeler.compiler.ast.Position;

public class ErrorReporter {
  private final List<CompilerError> errors = new ArrayList<>();
  private final List<CompilerError> warnings = new ArrayList<>();

  public void report(String message, Position position) {
    errors.add(new CompilerError(message, position));
  }

  public void warn(String message, Position position) {
    warnings.add(new CompilerError(message, position));
  }

  public boolean hasErrors() {
    return !errors.isEmpty();
  }

  public List<CompilerError> getErrors() {
    return errors;
  }

  public List<CompilerError> getWarnings() {
    return warnings;
  }
}