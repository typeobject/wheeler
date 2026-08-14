//! Encodes canonical instructions for one resolved direct statement.

module wheeler.compiler.closure.loop_body_instruction_encoding;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.storage_opcodes;

classical class LoopBodyInstructionEncoding {
  private const long OPERAND_LOCAL = 1;
  private const long U64 = ENCODING_WIDTH_U64;

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

    if (opcode == BODY_WORDS_GET) {
      long readOwner = operand / 256;
      long readIndex = operand % 256;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, readIndex, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_WORDS_GET,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, readOwner, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    }

    if (opcode == BODY_WORDS_SET) {
      long writeOwner = operand / 65536;
      long writeIndex = operand / 256 % 256;
      long writeValue = operand % 256;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeIndex, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, writeValue, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_WORDS_SET,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, writeOwner, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      return writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
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

    long assertionSource = -1;
    long assertionOpcode = OPCODE_LOCAL_EQ;
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

    if (-1 < assertionSource) {
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_MOVE,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, assertionSource, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, operand, U64);
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
