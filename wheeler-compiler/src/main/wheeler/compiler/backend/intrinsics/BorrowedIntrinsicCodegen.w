//! Encodes bounded reads through primitive borrowed buffers.

module wheeler.compiler.borrowed_intrinsic_codegen;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.storage_opcodes;

classical class BorrowedIntrinsicCodegen {
  private const long FORM_UNARY = INSTRUCTION_FORM_UNARY;
  private const long FORM_BINARY = INSTRUCTION_FORM_BINARY;
  private const long FORM_TERNARY = INSTRUCTION_FORM_TERNARY;
  private const long U64 = INSTRUCTION_OPERAND_WIDTH;

  private long writeBufferLength(
    borrow mut bytes output,
    long cursor,
    long operand,
    long localBase
  ) {
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_BUFFER_LENGTH, FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase, U64);
  }

  /// Writes one borrowed intrinsic statement, or reports that it owns no opcode.
  public long writeBorrowedIntrinsicStatement(
    borrow mut bytes output,
    long cursor,
    long opcode,
    long operand,
    long secondaryOperand,
    long localBase
  ) {
    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_UTF8_SCALAR, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      cursor = writeBufferLength(output, cursor, operand, localBase);
      cursor = writeInstructionHeader(output, cursor, OPCODE_RETURN_VALUE, FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH) {
      cursor = writeBufferLength(output, cursor, operand, localBase);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    }

    return -1;
  }
}
