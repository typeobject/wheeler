package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayList;
import java.util.List;

/** Mutable run-local planner; submitted tasks are immutable. */
public final class QuantumTaskBuilder {
  private final Program program;
  private final int registerId;
  private final long basisState;
  private final List<CircuitApplication> applications = new ArrayList<>();

  public QuantumTaskBuilder(Program program, int registerId, long basisState) {
    this.program = program;
    this.registerId = registerId;
    this.basisState = basisState;
  }

  public void apply(int circuitId, boolean inverse) {
    if (program.quantumCircuit(circuitId).registerId() != registerId) {
      throw new QuantumExecutionException("Circuit and prepared register do not match");
    }
    applications.add(new CircuitApplication(circuitId, inverse));
  }

  public QuantumTask build(int shots, long seed) {
    return new QuantumTask(program, registerId, basisState, List.copyOf(applications), shots, seed);
  }
}
