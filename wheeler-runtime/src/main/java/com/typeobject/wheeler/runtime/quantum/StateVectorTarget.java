package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.quantum.QuantumRegister;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.atomic.AtomicLong;

/** Asynchronous target facade over the ideal bounded state-vector engine. */
public final class StateVectorTarget implements QuantumTarget {
  public static final int MAX_QUBITS = StateVectorEngine.MAX_QUBITS;
  private static final AtomicLong JOB_SEQUENCE = new AtomicLong();

  private final TargetDescriptor descriptor = new TargetDescriptor(
      "wheeler-state-vector",
      "ideal-local",
      Set.of(TargetCapability.STATIC_CIRCUIT, TargetCapability.STATE_VECTOR_DIAGNOSTICS),
      MAX_QUBITS,
      100_000);

  @Override
  public TargetDescriptor descriptor() {
    return descriptor;
  }

  @Override
  public QuantumJob submit(QuantumTask task) {
    descriptor.require(TargetCapability.STATIC_CIRCUIT);
    QuantumRegister register = task.program().quantumRegister(task.registerId());
    if (register.qubits() > descriptor.maxQubits()) {
      throw new QuantumExecutionException("Task exceeds target qubit limit");
    }
    if (task.shots() > descriptor.maxShots()) {
      throw new QuantumExecutionException("Task exceeds target shot limit");
    }

    List<Long> outcomes = new ArrayList<>(task.shots());
    Map<Long, Long> counts = new LinkedHashMap<>();
    for (int shot = 0; shot < task.shots(); shot++) {
      StateVectorEngine engine = new StateVectorEngine(task.seed() + shot);
      engine.prepare(register, task.basisState());
      for (CircuitApplication application : task.applications()) {
        engine.apply(
            task.program(),
            task.program().quantumCircuit(application.circuitId()),
            application.inverse());
      }
      long outcome = engine.measure(register);
      outcomes.add(outcome);
      counts.merge(outcome, 1L, Long::sum);
    }
    String id = "state-vector-" + JOB_SEQUENCE.incrementAndGet();
    return new CompletedQuantumJob(
        new QuantumResult(id, outcomes, counts, descriptor.target()));
  }
}
