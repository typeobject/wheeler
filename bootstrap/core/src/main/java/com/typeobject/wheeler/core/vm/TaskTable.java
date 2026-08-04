package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.NavigableSet;
import java.util.TreeMap;
import java.util.TreeSet;

/** Bounded canonical owner of semantic tasks and their frame stacks. */
final class TaskTable {
  private static final NavigableSet<TaskId> ROOT_RUNNABLE =
      Collections.unmodifiableNavigableSet(new TreeSet<>(List.of(TaskId.ROOT)));
  private static final NavigableSet<TaskId> NO_RUNNABLE_TASKS =
      Collections.emptyNavigableSet();

  private final TreeMap<TaskId, ArrayList<Frame>> frames = new TreeMap<>();
  private final TreeMap<TaskId, TaskStatus> statuses = new TreeMap<>();
  private TaskId selected = TaskId.ROOT;

  TaskTable(Frame rootFrame) {
    frames.put(TaskId.ROOT, new ArrayList<>(List.of(rootFrame)));
    statuses.put(TaskId.ROOT, TaskStatus.RUNNABLE);
  }

  TaskId selected() {
    return selected;
  }

  NavigableSet<TaskId> runnableTaskIds() {
    return statuses.get(TaskId.ROOT) == TaskStatus.RUNNABLE
        ? ROOT_RUNNABLE
        : NO_RUNNABLE_TASKS;
  }

  void select(TaskId taskId) {
    if (!frames.containsKey(taskId)) {
      throw new VmTrap("Scheduler selected an unknown task: " + taskId.canonicalName());
    }
    selected = taskId;
  }

  TaskStatus selectedStatus() {
    TaskStatus status = statuses.get(selected);
    if (status == null) {
      throw new VmTrap("Selected task has no status: " + selected.canonicalName());
    }
    return status;
  }

  void setSelectedStatus(TaskStatus status) {
    if (status == null) {
      throw new IllegalArgumentException("Task status is required");
    }
    statuses.put(selected, status);
  }

  int frameDepth() {
    return selectedFrames().size();
  }

  boolean frameStackEmpty() {
    return selectedFrames().isEmpty();
  }

  Frame currentFrame() {
    return selectedFrames().getLast();
  }

  void addFrame(Frame frame) {
    selectedFrames().add(frame);
  }

  Frame removeLastFrame() {
    return selectedFrames().removeLast();
  }

  void replaceCurrentFrame(Frame frame) {
    ArrayList<Frame> stack = selectedFrames();
    stack.set(stack.size() - 1, frame);
  }

  Map<TaskId, List<Frame>> snapshotFrames() {
    Map<TaskId, List<Frame>> snapshot = new LinkedHashMap<>();
    frames.forEach((task, stack) -> snapshot.put(task, List.copyOf(stack)));
    return Collections.unmodifiableMap(snapshot);
  }

  Map<TaskId, TaskStatus> snapshotStatuses() {
    return Collections.unmodifiableMap(new LinkedHashMap<>(statuses));
  }

  private ArrayList<Frame> selectedFrames() {
    ArrayList<Frame> stack = frames.get(selected);
    if (stack == null) {
      throw new VmTrap("Selected task has no frame stack: " + selected.canonicalName());
    }
    return stack;
  }
}
