package com.typeobject.wheeler.core.quantum;

import java.util.List;
import java.util.Objects;

/** One immutable semantic gate application over ordered logical qubits. */
public record GateOperation(Gate gate, List<Integer> qubits, double parameter)
    implements QuantumOperation {
  private static final double NO_PARAMETER = 0.0;

  public GateOperation {
    Objects.requireNonNull(gate, "gate");
    qubits = List.copyOf(qubits);
    if (qubits.size() != gate.arity() || qubits.stream().anyMatch(index -> index < 0)) {
      throw new IllegalArgumentException("Invalid operands for " + gate);
    }
    if (!Double.isFinite(parameter) || (!gate.parameterized() && parameter != NO_PARAMETER)) {
      throw new IllegalArgumentException("Gate parameter does not match " + gate.form());
    }
  }

  public static GateOperation of(Gate gate, int... qubits) {
    return new GateOperation(
        gate,
        java.util.Arrays.stream(qubits).boxed().toList(),
        NO_PARAMETER);
  }

  @Override
  public QuantumOperation inverse() {
    return new GateOperation(gate, qubits, gate.inverseParameter(parameter));
  }
}
