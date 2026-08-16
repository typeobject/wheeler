package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.NavigableSet;
import java.util.TreeSet;

/** Canonical owner of the root task and its bounded frame stack. */
final class TaskTable {
  private static final NavigableSet<TaskId> ROOT_RUNNABLE =
      Collections.unmodifiableNavigableSet(new TreeSet<>(List.of(TaskId.ROOT)));
  private static final NavigableSet<TaskId> NO_RUNNABLE_TASKS =
      Collections.emptyNavigableSet();

  private final ArrayList<Frame> frames;
  private TaskStatus status = TaskStatus.RUNNABLE;

  TaskTable(Frame rootFrame) {
    frames = new ArrayList<>(List.of(rootFrame));
  }

  TaskId selected() {
    return TaskId.ROOT;
  }

  NavigableSet<TaskId> runnableTaskIds() {
    return status == TaskStatus.RUNNABLE ? ROOT_RUNNABLE : NO_RUNNABLE_TASKS;
  }

  void select(TaskId taskId) {
    if (!TaskId.ROOT.equals(taskId)) {
      throw new VmTrap("Scheduler selected an unknown task: " + taskId.canonicalName());
    }
  }

  TaskStatus selectedStatus() {
    return status;
  }

  void setSelectedStatus(TaskStatus nextStatus) {
    if (nextStatus == null) {
      throw new IllegalArgumentException("Task status is required");
    }
    status = nextStatus;
  }

  int frameDepth() {
    return frames.size();
  }

  boolean frameStackEmpty() {
    return frames.isEmpty();
  }

  Frame currentFrame() {
    return frames.getLast();
  }

  void addFrame(Frame frame) {
    frames.add(frame);
  }

  Frame removeLastFrame() {
    return frames.removeLast();
  }

  void replaceCurrentFrame(Frame frame) {
    frames.set(frames.size() - 1, frame);
  }

  Map<TaskId, List<Frame>> snapshotFrames() {
    return Map.of(TaskId.ROOT, List.copyOf(frames));
  }

  Map<TaskId, TaskStatus> snapshotStatuses() {
    return Map.of(TaskId.ROOT, status);
  }
}
