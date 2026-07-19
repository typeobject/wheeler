package com.typeobject.wheeler.runtime.quantum;

import java.time.Duration;
import java.util.List;

/** One ordered asynchronous batch submission. */
public interface QuantumBatchJob {
  String id();

  String batchIdentity();

  List<QuantumJob> jobs();

  JobState state();

  boolean cancel();

  QuantumBatchResult await(Duration timeout);
}
