package com.typeobject.wheeler.runtime.quantum;

import java.util.List;
import java.util.Objects;

/** Ordered validated results for one content-identified batch. */
public record QuantumBatchResult(
    String batchJobId, String batchIdentity, List<QuantumResult> results) {
  public QuantumBatchResult {
    Objects.requireNonNull(batchJobId, "batchJobId");
    Objects.requireNonNull(batchIdentity, "batchIdentity");
    results = List.copyOf(results);
    if (batchJobId.isBlank() || batchIdentity.isBlank() || results.isEmpty()) {
      throw new IllegalArgumentException("Quantum batch result is incomplete");
    }
  }
}
