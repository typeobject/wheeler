package com.typeobject.wheeler.runtime.quantum;

import java.util.List;

/** Canonical observations from one target-resident dynamic syndrome fixture. */
public record DynamicSyndromeResult(
    boolean logicalBit,
    boolean correctedDataBit,
    List<Boolean> syndromes,
    List<Boolean> resetAncillas,
    int conditionalCorrections) {
  public DynamicSyndromeResult {
    syndromes = List.copyOf(syndromes);
    resetAncillas = List.copyOf(resetAncillas);
    if (syndromes.isEmpty()
        || syndromes.size() != resetAncillas.size()
        || conditionalCorrections < 0
        || conditionalCorrections > syndromes.size()) {
      throw new IllegalArgumentException("Invalid dynamic syndrome result");
    }
    if (resetAncillas.stream().anyMatch(Boolean::booleanValue)) {
      throw new IllegalArgumentException("Dynamic syndrome result retains a dirty ancilla");
    }
  }
}
