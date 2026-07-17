package com.typeobject.wheeler.compiler;

import java.util.List;

final class SourceModel {
  record State(String name, long initialValue, int line) {}

  record Statement(String operation, List<String> arguments, int line) {
    Statement {
      arguments = List.copyOf(arguments);
    }
  }

  record Function(
      String name,
      boolean entry,
      boolean reversible,
      boolean coherent,
      List<Statement> statements,
      int line) {
    Function {
      statements = List.copyOf(statements);
    }
  }

  record SourceProgram(
      String name,
      String kind,
      List<State> states,
      List<Function> functions) {
    SourceProgram {
      states = List.copyOf(states);
      functions = List.copyOf(functions);
    }
  }

  private SourceModel() {}
}
