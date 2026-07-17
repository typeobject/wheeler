package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.Program;
import java.util.List;
import java.util.Objects;

/** A complete portable prepare-unitary-measure target submission. */
public record QuantumTask(
    Program program,
    int registerId,
    long basisState,
    List<CircuitApplication> applications,
    int shots,
    long seed) {
  public QuantumTask {
    Objects.requireNonNull(program, "program");
    applications = List.copyOf(applications);
    if (registerId < 0 || shots <= 0) {
      throw new IllegalArgumentException("Invalid quantum task");
    }
  }
}
