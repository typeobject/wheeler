package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.bytecode.Program;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

/** Mutable run-local planner. Built submissions are immutable. */
public final class QuantumSubmissionBuilder {
  private final Program program;
  private final int registerId;
  private final long basisState;
  private final List<CircuitApplication> applications = new ArrayList<>();

  public QuantumSubmissionBuilder(Program program, int registerId, long basisState) {
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

  public QuantumSubmission build(int shots, long seed) {
    return build(shots, seed, Map.of());
  }

  public QuantumSubmission build(int shots, long seed, Map<String, Double> bindings) {
    return new QuantumSubmission(
        program, registerId, basisState, List.copyOf(applications), bindings, shots, seed);
  }
}
