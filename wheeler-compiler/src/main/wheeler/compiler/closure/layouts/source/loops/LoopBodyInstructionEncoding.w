//! Encodes canonical instructions for one resolved direct statement.

module wheeler.compiler.closure.loop_body_instruction_encoding;

import wheeler.compiler.closure.loop_arithmetic_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_offset_instruction_encoding;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.storage_opcodes;

classical class LoopBodyInstructionEncoding {
  private const long OPERAND_LOCAL = 1;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports the canonical instruction and byte extent of one direct statement.
  public record LoopBodyInstructionExtent(long instructionCount, long length, boolean valid) {}

  /// Measures one resolved direct statement without writing caller storage.
  public LoopBodyInstructionExtent loopBodyInstructionExtent(long opcode, long operand) {
    if (offsetBodyOpcode(opcode)) {
      return new LoopBodyInstructionExtent(
        offsetBodyInstructionCount(opcode, operand),
        offsetBodyInstructionLength(opcode, operand),
        true
      );
    }

    if (opcode == BODY_UTF8_SCALAR) {
      return new LoopBodyInstructionExtent(4, 104, true);
    }

    if (opcode == BODY_UTF8_WIDTH) {
      return new LoopBodyInstructionExtent(4, 104, true);
    }

    if (arithmeticBodyOpcode(opcode)) {
      return new LoopBodyInstructionExtent(
        arithmeticBodyInstructionCount(opcode),
        arithmeticBodyInstructionLength(opcode),
        true
      );
    }

    boolean bufferGet = opcode == BODY_WORDS_GET;
    if (opcode == BODY_BYTES_GET) {
      bufferGet = true;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      bufferGet = true;
    }

    if (bufferGet) {
      if (0 < operand / 65536) {
        return new LoopBodyInstructionExtent(4, 104, true);
      }

      return new LoopBodyInstructionExtent(3, 80, true);
    }

    boolean bufferSet = opcode == BODY_WORDS_SET;
    if (opcode == BODY_BYTES_SET) {
      bufferSet = true;
    }

    if (bufferSet) {
      if (0 < operand / 16777216) {
        return new LoopBodyInstructionExtent(4, 104, true);
      }

      return new LoopBodyInstructionExtent(3, 80, true);
    }

    boolean bufferCopy = opcode == BODY_WORDS_COPY;
    if (opcode == BODY_BYTES_COPY) {
      bufferCopy = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
      bufferCopy = true;
    }

    if (bufferCopy) {
      long borrowedCount = operand / 4294967296 % 2 + operand / 8589934592;
      return new LoopBodyInstructionExtent(4 + borrowedCount, 112 + borrowedCount * 24, true);
    }

    if (opcode == BODY_BOOLEAN_LITERAL) {
      return new LoopBodyInstructionExtent(2, 48, true);
    }

    if (opcode == BODY_ASSERT_BOOLEAN) {
      return new LoopBodyInstructionExtent(2, 40, true);
    }

    if (BODY_BOOLEAN_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_EQ_LITERAL_BASE + 256) {
        return new LoopBodyInstructionExtent(4, 104, true);
      }
    }

    if (BODY_ASSERT_LITERAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LOCAL_LT_BASE + 256) {
        return new LoopBodyInstructionExtent(4, 96, true);
      }
    }

    if (opcode == 769) {
      return new LoopBodyInstructionExtent(2, 48, true);
    }

    if (STATEMENT_LOCAL_LONG_COPY_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
        return new LoopBodyInstructionExtent(2, 48, true);
      }

      if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE) {
        return new LoopBodyInstructionExtent(2, 56, true);
      }

      if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + 256) {
        return new LoopBodyInstructionExtent(2, 48, true);
      }

      if (opcode < BODY_ASSERT_LT_LITERAL_BASE + 256) {
        return new LoopBodyInstructionExtent(4, 96, true);
      }
    }

    if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + 256) {
        return new LoopBodyInstructionExtent(2, 48, true);
      }
    }

    return new LoopBodyInstructionExtent(0, 0, false);
  }

  /// Reports the exact local suffix width of one resolved direct statement.
  public long loopBodyLocalCount(long opcode, long operand) {
    if (opcode == 769) {
      return 2;
    }

    if (STATEMENT_LOCAL_LONG_COPY_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
        return 2;
      }
    }

    if (STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + 256) {
        return 1;
      }
    }

    if (STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + 256) {
        return 1;
      }
    }

    if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LT_LITERAL_BASE + 256) {
        return 3;
      }
    }

    if (opcode == BODY_BOOLEAN_LITERAL) {
      return 2;
    }

    if (opcode == BODY_ASSERT_BOOLEAN) {
      return 1;
    }

    if (BODY_BOOLEAN_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_EQ_LITERAL_BASE + 256) {
        return 4;
      }
    }

    if (BODY_ASSERT_LITERAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LOCAL_LT_BASE + 256) {
        return 3;
      }
    }

    if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + 256) {
        return 1;
      }
    }

    if (offsetBodyOpcode(opcode)) {
      return offsetBodyLocalCount(opcode, operand);
    }

    if (opcode == BODY_UTF8_SCALAR) {
      return 4;
    }

    if (opcode == BODY_UTF8_WIDTH) {
      return 4;
    }

    if (arithmeticBodyOpcode(opcode)) {
      return arithmeticBodyLocalCount(opcode);
    }

    boolean bufferGet = opcode == BODY_WORDS_GET;
    if (opcode == BODY_BYTES_GET) {
      bufferGet = true;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      bufferGet = true;
    }

    if (bufferGet) {
      if (0 < operand / 65536) {
        return 4;
      }

      return 3;
    }

    boolean bufferSet = opcode == BODY_WORDS_SET;
    if (opcode == BODY_BYTES_SET) {
      bufferSet = true;
    }

    if (bufferSet) {
      if (0 < operand / 16777216) {
        return 3;
      }

      return 2;
    }

    boolean bufferCopy = opcode == BODY_WORDS_COPY;
    if (opcode == BODY_BYTES_COPY) {
      bufferCopy = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
      bufferCopy = true;
    }

    if (bufferCopy) {
      return 3 + operand / 4294967296 % 2 + operand / 8589934592;
    }

    return -1;
  }

  /// Writes one resolved literal or local operand.
  public long writeLoopInstructionOperand(
    borrow mut bytes output,
    long cursor,
    long kind,
    long operand
  ) {
    if (kind == OPERAND_LOCAL) {
      return writeUnsignedLittleEndian(output, cursor, operand, U64);
    }

    if (kind == 0) {
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    return -1;
  }

  /// Emits one resolved direct statement into caller-owned private code storage.
  public long writeLoopBodyInstructionProduct(
    borrow mut bytes output,
    long cursor,
    long body,
    borrow mut words bodyRows
  ) {
    long localBase = bodyRows[BODY_LOCAL_BASE_ROW + body];
    long opcode = bodyRows[BODY_OPCODE_ROW + body];
    long operandKind = bodyRows[BODY_OPERAND_KIND_ROW + body];
    long operand = bodyRows[BODY_OPERAND_ROW + body];
    if (opcode == BODY_BOOLEAN_LITERAL) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (offsetBodyOpcode(opcode)) {
      return writeOffsetBodyInstruction(output, cursor, localBase, opcode, operand);
    }

    long utf8Opcode = -1;
    if (opcode == BODY_UTF8_SCALAR) {
      utf8Opcode = OPCODE_UTF8_SCALAR;
    }

    if (opcode == BODY_UTF8_WIDTH) {
      utf8Opcode = OPCODE_UTF8_WIDTH;
    }

    if (arithmeticBodyOpcode(opcode)) {
      return writeArithmeticBodyInstruction(
        output,
        cursor,
        localBase,
        opcode,
        operandKind,
        operand
      );
    }

    if (-1 < utf8Opcode) {
      long text = operand / 256;
      long index = operand % 256;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, text, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, index, U64);
      cursor = writeInstructionHeader(output, cursor, utf8Opcode, INSTRUCTION_FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    boolean bufferGet = opcode == BODY_WORDS_GET;
    if (opcode == BODY_BYTES_GET) {
      bufferGet = true;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      bufferGet = true;
    }

    if (bufferGet) {
      long readStorageOpcode = OPCODE_WORDS_GET;
      if (opcode == BODY_BYTES_GET) {
        readStorageOpcode = OPCODE_BYTES_GET;
      }

      if (opcode == BODY_BYTEVIEW_GET) {
        readStorageOpcode = OPCODE_BYTES_GET;
      }

      long readBorrowedOwner = operand / 65536;
      long readOperand = operand % 65536;
      long readOwner = readOperand / 256;
      long readIndex = readOperand % 256;
      long readNextLocal = localBase;
      long readOwnerOperand = readOwner;
      if (0 < readBorrowedOwner) {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, readNextLocal, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, readOwner, U64);
        readOwnerOperand = readNextLocal;
        readNextLocal += 1;
      }

      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, readNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, readIndex, U64);
      long readIndexOperand = readNextLocal;
      readNextLocal += 1;
      cursor = writeInstructionHeader(
        output,
        cursor,
        readStorageOpcode,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, readNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, readOwnerOperand, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, readIndexOperand, U64);
      long readResult = readNextLocal;
      readNextLocal += 1;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, readNextLocal, U64);
      return writeUnsignedLittleEndian(output, cursor, readResult, U64);
    }

    boolean bufferSet = opcode == BODY_WORDS_SET;
    if (opcode == BODY_BYTES_SET) {
      bufferSet = true;
    }

    if (bufferSet) {
      long writeStorageOpcode = OPCODE_WORDS_SET;
      if (opcode == BODY_BYTES_SET) {
        writeStorageOpcode = OPCODE_BYTES_SET;
      }

      long writeBorrowedOwner = operand / 16777216;
      long writeOperand = operand % 16777216;
      long writeOwner = writeOperand / 65536;
      long writeIndex = writeOperand / 256 % 256;
      long writeValue = writeOperand % 256;
      long writeNextLocal = localBase;
      long writeOwnerOperand = writeOwner;
      if (0 < writeBorrowedOwner) {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, writeNextLocal, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, writeOwner, U64);
        writeOwnerOperand = writeNextLocal;
        writeNextLocal += 1;
      }

      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, writeNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeIndex, U64);
      long writeIndexOperand = writeNextLocal;
      writeNextLocal += 1;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, writeNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeValue, U64);
      long writeValueOperand = writeNextLocal;
      cursor = writeInstructionHeader(
        output,
        cursor,
        writeStorageOpcode,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, writeOwnerOperand, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeIndexOperand, U64);
      return writeUnsignedLittleEndian(output, cursor, writeValueOperand, U64);
    }

    boolean bufferCopy = opcode == BODY_WORDS_COPY;
    if (opcode == BODY_BYTES_COPY) {
      bufferCopy = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
      bufferCopy = true;
    }

    if (bufferCopy) {
      long copyGetOpcode = OPCODE_WORDS_GET;
      long copySetOpcode = OPCODE_WORDS_SET;
      if (opcode == BODY_BYTES_COPY) {
        copyGetOpcode = OPCODE_BYTES_GET;
        copySetOpcode = OPCODE_BYTES_SET;
      }

      if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
        copyGetOpcode = OPCODE_BYTES_GET;
        copySetOpcode = OPCODE_BYTES_SET;
      }

      long copyReadBorrowed = operand / 8589934592;
      long copyWriteBorrowed = operand / 4294967296 % 2;
      long copyOperand = operand % 4294967296;
      long copyWriteOwner = copyOperand / 16777216;
      long copyWriteIndex = copyOperand / 65536 % 256;
      long copyReadOwner = copyOperand / 256 % 256;
      long copyReadIndex = copyOperand % 256;
      long copyNextLocal = localBase;
      long copyWriteOwnerOperand = copyWriteOwner;
      if (0 < copyWriteBorrowed) {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, copyNextLocal, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, copyWriteOwner, U64);
        copyWriteOwnerOperand = copyNextLocal;
        copyNextLocal += 1;
      }

      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, copyNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, copyWriteIndex, U64);
      long copyWriteIndexOperand = copyNextLocal;
      copyNextLocal += 1;
      long copyReadOwnerOperand = copyReadOwner;
      if (0 < copyReadBorrowed) {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, copyNextLocal, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, copyReadOwner, U64);
        copyReadOwnerOperand = copyNextLocal;
        copyNextLocal += 1;
      }

      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, copyNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, copyReadIndex, U64);
      long copyReadIndexOperand = copyNextLocal;
      copyNextLocal += 1;
      cursor = writeInstructionHeader(output, cursor, copyGetOpcode, INSTRUCTION_FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, copyNextLocal, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, copyReadOwnerOperand, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, copyReadIndexOperand, U64);
      long copyResult = copyNextLocal;
      cursor = writeInstructionHeader(output, cursor, copySetOpcode, INSTRUCTION_FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, copyWriteOwnerOperand, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, copyWriteIndexOperand, U64);
      return writeUnsignedLittleEndian(output, cursor, copyResult, U64);
    }

    if (opcode == BODY_ASSERT_BOOLEAN) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_EXPECT_TRUE,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (opcode == 769) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    if (STATEMENT_LOCAL_LONG_COPY_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeUnsignedLittleEndian(
          output,
          cursor,
          opcode - STATEMENT_LOCAL_LONG_COPY_BASE,
          U64
        );
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        return writeUnsignedLittleEndian(output, cursor, localBase, U64);
      }
    }

    if (BODY_BOOLEAN_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_EQ_LITERAL_BASE + 256) {
        long comparisonSource = opcode - BODY_BOOLEAN_EQ_LITERAL_BASE;
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, comparisonSource, U64);
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_CONST,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        cursor = writeSignedLittleEndian(output, cursor, operand, U64);
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_EQ,
          INSTRUCTION_FORM_TERNARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
        return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      }
    }

    long assertionSource = -1;
    long assertionOpcode = OPCODE_LOCAL_EQ;
    boolean assertionLiteralLeft = false;
    if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LT_LITERAL_BASE) {
        assertionSource = opcode - BODY_ASSERT_EQ_LITERAL_BASE;
      } else {
        if (opcode < BODY_ASSERT_LT_LITERAL_BASE + 256) {
          assertionSource = opcode - BODY_ASSERT_LT_LITERAL_BASE;
          assertionOpcode = OPCODE_LOCAL_LT;
        }
      }
    }

    if (BODY_ASSERT_LITERAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LITERAL_LT_BASE + 256) {
        assertionSource = opcode - BODY_ASSERT_LITERAL_LT_BASE;
        assertionOpcode = OPCODE_LOCAL_LT;
        assertionLiteralLeft = true;
      }
    }

    if (BODY_ASSERT_LOCAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LOCAL_LT_BASE + 256) {
        assertionSource = opcode - BODY_ASSERT_LOCAL_LT_BASE;
        assertionOpcode = OPCODE_LOCAL_LT;
      }
    }

    if (-1 < assertionSource) {
      if (assertionLiteralLeft) {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_CONST,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeSignedLittleEndian(output, cursor, operand, U64);
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, assertionSource, U64);
      } else {
        cursor = writeInstructionHeader(
          output,
          cursor,
          OPCODE_LOCAL_MOVE,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
        cursor = writeUnsignedLittleEndian(output, cursor, assertionSource, U64);
        long assertionOperandOpcode = OPCODE_LOCAL_CONST;
        if (operandKind == OPERAND_LOCAL) {
          assertionOperandOpcode = OPCODE_LOCAL_MOVE;
        }

        cursor = writeInstructionHeader(
          output,
          cursor,
          assertionOperandOpcode,
          INSTRUCTION_FORM_BINARY
        );
        cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
        cursor = writeLoopInstructionOperand(output, cursor, operandKind, operand);
      }

      cursor = writeInstructionHeader(output, cursor, assertionOpcode, INSTRUCTION_FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_EXPECT_TRUE,
        INSTRUCTION_FORM_UNARY
      );
      return writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
    }

    long assignmentTarget = -1;
    if (STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE) {
        assignmentTarget = opcode - STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE;
      } else {
        if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + 256) {
          assignmentTarget = opcode - STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE;
        } else {
          if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < opcode) {
            if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE) {
              assignmentTarget = opcode - BODY_ASSIGN_BOOLEAN_LITERAL_BASE;
            } else {
              if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + 256) {
                assignmentTarget = opcode - BODY_ASSIGN_BOOLEAN_LOCAL_BASE;
              }
            }
          }
        }
      }
    }

    if (-1 < assignmentTarget) {
      long assignmentOpcode = OPCODE_LOCAL_CONST;
      if (operandKind == OPERAND_LOCAL) {
        assignmentOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(output, cursor, assignmentOpcode, INSTRUCTION_FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeLoopInstructionOperand(output, cursor, operandKind, operand);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, assignmentTarget, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase, U64);
    }

    long target = -1;
    long updateOpcode = OPCODE_LOCAL_ADD;
    long sourceForm = operandKind;
    if (STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE) {
        target = opcode - STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
      } else {
        if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE) {
          target = opcode - STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE;
          sourceForm = OPERAND_LOCAL;
        } else {
          if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE) {
            target = opcode - STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
            updateOpcode = OPCODE_LOCAL_SUB;
          } else {
            if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE) {
              target = opcode - STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE;
              updateOpcode = OPCODE_LOCAL_SUB;
              sourceForm = OPERAND_LOCAL;
            } else {
              if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE) {
                target = opcode - STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
                updateOpcode = OPCODE_LOCAL_XOR;
              } else {
                if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + 256) {
                  target = opcode - STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE;
                  updateOpcode = OPCODE_LOCAL_XOR;
                  sourceForm = OPERAND_LOCAL;
                }
              }
            }
          }
        }
      }
    }

    if (target < 0) {
      return -1;
    }

    long sourceOpcode = OPCODE_LOCAL_CONST;
    if (sourceForm == OPERAND_LOCAL) {
      sourceOpcode = OPCODE_LOCAL_MOVE;
    }

    cursor = writeInstructionHeader(output, cursor, sourceOpcode, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeLoopInstructionOperand(output, cursor, sourceForm, operand);
    cursor = writeInstructionHeader(output, cursor, updateOpcode, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase, U64);
  }

}
