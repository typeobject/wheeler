package com.typeobject.wheeler.compiler;

import java.util.List;

final class SourceModel {
  record State(String name, long initialValue, int line) {}

  record QuantumRegisterSource(String name, int qubits, int line) {}

  record Parameter(String name, String type) {}

  record RecordField(String name, String type) {}

  record RecordDefinition(String name, List<RecordField> fields, int line) {
    RecordDefinition {
      fields = List.copyOf(fields);
    }
  }

  record VariantCase(String name, List<RecordField> fields) {
    VariantCase {
      fields = List.copyOf(fields);
    }
  }

  record VariantDefinition(String name, List<VariantCase> cases, int line) {
    VariantDefinition {
      cases = List.copyOf(cases);
    }
  }

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
      List<Parameter> parameters,
      String returnType,
      List<Statement> statements,
      int line) {
    Function {
      parameters = List.copyOf(parameters);
      statements = List.copyOf(statements);
    }

    boolean returnsValue() {
      return !returnType.equals("void");
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
      List<RecordDefinition> records,
      List<VariantDefinition> variants,
      List<Function> functions,
      List<QuantumRegisterSource> quantumRegisters,
      List<Circuit> circuits) {
    SourceProgram {
      states = List.copyOf(states);
      records = List.copyOf(records);
      variants = List.copyOf(variants);
      functions = List.copyOf(functions);
      quantumRegisters = List.copyOf(quantumRegisters);
      circuits = List.copyOf(circuits);
    }
  }

  private SourceModel() {}
}
