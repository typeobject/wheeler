package com.typeobject.wheeler.core.vm;

import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.INDEX;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.OWNER;
import static com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole.TARGET;

import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.Program;

/** Focused bounds checks for VM control-flow and global-address operands. */
final class VmControlChecks {
  private VmControlChecks() {}

  /** Validates one instruction-index jump against the active function direction. */
  static int jumpTarget(
      Program program, Frame frame, Instruction instruction) {
    int target = Math.toIntExact(instruction.operand(TARGET));
    int bodySize = program.function(frame.functionId()).body(frame.inverse()).size();
    if (target < 0 || target >= bodySize) {
      throw new VmTrap("Invalid jump target " + target);
    }
    return target;
  }

  /** Requires one signed global to equal its assertion operand. */
  static void requireGlobalEqual(
      Program program, long[] globals, int global, long expected) {
    if (globals[global] != expected) {
      throw new VmTrap(VmTrap.Code.ASSERTION,
          "Expectation failed for %s: expected %d, got %d"
          .formatted(program.globals().get(global).name(), expected, globals[global]));
    }
  }

  /** Requires one canonical Boolean local to hold true. */
  static void requireTrue(Program program, Frame frame, int local) {
    long actual = frame.local(local);
    if (actual != 1) {
      throw new VmTrap(
          VmTrap.Code.ASSERTION,
          "Assertion failed in %s at instruction %d for local %d: expected 1, got %d"
              .formatted(
                  program.function(frame.functionId()).name(),
                  frame.programCounter(),
                  local,
                  actual));
    }
  }

  /** Decodes one UTF-8 scalar using checked local handles from the active frame. */
  static Utf8.Scalar utf8Scalar(
      OwnedStore owned, Frame frame, Instruction instruction) {
    long buffer = frame.local(Math.toIntExact(instruction.operand(OWNER)));
    long index = frame.local(Math.toIntExact(instruction.operand(INDEX)));
    return Utf8.decode(owned.utf8Bytes(buffer), Math.toIntExact(index));
  }

  /** Validates one global index without exposing the VM's mutable global array. */
  static int globalIndex(int globalCount, int index) {
    if (index < 0 || index >= globalCount) {
      throw new VmTrap("Invalid global index " + index);
    }
    return index;
  }
}
