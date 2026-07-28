package com.typeobject.wheeler.core.vm;

import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.TreeMap;

/** Bounded canonical owner of semantic tasks and their frame stacks. */
final class TaskTable {
  private final TreeMap<TaskId, ArrayList<Frame>> frames = new TreeMap<>();
  private TaskId selected = TaskId.ROOT;

  TaskTable(Frame rootFrame) {
    frames.put(TaskId.ROOT, new ArrayList<>(List.of(rootFrame)));
  }

  TaskId selected() {
    return selected;
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

  private ArrayList<Frame> selectedFrames() {
    ArrayList<Frame> stack = frames.get(selected);
    if (stack == null) {
      throw new VmTrap("Selected task has no frame stack: " + selected.canonicalName());
    }
    return stack;
  }
}
