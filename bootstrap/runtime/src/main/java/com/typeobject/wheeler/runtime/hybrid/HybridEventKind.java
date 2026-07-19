package com.typeobject.wheeler.runtime.hybrid;

/** Stable version-1 hybrid event vocabulary. */
public enum HybridEventKind {
  RUN_STARTED,
  TARGET_SELECTED,
  TRANSACTION_STARTED,
  TRANSACTION_ABORTED,
  QUANTUM_SUBMITTED,
  QUANTUM_APPLIED,
  CANCELLATION_REQUESTED,
  BRANCH_RETRIED,
  BRANCH_DISCARDED,
  COMMITTED,
  RUN_COMPLETED,
  RUN_TRAPPED
}
