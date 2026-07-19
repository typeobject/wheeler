package com.typeobject.wheeler.core.quantum;

import java.util.List;
import java.util.Objects;

/** One immutable semantic gate application over ordered logical qubits. */
public record GateOperation(Gate gate, List<Integer> qubits, double parameter)
    implements QuantumOperation {
  public GateOperation {
    Objects.requireNonNull(gate, "gate");
    qubits = List.copyOf(qubits);
    if (qubits.size() != gate.arity() || qubits.stream().anyMatch(index -> index < 0)) {
      throw new IllegalArgumentException("Invalid operands for " + gate);
    }
    if (!Double.isFinite(parameter)) {
      throw new IllegalArgumentException("Gate parameter must be finite");
    }
  }

  public static GateOperation of(Gate gate, int... qubits) {
    return new GateOperation(gate, java.util.Arrays.stream(qubits).boxed().toList(), 0.0);
  }

  @Override
  public QuantumOperation inverse() {
    return new GateOperation(gate, qubits, gate.inverseParameter(parameter));
  }
}
