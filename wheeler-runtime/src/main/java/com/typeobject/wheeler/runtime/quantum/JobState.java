package com.typeobject.wheeler.runtime.quantum;

/** Provider-neutral lifecycle state of one bounded quantum job. */
public enum JobState {
  QUEUED,
  RUNNING,
  SUCCEEDED,
  FAILED,
  CANCEL_REQUESTED,
  CANCELLED
}
