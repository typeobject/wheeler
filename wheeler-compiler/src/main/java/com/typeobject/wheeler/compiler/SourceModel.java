package com.typeobject.wheeler.compiler;

import java.util.List;

final class SourceModel {
  record State(String name, long initialValue, int line) {}

  record QuantumRegisterSource(String name, int qubits, int line) {}

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

  record Circuit(String name, String registerName, List<Statement> statements, int line) {
    Circuit {
      statements = List.copyOf(statements);
    }
  }

  record SourceProgram(
      String name,
      String kind,
      List<State> states,
      List<Function> functions,
      List<QuantumRegisterSource> quantumRegisters,
      List<Circuit> circuits) {
    SourceProgram {
      states = List.copyOf(states);
      functions = List.copyOf(functions);
      quantumRegisters = List.copyOf(quantumRegisters);
      circuits = List.copyOf(circuits);
    }
  }

  private SourceModel() {}
}
