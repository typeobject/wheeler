package com.typeobject.wheeler.runtime.quantum;

import com.typeobject.wheeler.core.quantum.ConditionalGateOperation;
import com.typeobject.wheeler.core.quantum.MeasureOperation;
import com.typeobject.wheeler.core.quantum.PrepareOperation;
import com.typeobject.wheeler.core.quantum.QuantumCircuit;
import com.typeobject.wheeler.core.quantum.QuantumRegister;
import com.typeobject.wheeler.core.quantum.ResetOperation;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicLong;

/** Asynchronous target for the bounded canonical target-resident dynamic profile. */
public final class DynamicStateVectorTarget implements QuantumTarget {
  private static final AtomicLong JOB_SEQUENCE = new AtomicLong();

  private final DynamicStateVectorSimulator simulator = new DynamicStateVectorSimulator();
  private final ConcurrentMap<String, StoredJob> jobs = new ConcurrentHashMap<>();

  @Override
  public TargetDescriptor descriptor() {
    return simulator.descriptor();
  }

  @Override
  public QuantumJob submit(QuantumSubmission submission) {
    descriptor().require(submission.requiredCapabilities());
    QuantumRegister register = submission.program().quantumRegister(submission.registerId());
    if (register.qubits() > descriptor().maxQubits()) {
      throw new QuantumExecutionException("Submission exceeds dynamic target qubit limit");
    }
    if (submission.shots() > descriptor().maxShots()) {
      throw new QuantumExecutionException("Submission exceeds dynamic target shot limit");
    }
    if (submission.applications().size() != 1) {
      throw new QuantumExecutionException(
          "Dynamic target submissions require exactly one semantic region");
    }

    CircuitApplication application = submission.applications().getFirst();
    QuantumCircuit circuit = submission.program().quantumCircuit(application.circuitId());
    boolean dynamic = circuit.operations().stream().anyMatch(
        operation -> operation instanceof PrepareOperation
            || operation instanceof MeasureOperation
            || operation instanceof ResetOperation
            || operation instanceof ConditionalGateOperation);
    if (dynamic && application.inverse()) {
      throw new QuantumExecutionException("Target-resident dynamic regions have no inverse");
    }
    List<Long> outcomes = new ArrayList<>(submission.shots());
    Map<Long, Long> counts = new LinkedHashMap<>();
    for (int shot = 0; shot < submission.shots(); shot++) {
      long seed = Math.addExact(submission.seed(), shot);
      long outcome = dynamic
          ? simulator.execute(submission.program(), circuit, seed).basisState()
          : executeStatic(submission, circuit, application.inverse(), register, seed);
      outcomes.add(outcome);
      counts.merge(outcome, 1L, Long::sum);
    }

    String id = "dynamic-state-vector-" + JOB_SEQUENCE.incrementAndGet();
    QuantumJob job = new CompletedQuantumJob(new QuantumResult(
        id, submission.identity(), outcomes, counts, descriptor().target()));
    jobs.put(id, new StoredJob(submission.identity(), job));
    return job;
  }

  @Override
  public QuantumJob recover(String jobId, QuantumSubmission submission) {
    StoredJob stored = jobs.get(jobId);
    if (stored == null || !stored.submissionIdentity().equals(submission.identity())) {
      throw new QuantumExecutionException("Unknown or mismatched dynamic state-vector job " + jobId);
    }
    return stored.job();
  }

  private static long executeStatic(
      QuantumSubmission submission,
      QuantumCircuit circuit,
      boolean inverse,
      QuantumRegister register,
      long seed) {
    StateVectorEngine engine = new StateVectorEngine(seed);
    engine.prepare(register, submission.basisState());
    engine.apply(submission.program(), circuit, inverse, submission.bindings());
    return engine.measure(register);
  }

  private record StoredJob(String submissionIdentity, QuantumJob job) {}
}
