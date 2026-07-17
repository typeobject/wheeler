package com.typeobject.wheeler.runtime.quantum;

public enum JobState {
  QUEUED,
  RUNNING,
  SUCCEEDED,
  FAILED,
  CANCEL_REQUESTED,
  CANCELLED
}
