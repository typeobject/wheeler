//! Encodes signed ordering operands once in left-to-right source order.

module wheeler.compiler.signed_ordering_encoding;

import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.signed_ordering_kinds;

classical class SignedOrderingEncoding {
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;
  private const long ORDERING_CODE_BYTES = 96;

  private long writeOperand(
    borrow mut bytes output,
    long cursor,
    long local,
    long kind,
    long value
  ) {
    long load = OPCODE_LOCAL_CONST;
    if (kind == ASSERTION_LOCAL) {
      load = OPCODE_LOCAL_MOVE;
    }

    if (kind == ASSERTION_GLOBAL) {
      load = OPCODE_LOCAL_LOAD_GLOBAL;
    }

    cursor = writeInstructionHeader(output, cursor, load, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, local, U64);
    return writeSignedLittleEndian(output, cursor, value, U64);
  }

  private boolean operandBeforeTemporaries(long kind, long value, long localBase) {
    if (signedOrderingValueValid(kind, value)) {} else {
      return false;
    }

    if (kind == ASSERTION_LOCAL) {
      return value < localBase;
    }

    return true;
  }

  /// Validates both operands, three frame slots, and the complete output window before writes.
  public long writeSignedOrderingAssertion(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long left,
    long right,
    long localBase
  ) {
    if (cursor < 0) {
      return -1;
    }

    if (bufferLength(output) - cursor < ORDERING_CODE_BYTES) {
      return -1;
    }

    if (signedOrderingValueValid(ASSERTION_LOCAL, localBase)) {} else {
      return -1;
    }

    if (signedOrderingValueValid(ASSERTION_LOCAL, localBase + 2)) {} else {
      return -1;
    }

    long leftKind = signedOrderingLeftKind(opcode);
    long rightKind = signedOrderingRightKind(opcode);
    if (operandBeforeTemporaries(leftKind, left, localBase)) {} else {
      return -1;
    }

    if (operandBeforeTemporaries(rightKind, right, localBase)) {} else {
      return -1;
    }

    cursor = writeOperand(output, cursor, localBase, leftKind, left);
    cursor = writeOperand(output, cursor, localBase + 1, rightKind, right);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LT, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_EXPECT_TRUE, INSTRUCTION_FORM_UNARY);
    return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
  }
}
