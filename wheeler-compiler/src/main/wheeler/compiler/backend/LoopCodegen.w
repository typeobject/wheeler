//! Emits canonical bytecode for bounded local loops.

module wheeler.compiler.loop_codegen;

import wheeler.compiler.encoding;
import wheeler.compiler.loop_kinds;
import wheeler.compiler.opcodes;
import wheeler.compiler.scalar_opcodes;
import wheeler.compiler.statement_kinds;

classical class LoopCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  /// Emits one resolved signed-local while loop.
  public long writeLocalWhile(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase,
    long instructionBase
  ) {
    long target = resolvedLocalWhileTarget(opcode);
    long limitOpcode = OPCODE_LOCAL_CONST;
    if (resolvedLocalWhileLimitNamed(opcode)) {
      limitOpcode = OPCODE_LOCAL_MOVE;
    }

    cursor = writeInstructionHeader(output, cursor, limitOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeLoopOperand(output, cursor, limitOpcode, secondaryOperand);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 0, U64);

    long leftOpcode = OPCODE_LOCAL_MOVE;
    long leftOperand = target;
    long conditionOpcode = OPCODE_LOCAL_CONST;
    long conditionOperand = operand;
    if (resolvedLocalWhileConditionNamed(opcode)) {
      conditionOpcode = OPCODE_LOCAL_MOVE;
    }

    if (resolvedLocalWhileReversed(opcode)) {
      leftOpcode = OPCODE_LOCAL_CONST;
      leftOperand = operand;
      conditionOpcode = OPCODE_LOCAL_MOVE;
      conditionOperand = target;
    }

    cursor = writeInstructionHeader(output, cursor, leftOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeLoopOperand(output, cursor, leftOpcode, leftOperand);
    cursor = writeInstructionHeader(output, cursor, conditionOpcode, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeLoopOperand(output, cursor, conditionOpcode, conditionOperand);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LT, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP_IF_ZERO, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 10, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LOOP_CHECK, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeSignedLittleEndian(output, cursor, /* value= */ 1, U64);

    long updateOpcode = OPCODE_LOCAL_ADD;
    if (resolvedLocalWhileUpdateForm(opcode) == STATEMENT_LOCAL_WHILE_SUB_FORM) {
      updateOpcode = OPCODE_LOCAL_SUB;
    }

    if (resolvedLocalWhileUpdateForm(opcode) == STATEMENT_LOCAL_WHILE_XOR_FORM) {
      updateOpcode = OPCODE_LOCAL_XOR;
    }

    cursor = writeInstructionHeader(output, cursor, updateOpcode, FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 5, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, instructionBase + 2, U64);
  }

  private long writeLoopOperand(borrow mut bytes output, long cursor, long opcode, long operand) {
    if (opcode == OPCODE_LOCAL_CONST) {
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    return writeUnsignedLittleEndian(output, cursor, operand, U64);
  }
}
