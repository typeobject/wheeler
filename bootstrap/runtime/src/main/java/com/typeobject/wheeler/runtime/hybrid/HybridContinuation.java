package com.typeobject.wheeler.runtime.hybrid;

import java.util.Map;
import java.util.Objects;
import java.util.TreeMap;

/** Bounded typed state needed to validate a recovered workflow edge. */
public record HybridContinuation(
    String artifactId,
    String runId,
    String branchId,
    int workflowIndex,
    Map<String, Long> globals,
    String pendingJobId,
    String pendingTarget,
    TransactionPhase transactionPhase,
    int transactionWorkflowIndex,
    int transactionObservationCount,
    Map<String, Long> transactionGlobals) {
  public HybridContinuation {
    Objects.requireNonNull(artifactId, "artifactId");
    Objects.requireNonNull(runId, "runId");
    Objects.requireNonNull(branchId, "branchId");
    Objects.requireNonNull(pendingJobId, "pendingJobId");
    Objects.requireNonNull(pendingTarget, "pendingTarget");
    transactionPhase = Objects.requireNonNull(transactionPhase, "transactionPhase");
    globals = ordered(globals, "globals");
    transactionGlobals = ordered(transactionGlobals, "transactionGlobals");
    if (workflowIndex < 0 || transactionWorkflowIndex < -1 || transactionObservationCount < 0) {
      throw new IllegalArgumentException("Invalid continuation position");
    }
    if (transactionPhase == TransactionPhase.NONE
        && (transactionWorkflowIndex != -1
            || transactionObservationCount != 0
            || !transactionGlobals.isEmpty())) {
      throw new IllegalArgumentException("Inactive transaction carries a checkpoint");
    }
    if (transactionPhase != TransactionPhase.NONE
        && (transactionWorkflowIndex < 0 || transactionGlobals.isEmpty())) {
      throw new IllegalArgumentException("Active transaction lacks a checkpoint");
    }
  }

  public boolean waiting() {
    return !pendingJobId.isEmpty();
  }

  private static Map<String, Long> ordered(Map<String, Long> values, String name) {
    Objects.requireNonNull(values, name);
    if (values.size() > 65_535) {
      throw new IllegalArgumentException(name + " exceeds global limit");
    }
    TreeMap<String, Long> result = new TreeMap<>();
    values.forEach((key, value) -> result.put(
        Objects.requireNonNull(key, "global name"), Objects.requireNonNull(value, "global value")));
    return Map.copyOf(result);
  }
}
