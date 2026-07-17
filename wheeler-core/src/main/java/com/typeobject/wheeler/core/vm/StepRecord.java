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
    long previousValue) {
  public static final int NO_GLOBAL = -1;

  public StepRecord {
    Objects.requireNonNull(instruction, "instruction");
    Objects.requireNonNull(previousStatus, "previousStatus");
    Objects.requireNonNull(controlChange, "controlChange");
    Objects.requireNonNull(previousFrame, "previousFrame");
  }

  public enum ControlChange {
    ADVANCE,
    CALL,
    RETURN
  }
}
