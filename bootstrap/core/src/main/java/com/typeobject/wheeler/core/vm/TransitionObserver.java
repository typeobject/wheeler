package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Opcode;

/** Receives immutable observations after successful execution or rewind transitions. */
@FunctionalInterface
public interface TransitionObserver {
  /** Observer that deliberately records nothing. */
  TransitionObserver NONE = observation -> {};

  /** Records one transition without receiving mutable machine state. */
  void observe(Observation observation);

  /** Creates an observation for one successful execution transition. */
  static Observation execution(long sequence, Frame frame, Instruction instruction) {
    int branchOutcome = -1;
    if (instruction.opcode() == Opcode.JUMP_IF_ZERO) {
      int condition = Math.toIntExact(instruction.operands().getFirst());
      branchOutcome = frame.local(condition) == 0 ? 1 : 0;
    }
    return new Observation(
        sequence,
        frame.inverse() ? Direction.INVERSE : Direction.FORWARD,
        frame.functionId(),
        frame.programCounter(),
        instruction.opcode(),
        branchOutcome);
  }

  /** Creates a distinct observation for rewinding one retained transition. */
  static Observation rewind(StepRecord record) {
    Frame frame = record.previousFrame();
    return new Observation(
        record.sequence(),
        frame.inverse() ? Direction.REWIND_INVERSE : Direction.REWIND_FORWARD,
        frame.functionId(),
        frame.programCounter(),
        record.instruction().opcode(),
        -1);
  }

  /** Distinguishes forward/inverse execution from rewinding either kind of transition. */
  enum Direction {
    FORWARD,
    INVERSE,
    REWIND_FORWARD,
    REWIND_INVERSE
  }

  /** One typed, instruction-addressed transition observation. */
  record Observation(
      long sequence,
      Direction direction,
      int functionId,
      int instructionIndex,
      Opcode opcode,
      int branchOutcome) {
    public Observation {
      if (sequence < 0 || functionId < 0 || instructionIndex < 0 || opcode == null
          || branchOutcome < -1 || branchOutcome > 1) {
        throw new IllegalArgumentException("Invalid transition observation");
      }
    }
  }
}
