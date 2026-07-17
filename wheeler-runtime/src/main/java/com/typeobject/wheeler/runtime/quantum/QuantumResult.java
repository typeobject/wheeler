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
}
