package com.typeobject.wheeler.core.quantum;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/** A unitary region tied to one logical register in the first quantum profile. */
public record QuantumCircuit(
    int id, String name, int registerId, List<QuantumOperation> operations) {
  public QuantumCircuit {
    if (id < 0 || registerId < 0) {
      throw new IllegalArgumentException("Invalid circuit identity");
    }
    Objects.requireNonNull(name, "name");
    operations = List.copyOf(operations);
  }

  public List<QuantumOperation> inverseOperations() {
    List<QuantumOperation> result = new ArrayList<>(operations.size());
    for (int i = operations.size() - 1; i >= 0; i--) {
      result.add(operations.get(i).inverse());
    }
    return List.copyOf(result);
  }
}
