//! Encodes bounded operations through primitive borrowed buffers.

module wheeler.compiler.borrowed_intrinsic_codegen;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.encoding;
import wheeler.compiler.opcodes;
import wheeler.compiler.storage_opcodes;
import wheeler.compiler.type_codes;

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
    long localBase,
    long firstSourceType
  ) {
    boolean borrowedWrite = opcode == STATEMENT_SET_WORD;
    if (opcode == STATEMENT_SET_BYTE) {
      borrowedWrite = true;
    }

    if (opcode == STATEMENT_MAP_PUT) {
      borrowedWrite = true;
    }

    if (borrowedWrite) {
      long writeIndex = secondaryOperand / INTRINSIC_LOCAL_SOURCE_COUNT;
      long writeValue = secondaryOperand % INTRINSIC_LOCAL_SOURCE_COUNT;
      long writeOpcode = OPCODE_WORDS_SET;
      if (opcode == STATEMENT_SET_BYTE) {
        writeOpcode = OPCODE_BYTES_SET;
      }

      if (opcode == STATEMENT_MAP_PUT) {
        writeOpcode = OPCODE_MAP_PUT;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeIndex, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeValue, U64);
      cursor = writeInstructionHeader(output, cursor, writeOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_GET) {
      long getOpcode = OPCODE_BYTES_GET;
      if (firstSourceType == TYPE_WORDS_BORROW) {
        getOpcode = OPCODE_WORDS_GET;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, getOpcode, FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    boolean utf8IndexedRead = opcode == STATEMENT_LOCAL_UTF8_SCALAR;
    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
      utf8IndexedRead = true;
    }

    if (utf8IndexedRead) {
      long readOpcode = OPCODE_UTF8_SCALAR;
      if (opcode == STATEMENT_LOCAL_UTF8_WIDTH) {
        readOpcode = OPCODE_UTF8_WIDTH;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, secondaryOperand, U64);
      cursor = writeInstructionHeader(output, cursor, readOpcode, FORM_TERNARY);
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
