package com.typeobject.wheeler.core.vm;

import java.util.NavigableSet;

/** Deterministic canonical task selector with verifier-visible cursor state. */
final class TaskScheduler {
  private TaskId cursor = TaskId.ROOT;

  TaskId cursor() {
    return cursor;
  }

  TaskId next(NavigableSet<TaskId> runnable) {
    if (runnable.isEmpty()) {
      throw new VmTrap("Task machine has no runnable task");
    }
    TaskId selected = runnable.higher(cursor);
    if (selected == null) {
      selected = runnable.first();
    }
    return selected;
  }

  void commit(TaskId selected) {
    if (selected == null) {
      throw new IllegalArgumentException("Selected task is required");
    }
    cursor = selected;
  }

  void restore(TaskId previousCursor) {
    if (previousCursor == null) {
      throw new IllegalArgumentException("Scheduler cursor is required");
    }
    cursor = previousCursor;
  }
}
