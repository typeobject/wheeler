package com.typeobject.wheeler.core.vm;

import com.typeobject.wheeler.core.bytecode.Instruction;
import com.typeobject.wheeler.core.bytecode.InstructionForm.OperandRole;

/** Restores scalar data changed by one reversible VM transition. */
final class VmDataRewinder {
  private VmDataRewinder() {}

  /** Restores globals and returns the frame with any changed local restored. */
  static Frame undo(StepRecord record, long[] globals, Frame frame) {
    Instruction instruction = record.instruction();
    switch (instruction.opcode()) {
      case ADD_CONST -> {
        int index = globalIndex(globals, instruction, OperandRole.GLOBAL);
        globals[index] = Math.subtractExact(
            globals[index], instruction.operand(OperandRole.IMMEDIATE));
      }
      case SUB_CONST -> {
        int index = globalIndex(globals, instruction, OperandRole.GLOBAL);
        globals[index] = Math.addExact(
            globals[index], instruction.operand(OperandRole.IMMEDIATE));
      }
      case XOR_CONST -> globals[globalIndex(globals, instruction, OperandRole.GLOBAL)] ^=
          instruction.operand(OperandRole.IMMEDIATE);
      case SWAP -> {
        int left = globalIndex(globals, instruction, OperandRole.LEFT_GLOBAL);
        int right = globalIndex(globals, instruction, OperandRole.RIGHT_GLOBAL);
        long value = globals[left];
        globals[left] = globals[right];
        globals[right] = value;
      }
      case SET_LOGGED, LOCAL_STORE_GLOBAL ->
          globals[record.changedGlobal()] = record.previousValue();
      case NOP, HALT, RETURN, RETURN_VALUE, CALL, UNCALL, CALL_VALUE, CALL_VOID,
          CALL_RESULT_SLOT, UNCALL_RESULT_SLOT, RESULT_FILL_CONSTANT, RESULT_FILL_SOURCE,
          RESULT_FILL_BINARY, RETURN_RESULT_SLOT,
          OUTPUT_LENGTH,
          EXPECT_EQ, EXPECT_TRUE, CHECKPOINT, COMMIT,
          LOCAL_CONST, LOCAL_LOAD_GLOBAL, LOCAL_MOVE, LOCAL_ADD, LOCAL_SUB,
          LOCAL_MUL, LOCAL_DIV, LOCAL_MOD, LOCAL_AND, LOCAL_ROTR32, LOCAL_XOR, LOCAL_EQ, LOCAL_LT,
          JUMP, JUMP_IF_ZERO, LOCAL_LOOP_CHECK,
          RECORD_NEW, RECORD_GET -> {
        // These instructions alter only control or status state.
      }
    }
    Frame restored = frame;
    if (record.changedLocal() != StepRecord.NO_LOCAL) {
      restored = restored.withLocal(record.changedLocal(), record.previousLocalValue());
    }
    if (record.changedSecondaryLocal() != StepRecord.NO_LOCAL) {
      restored = restored.withLocal(
          record.changedSecondaryLocal(), record.previousSecondaryLocalValue());
    }
    return restored;
  }

  private static int globalIndex(
      long[] globals, Instruction instruction, OperandRole role) {
    return VmControlChecks.globalIndex(
        globals.length, Math.toIntExact(instruction.operand(role)));
  }
}
