//! Encodes direct loop-body operations whose indexes require one checked sum.

module wheeler.compiler.closure.loop_offset_instruction_encoding;

import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.storage_opcodes;

classical class LoopOffsetInstructionEncoding {
  private const long LITERAL_INDEX_OFFSET_SCALE = 131072;
  private const long OFFSET_COPY_READ_BORROW_SCALE = 2199023255552;
  private const long OFFSET_COPY_WRITE_BORROW_SCALE = 1099511627776;
  private const long OFFSET_COPY_WRITE_OWNER_SCALE = 4294967296;
  private const long OFFSET_COPY_WRITE_INDEX_SCALE = 16777216;
  private const long OFFSET_COPY_READ_OWNER_SCALE = 65536;
  private const long OFFSET_COPY_READ_BASE_SCALE = 256;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports whether one closed body opcode belongs to this encoder.
  public boolean offsetBodyOpcode(long opcode) {
    if (opcode == BODY_WORDS_GET_OFFSET) {
      return true;
    }

    return opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM;
  }

  /// Reports the exact instruction count for one checked-index operation.
  public long offsetBodyInstructionCount(long opcode, long operand) {
    if (opcode == BODY_WORDS_GET_OFFSET) {
      return 5 + operand % LITERAL_INDEX_OFFSET_SCALE / 65536;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
      long readBorrowed = operand / OFFSET_COPY_READ_BORROW_SCALE;
      long writeBorrowed = operand / OFFSET_COPY_WRITE_BORROW_SCALE % 2;
      return 6 + readBorrowed + writeBorrowed;
    }

    return -1;
  }

  /// Reports the exact encoded byte length for one checked-index operation.
  public long offsetBodyInstructionLength(long opcode, long operand) {
    if (opcode == BODY_WORDS_GET_OFFSET) {
      long borrowed = operand % LITERAL_INDEX_OFFSET_SCALE / 65536;
      return 136 + borrowed * 24;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
      long readBorrowed = operand / OFFSET_COPY_READ_BORROW_SCALE;
      long writeBorrowed = operand / OFFSET_COPY_WRITE_BORROW_SCALE % 2;
      return 168 + (readBorrowed + writeBorrowed) * 24;
    }

    return -1;
  }

  /// Reports the exact local suffix width for one checked-index operation.
  public long offsetBodyLocalCount(long opcode, long operand) {
    if (opcode == BODY_WORDS_GET_OFFSET) {
      return 5 + operand % LITERAL_INDEX_OFFSET_SCALE / 65536;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
      long readBorrowed = operand / OFFSET_COPY_READ_BORROW_SCALE;
      long writeBorrowed = operand / OFFSET_COPY_WRITE_BORROW_SCALE % 2;
      return 5 + readBorrowed + writeBorrowed;
    }

    return -1;
  }

  private long writeLiteralWordRead(
    borrow mut bytes output,
    long cursor,
    long localBase,
    long operand
  ) {
    long literal = operand / LITERAL_INDEX_OFFSET_SCALE;
    long packed = operand % LITERAL_INDEX_OFFSET_SCALE;
    long borrowedOwner = packed / 65536;
    long pair = packed % 65536;
    long owner = pair / 256;
    long index = pair % 256;
    long nextLocal = localBase;
    long ownerOperand = owner;
    if (0 < borrowedOwner) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, owner, U64);
      ownerOperand = nextLocal;
      nextLocal += 1;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeSignedLittleEndian(output, cursor, literal, U64);
    long literalLocal = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, index, U64);
    long indexLocal = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_ADD, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, literalLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, indexLocal, U64);
    long sumLocal = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_WORDS_GET, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, ownerOperand, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, sumLocal, U64);
    long result = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    return writeUnsignedLittleEndian(output, cursor, result, U64);
  }

  private long writeByteViewCopy(
    borrow mut bytes output,
    long cursor,
    long localBase,
    long operand
  ) {
    long readBorrowed = operand / OFFSET_COPY_READ_BORROW_SCALE;
    long writeBorrowed = operand / OFFSET_COPY_WRITE_BORROW_SCALE % 2;
    long tuple = operand % OFFSET_COPY_WRITE_BORROW_SCALE;
    long writeOwner = tuple / OFFSET_COPY_WRITE_OWNER_SCALE;
    long writeIndex = tuple / OFFSET_COPY_WRITE_INDEX_SCALE % 256;
    long readOwner = tuple / OFFSET_COPY_READ_OWNER_SCALE % 256;
    long readBase = tuple / OFFSET_COPY_READ_BASE_SCALE % 256;
    long readIndex = tuple % 256;
    long nextLocal = localBase;
    long writeOwnerOperand = writeOwner;
    if (0 < writeBorrowed) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeOwner, U64);
      writeOwnerOperand = nextLocal;
      nextLocal += 1;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, writeIndex, U64);
    long writeIndexOperand = nextLocal;
    nextLocal += 1;
    long readOwnerOperand = readOwner;
    if (0 < readBorrowed) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, readOwner, U64);
      readOwnerOperand = nextLocal;
      nextLocal += 1;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, readBase, U64);
    long readBaseOperand = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, readIndex, U64);
    long readIndexOperand = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_ADD, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, readBaseOperand, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, readIndexOperand, U64);
    long readSumOperand = nextLocal;
    nextLocal += 1;
    cursor = writeInstructionHeader(output, cursor, OPCODE_BYTES_GET, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, nextLocal, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, readOwnerOperand, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, readSumOperand, U64);
    long result = nextLocal;
    cursor = writeInstructionHeader(output, cursor, OPCODE_BYTES_SET, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, writeOwnerOperand, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, writeIndexOperand, U64);
    return writeUnsignedLittleEndian(output, cursor, result, U64);
  }

  /// Emits one checked-index operation into private caller-owned code storage.
  public long writeOffsetBodyInstruction(
    borrow mut bytes output,
    long cursor,
    long localBase,
    long opcode,
    long operand
  ) {
    if (opcode == BODY_WORDS_GET_OFFSET) {
      return writeLiteralWordRead(output, cursor, localBase, operand);
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
      return writeByteViewCopy(output, cursor, localBase, operand);
    }

    return -1;
  }
}
