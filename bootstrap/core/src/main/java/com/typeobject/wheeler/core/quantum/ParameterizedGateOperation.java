package com.typeobject.wheeler.core.quantum;

import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Semantic phase gate whose finite angle is supplied by a task binding. */
public record ParameterizedGateOperation(
    Gate gate, List<Integer> qubits, String parameterName, double scale)
    implements QuantumOperation {
  public ParameterizedGateOperation {
    Objects.requireNonNull(gate, "gate");
    Objects.requireNonNull(parameterName, "parameterName");
    qubits = List.copyOf(qubits);
    if ((gate != Gate.PHASE && gate != Gate.CPHASE)
        || qubits.size() != gate.arity()
        || qubits.stream().anyMatch(index -> index < 0)
        || parameterName.isBlank()
        || parameterName.length() > 1024
        || !Double.isFinite(scale)) {
      throw new IllegalArgumentException("Invalid parameterized gate operation");
    }
  }

  public GateOperation bind(Map<String, Double> bindings) {
    Double value = bindings.get(parameterName);
    if (value == null || !Double.isFinite(value)) {
      throw new IllegalArgumentException("Missing or invalid quantum parameter " + parameterName);
    }
    double angle = value * scale;
    if (!Double.isFinite(angle)) {
      throw new IllegalArgumentException("Bound quantum parameter is not finite: " + parameterName);
    }
    return new GateOperation(gate, qubits, angle);
  }

  @Override
  public QuantumOperation inverse() {
    return new ParameterizedGateOperation(gate, qubits, parameterName, -scale);
  }
}
