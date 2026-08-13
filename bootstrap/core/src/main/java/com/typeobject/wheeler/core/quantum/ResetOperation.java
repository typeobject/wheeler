package com.typeobject.wheeler.core.quantum;

/** Resets one logical qubit to the zero basis state. */
public record ResetOperation(int qubit) implements QuantumOperation {
  public ResetOperation {
    if (qubit < 0) {
      throw new IllegalArgumentException("Quantum reset qubit must be nonnegative");
    }
  }

  @Override
  public QuantumOperation inverse() {
    throw new IllegalStateException("Quantum reset has no unitary inverse");
  }
}
