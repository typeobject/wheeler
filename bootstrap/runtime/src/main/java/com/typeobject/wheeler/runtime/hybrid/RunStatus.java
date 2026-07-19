package com.typeobject.wheeler.runtime.hybrid;

/** Durable semantic state of a hybrid run. */
public enum RunStatus {
  ACTIVE,
  WAITING,
  COMPLETED,
  CANCELLED,
  TRAPPED
}
