package com.typeobject.wheeler.core.vm;

/** Lifecycle state of one semantic task in the deterministic task table. */
public enum TaskStatus {
  CREATED,
  RUNNABLE,
  RUNNING,
  BLOCKED_ON_JOIN,
  COMPLETED,
  JOINED,
  FAILED
}
