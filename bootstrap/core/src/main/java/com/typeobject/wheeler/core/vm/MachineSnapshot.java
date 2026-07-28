package com.typeobject.wheeler.core.vm;

import java.util.List;
import java.util.Map;

/** Immutable public projection of machine state for tests, tools, and debugging. */
public record MachineSnapshot(
    TaskId selectedTask,
    long workflowEpoch,
    MachineStatus status,
    Map<TaskId, List<Frame>> taskFrames,
    Map<String, Long> globals,
    List<RecordValue> records,
    List<VariantValue> variants,
    List<ArrayValue> arrays,
    List<SliceValue> slices,
    List<RegionValue> regions,
    List<BufferValue> buffers,
    int hostOutputLength,
    int historyRecords,
    long sequence) {
  /** Returns the immutable frame stack for the selected semantic task. */
  public List<Frame> selectedFrames() {
    List<Frame> selected = taskFrames.get(selectedTask);
    if (selected == null) {
      throw new IllegalStateException("Snapshot omits its selected task");
    }
    return selected;
  }
}
