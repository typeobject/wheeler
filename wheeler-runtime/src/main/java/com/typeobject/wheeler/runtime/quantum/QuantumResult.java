package com.typeobject.wheeler.runtime.quantum;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Objects;

/** Canonical little-endian full-register sampling result with submission provenance. */
public record QuantumResult(
    String jobId,
    String taskIdentity,
    List<Long> outcomes,
    Map<Long, Long> counts,
    String target) {
  public QuantumResult {
    Objects.requireNonNull(jobId, "jobId");
    Objects.requireNonNull(taskIdentity, "taskIdentity");
    Objects.requireNonNull(target, "target");
    outcomes = List.copyOf(outcomes);
    counts = Map.copyOf(new LinkedHashMap<>(counts));
    if (jobId.isBlank() || taskIdentity.isBlank() || target.isBlank() || outcomes.isEmpty()) {
      throw new IllegalArgumentException("Quantum result identity and outcomes are required");
    }
    Map<Long, Long> expected = new LinkedHashMap<>();
    outcomes.forEach(value -> expected.merge(value, 1L, Long::sum));
    if (!expected.equals(counts)) {
      throw new IllegalArgumentException("Quantum result counts do not match outcomes");
    }
  }

  public long firstOutcome() {
    return outcomes.getFirst();
  }

  /** Estimate a tensor product of Pauli-Z observables from little-endian samples. */
  public ExpectationEstimate zExpectation(List<Integer> qubits) {
    List<Integer> selected = List.copyOf(qubits);
    long mask = 0;
    for (int qubit : selected) {
      if (qubit < 0 || qubit >= Long.SIZE - 1 || (mask & (1L << qubit)) != 0) {
        throw new IllegalArgumentException("Invalid or repeated expectation qubit " + qubit);
      }
      mask |= 1L << qubit;
    }
    if (selected.isEmpty()) {
      throw new IllegalArgumentException("Expectation requires at least one qubit");
    }
    double sum = 0;
    for (long outcome : outcomes) {
      sum += (Long.bitCount(outcome & mask) & 1) == 0 ? 1 : -1;
    }
    double mean = sum / outcomes.size();
    double standardError = Math.sqrt(Math.max(0, 1 - mean * mean) / outcomes.size());
    return new ExpectationEstimate(mean, standardError, outcomes.size());
  }

  public ExpectationEstimate zExpectation(int qubit) {
    return zExpectation(List.of(qubit));
  }
}
