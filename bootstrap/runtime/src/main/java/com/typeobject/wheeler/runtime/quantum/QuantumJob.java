package com.typeobject.wheeler.runtime.quantum;

import java.time.Duration;

/** Recoverable asynchronous target execution. */
public interface QuantumJob {
  String id();

  JobState state();

  boolean cancel();

  QuantumResult await(Duration timeout);
}
