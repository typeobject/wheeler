package com.typeobject.wheeler.runtime.hybrid;

import java.util.List;
import java.util.Objects;

/** Complete bounded semantic checkpoint for persistence or replay. */
public record HybridRunSnapshot(
    int schemaVersion,
    String artifactId,
    String runId,
    RunMode mode,
    RunStatus status,
    String activeBranch,
    long commitHorizon,
    HybridRunLimits limits,
    HybridContinuation continuation,
    List<HybridEvent> events) {
  public static final int SCHEMA_VERSION = 1;

  public HybridRunSnapshot {
    if (schemaVersion != SCHEMA_VERSION) {
      throw new IllegalArgumentException("Unsupported hybrid snapshot schema " + schemaVersion);
    }
    Objects.requireNonNull(artifactId, "artifactId");
    Objects.requireNonNull(runId, "runId");
    Objects.requireNonNull(mode, "mode");
    Objects.requireNonNull(status, "status");
    Objects.requireNonNull(activeBranch, "activeBranch");
    Objects.requireNonNull(limits, "limits");
    Objects.requireNonNull(continuation, "continuation");
    events = List.copyOf(events);
    if (events.size() > limits.maxEvents() || commitHorizon < -1) {
      throw new IllegalArgumentException("Hybrid snapshot exceeds declared limits");
    }
    if (!artifactId.equals(continuation.artifactId())
        || !runId.equals(continuation.runId())
        || !activeBranch.equals(continuation.branchId())) {
      throw new IllegalArgumentException("Continuation identity does not match snapshot");
    }
  }
}
