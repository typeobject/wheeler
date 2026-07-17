package com.typeobject.wheeler.runtime.quantum;

import java.time.Duration;
import java.util.Objects;

final class CompletedQuantumJob implements QuantumJob {
  private final QuantumResult result;

  CompletedQuantumJob(QuantumResult result) {
    this.result = Objects.requireNonNull(result, "result");
  }

  @Override
  public String id() {
    return result.jobId();
  }

  @Override
  public JobState state() {
    return JobState.SUCCEEDED;
  }

  @Override
  public boolean cancel() {
    return false;
  }

  @Override
  public QuantumResult await(Duration timeout) {
    if (timeout.isNegative()) {
      throw new IllegalArgumentException("Timeout must not be negative");
    }
    return result;
  }
}
