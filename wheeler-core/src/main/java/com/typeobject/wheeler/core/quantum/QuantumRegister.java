package com.typeobject.wheeler.core.quantum;

import java.util.Objects;

/** A logical affine register declaration. */
public record QuantumRegister(int id, String name, int qubits) {
  public QuantumRegister {
    if (id < 0 || qubits <= 0 || qubits > 62) {
      throw new IllegalArgumentException("Invalid quantum register shape");
    }
    Objects.requireNonNull(name, "name");
  }
}
