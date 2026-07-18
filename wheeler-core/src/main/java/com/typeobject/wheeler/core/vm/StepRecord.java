package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.Instruction;
import java.util.Objects;

/** Minimal information needed to reverse one successful VM transition. */
public record StepRecord(
    long sequence,
    Instruction instruction,
    MachineStatus previousStatus,
    ControlChange controlChange,
    Frame previousFrame,
    int changedGlobal,
    long previousValue,
    int changedLocal,
    long previousLocalValue,
    int previousRecordCount,
    int previousVariantCount,
    int previousArrayCount,
    int previousSliceCount,
    int previousRegionCount,
    int previousBufferCount,
    int changedRegion,
    RegionValue previousRegion,
    int changedBuffer,
    BufferValue previousBuffer) {
  public static final int NO_GLOBAL = -1;
  public static final int NO_LOCAL = -1;

  public StepRecord {
    Objects.requireNonNull(instruction, "instruction");
    Objects.requireNonNull(previousStatus, "previousStatus");
    Objects.requireNonNull(controlChange, "controlChange");
    Objects.requireNonNull(previousFrame, "previousFrame");
    if (previousRecordCount < 0 || previousVariantCount < 0
        || previousArrayCount < 0 || previousSliceCount < 0
        || previousRegionCount < 0 || previousBufferCount < 0
        || changedRegion < -1 || changedBuffer < -1) {
      throw new IllegalArgumentException("Invalid previous aggregate or ownership state");
    }
    if ((changedRegion >= 0) != (previousRegion != null)
        || (changedBuffer >= 0) != (previousBuffer != null)) {
      throw new IllegalArgumentException("Incomplete ownership rewind delta");
    }
  }

  public enum ControlChange {
    ADVANCE,
    CALL,
    RETURN
  }
}
