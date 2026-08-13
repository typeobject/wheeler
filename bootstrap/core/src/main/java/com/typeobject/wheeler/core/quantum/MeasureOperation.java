package com.typeobject.wheeler.core.quantum;

/** Measures one logical qubit into a bounded target-resident classical slot. */
public record MeasureOperation(int qubit, int resultSlot) implements QuantumOperation {
  public MeasureOperation {
    if (qubit < 0 || resultSlot < 0) {
      throw new IllegalArgumentException("Quantum measurement operands must be nonnegative");
    }
  }

  @Override
  public QuantumOperation inverse() {
    throw new IllegalStateException("Quantum measurement has no unitary inverse");
  }
}
