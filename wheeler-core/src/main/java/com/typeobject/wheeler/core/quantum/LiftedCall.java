package com.typeobject.wheeler.core.quantum;

/** Coherent invocation of a compiler-validated classical reversible function. */
public record LiftedCall(int functionId, boolean inverseDirection) implements QuantumOperation {
  public LiftedCall {
    if (functionId < 0) {
      throw new IllegalArgumentException("Invalid lifted function ID");
    }
  }

  @Override
  public QuantumOperation inverse() {
    return new LiftedCall(functionId, !inverseDirection);
  }
}
