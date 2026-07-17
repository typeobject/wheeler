package com.typeobject.wheeler.runtime.quantum;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/** Canonical little-endian full-register sampling result. */
public record QuantumResult(
    String jobId,
    List<Long> outcomes,
    Map<Long, Long> counts,
    String target) {
  public QuantumResult {
    outcomes = List.copyOf(outcomes);
    counts = Map.copyOf(new LinkedHashMap<>(counts));
    if (outcomes.isEmpty()) {
      throw new IllegalArgumentException("Quantum result has no outcomes");
    }
  }

  public long firstOutcome() {
    return outcomes.getFirst();
  }
}
