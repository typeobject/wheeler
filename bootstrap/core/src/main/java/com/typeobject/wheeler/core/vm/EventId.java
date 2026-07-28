package com.typeobject.wheeler.core.vm;

import java.util.Objects;

/** Stable semantic origin for one task-machine event. */
public record EventId(long workflowEpoch, TaskId taskId, long taskLocalSequence) {
  public EventId {
    Objects.requireNonNull(taskId, "taskId");
    if (workflowEpoch < 0 || taskLocalSequence < 0) {
      throw new IllegalArgumentException("EventId fields cannot be negative");
    }
  }

  /** Returns an event identity for the current single-task compatibility machine. */
  public static EventId root(long taskLocalSequence) {
    return new EventId(0, TaskId.ROOT, taskLocalSequence);
  }
}
