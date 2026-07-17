package com.typeobject.wheeler.runtime.quantum;

/** One forward circuit or generated adjoint in a submitted task. */
public record CircuitApplication(int circuitId, boolean inverse) {
  public CircuitApplication {
    if (circuitId < 0) {
      throw new IllegalArgumentException("Invalid circuit ID");
    }
  }
}
