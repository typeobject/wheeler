package com.typeobject.wheeler.core.vm;

import java.util.List;
import java.util.Map;

/** Immutable public projection of machine state for tests, tools, and debugging. */
public record MachineSnapshot(
    MachineStatus status,
    List<Frame> frames,
    Map<String, Long> globals,
    List<RecordValue> records,
    int historyRecords,
    long sequence) {}
