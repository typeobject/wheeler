package com.typeobject.wheeler.core.quantum;

import java.util.Objects;

/** Applies one fixed gate when a target-resident classical slot matches a Boolean value. */
public record ConditionalGateOperation(
    int resultSlot, boolean expected, GateOperation gate) implements QuantumOperation {
  public ConditionalGateOperation {
    if (resultSlot < 0) {
      throw new IllegalArgumentException("Conditional result slot must be nonnegative");
    }
    Objects.requireNonNull(gate, "gate");
    if (gate.gate().parameterized()) {
      throw new IllegalArgumentException("Conditional gates must use fixed gate forms");
    }
  }

  @Override
  public QuantumOperation inverse() {
    return new ConditionalGateOperation(
        resultSlot, expected, (GateOperation) gate.inverse());
  }
}
