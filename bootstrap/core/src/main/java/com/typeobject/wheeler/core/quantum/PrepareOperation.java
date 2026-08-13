package com.typeobject.wheeler.core.quantum;

/** Prepares one complete logical register in a declared basis state. */
public record PrepareOperation(long basisState) implements QuantumOperation {
  public PrepareOperation {
    if (basisState < 0) {
      throw new IllegalArgumentException("Quantum basis state must be nonnegative");
    }
  }

  @Override
  public QuantumOperation inverse() {
    throw new IllegalStateException("Quantum preparation has no unitary inverse");
  }
}
