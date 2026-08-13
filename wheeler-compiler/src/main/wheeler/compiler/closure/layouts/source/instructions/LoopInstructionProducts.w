//! Emits canonical instructions from resolved loop and direct-body products.

module wheeler.compiler.closure.loop_instruction_products;

import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.storage_opcodes;

classical class LoopInstructionProducts {
  private const long BODY_COUNT_LIMIT = 4096;
  private const long BODY_LOCAL_BASE_ROW = 4096;
  private const long BODY_OPCODE_ROW = 8192;
  private const long BODY_OPERAND_KIND_ROW = 12288;
  private const long BODY_OPERAND_ROW = 16384;
  private const long BODY_ROWS = 20480;
  private const long BODY_STAGING_BYTES = 163840;
  private const long CONDITION_LEFT_KIND_ROW = 256;
  private const long CONDITION_LEFT_OPERAND_ROW = 512;
  private const long CONDITION_RIGHT_KIND_ROW = 768;
  private const long CONDITION_RIGHT_OPERAND_ROW = 1024;
  private const long CONDITION_ROWS = 1536;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_FRAME_LOCAL_COUNT = 5;
  private const long LOOP_CONDITION_ROW = 768;
  private const long LOOP_LIMIT_ROW = 1024;
  private const long LOOP_FIRST_BODY_STATEMENT_ROW = 1536;
  private const long LOOP_BODY_STATEMENT_COUNT_ROW = 1792;
  private const long LOOP_ROWS = 2304;
  private const long MAX_CODE_BYTES = 262144;
  private const long OPERAND_LOCAL = 1;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one complete canonical loop code extent.
  public record LoopInstructionProductPlan(long instructionCount, long length, boolean valid) {}

  private long writeOperand(borrow mut bytes output, long cursor, long kind, long operand) {
    if (kind == OPERAND_LOCAL) {
      return writeUnsignedLittleEndian(output, cursor, operand, U64);
    }

    if (kind == 0) {
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    return -1;
  }

  private long bodyAtStatement(long statement, long bodyCount, borrow mut words bodyRows) {
    long selected = -1;
    long matches = 0;
    long body = 0;
    while (body < bodyCount) limit BODY_COUNT_LIMIT {
      if (bodyRows[body] == statement) {
        selected = body;
        matches += 1;
      }

      body += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long rebaseBodyOpcode(long opcode, long boundary, long bias) {
    long base = -1;
    if (STATEMENT_LOCAL_LONG_COPY_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_LONG_COPY_BASE + 256) {
        base = STATEMENT_LOCAL_LONG_COPY_BASE;
      }
    }

    if (STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE + 256) {
        base = opcode / 256 * 256;
      }
    }

    if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_LITERAL) {
        base = opcode / 256 * 256;
      }
    }

    if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + 256) {
        base = opcode / 256 * 256;
      }
    }

    if (base < 0) {
      return opcode;
    }

    long local = opcode - base;
    if (local < boundary) {
      return opcode;
    }

    return opcode + bias;
  }

  private long writeBodyStatement(
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
      cursor = writeOperand(output, cursor, operandKind, operand);
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
    cursor = writeOperand(output, cursor, sourceForm, operand);
    cursor = writeInstructionHeader(output, cursor, updateOpcode, INSTRUCTION_FORM_TERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase, U64);
  }

  /// Emits every validated loop window after a complete extent pass.
  public LoopInstructionProductPlan writeLoopInstructionProducts(
    long loopCount,
    borrow mut words conditionRows,
    borrow mut words loopRows,
    long bodyCount,
    borrow mut words bodyRows,
    borrow mut words loopLocalBases,
    borrow mut words loopInstructionStarts,
    borrow mut bytes output
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(conditionRows) == CONDITION_ROWS);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(bufferLength(loopLocalBases) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopInstructionStarts) == LOOP_COUNT_LIMIT);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ BODY_STAGING_BYTES, /* allocations= */ 1);
    words stagedBodies = allocate(staging, BODY_ROWS);
    long bodyRow = 0;
    while (bodyRow < BODY_ROWS) limit BODY_ROWS {
      set(stagedBodies, bodyRow, bodyRows[bodyRow]);
      bodyRow += 1;
    }

    boolean valid = true;
    long requiredLength = 0;
    long instructionCount = 0;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long bodyStatementCount = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      if (bodyStatementCount < 0) {
        valid = false;
      }

      if (64 < bodyStatementCount) {
        valid = false;
      }

      long bodyOffset = 0;
      while (bodyOffset < bodyStatementCount) limit 64 {
        long statement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop] + bodyOffset;
        long body = bodyAtStatement(statement, bodyCount, stagedBodies);
        if (body < 0) {
          valid = false;
        } else {
          long opcode = stagedBodies[BODY_OPCODE_ROW + body];
          if (opcode == BODY_WORDS_GET) {
            requiredLength += 80;
            instructionCount += 3;
          } else {
            if (opcode == BODY_WORDS_SET) {
              requiredLength += 80;
              instructionCount += 3;
            } else {
              if (opcode == BODY_BOOLEAN_LITERAL) {
                requiredLength += 48;
                instructionCount += 2;
              } else {
                if (opcode == BODY_ASSERT_BOOLEAN) {
                  requiredLength += 40;
                  instructionCount += 2;
                } else {
                  if (opcode == 769) {
                    requiredLength += 48;
                    instructionCount += 2;
                  } else {
                    if (STATEMENT_LOCAL_LONG_COPY_BASE - 1 < opcode) {
                      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
                        requiredLength += 48;
                        instructionCount += 2;
                      } else {
                        if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE) {
                          requiredLength += 56;
                          instructionCount += 2;
                        } else {
                          if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + 256) {
                            requiredLength += 48;
                            instructionCount += 2;
                          } else {
                            if (opcode < BODY_ASSERT_LT_LITERAL_BASE + 256) {
                              requiredLength += 96;
                              instructionCount += 4;
                            } else {
                              if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < opcode) {
                                if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + 256) {
                                  requiredLength += 48;
                                  instructionCount += 2;
                                } else {
                                  valid = false;
                                }
                              } else {
                                valid = false;
                              }
                            }
                          }
                        }
                      }
                    } else {
                      valid = false;
                    }
                  }
                }
              }
            }
          }
        }

        bodyOffset += 1;
      }

      requiredLength += 200;
      instructionCount += 8;
      if (MAX_CODE_BYTES < requiredLength) {
        valid = false;
      }

      loop += 1;
    }

    if (valid == false) {
      drop(stagedBodies);
      drop(staging);
      return new LoopInstructionProductPlan(0, 0, false);
    }

    long cursor = 0;
    loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long condition = loopRows[LOOP_CONDITION_ROW + loop];
      long localBase = loopLocalBases[loop];
      long instructionBase = loopInstructionStarts[loop];
      long bodyLocalBias = LOOP_FRAME_LOCAL_COUNT;
      long leftKind = conditionRows[CONDITION_LEFT_KIND_ROW + condition];
      long rightKind = conditionRows[CONDITION_RIGHT_KIND_ROW + condition];
      long leftOpcode = OPCODE_LOCAL_CONST;
      if (leftKind == OPERAND_LOCAL) {
        leftOpcode = OPCODE_LOCAL_MOVE;
      }

      long rightOpcode = OPCODE_LOCAL_CONST;
      if (rightKind == OPERAND_LOCAL) {
        rightOpcode = OPCODE_LOCAL_MOVE;
      }

      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, loopRows[LOOP_LIMIT_ROW + loop], U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, 0, U64);
      cursor = writeInstructionHeader(output, cursor, leftOpcode, INSTRUCTION_FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeOperand(
        output,
        cursor,
        leftKind,
        conditionRows[CONDITION_LEFT_OPERAND_ROW + condition]
      );
      cursor = writeInstructionHeader(output, cursor, rightOpcode, INSTRUCTION_FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      cursor = writeOperand(
        output,
        cursor,
        rightKind,
        conditionRows[CONDITION_RIGHT_OPERAND_ROW + condition]
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LT, INSTRUCTION_FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 3, U64);
      long exitHeader = cursor;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_JUMP_IF_ZERO,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, 0, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_LOOP_CHECK,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
      long emittedBodyCount = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      long emittedBodyOffset = 0;
      long bodyInstructions = 0;
      while (emittedBodyOffset < emittedBodyCount) limit 64 {
        long emittedStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop] + emittedBodyOffset;
        long emittedBody = bodyAtStatement(emittedStatement, bodyCount, stagedBodies);
        long emittedLocal = stagedBodies[BODY_LOCAL_BASE_ROW + emittedBody];
        set(stagedBodies, BODY_LOCAL_BASE_ROW + emittedBody, emittedLocal + bodyLocalBias);
        long emittedOpcode = stagedBodies[BODY_OPCODE_ROW + emittedBody];
        set(
          stagedBodies,
          BODY_OPCODE_ROW + emittedBody,
          rebaseBodyOpcode(emittedOpcode, localBase, bodyLocalBias)
        );
        long emittedOperand = stagedBodies[BODY_OPERAND_ROW + emittedBody];
        if (emittedOpcode == BODY_WORDS_GET) {
          long readOwner = emittedOperand / 256;
          long readIndex = emittedOperand % 256;
          if (localBase < readOwner + 1) {
            readOwner += bodyLocalBias;
          }

          if (localBase < readIndex + 1) {
            readIndex += bodyLocalBias;
          }

          set(stagedBodies, BODY_OPERAND_ROW + emittedBody, readOwner * 256 + readIndex);
        } else {
          if (emittedOpcode == BODY_WORDS_SET) {
            long writeOwner = emittedOperand / 65536;
            long writeIndex = emittedOperand / 256 % 256;
            long writeValue = emittedOperand % 256;
            if (localBase < writeOwner + 1) {
              writeOwner += bodyLocalBias;
            }

            if (localBase < writeIndex + 1) {
              writeIndex += bodyLocalBias;
            }

            if (localBase < writeValue + 1) {
              writeValue += bodyLocalBias;
            }

            set(
              stagedBodies,
              BODY_OPERAND_ROW + emittedBody,
              writeOwner * 65536 + writeIndex * 256 + writeValue
            );
          } else {
            if (stagedBodies[BODY_OPERAND_KIND_ROW + emittedBody] == OPERAND_LOCAL) {
              if (localBase < emittedOperand + 1) {
                set(stagedBodies, BODY_OPERAND_ROW + emittedBody, emittedOperand + bodyLocalBias);
              }
            }
          }
        }

        long next = writeBodyStatement(output, cursor, emittedBody, stagedBodies);
        if (next < 0) {
          valid = false;
        } else {
          cursor = next;
          long writtenOpcode = stagedBodies[BODY_OPCODE_ROW + emittedBody];
          if (writtenOpcode == BODY_WORDS_GET) {
            bodyInstructions += 3;
          } else {
            if (writtenOpcode == BODY_WORDS_SET) {
              bodyInstructions += 3;
            } else {
              if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < writtenOpcode) {
                if (writtenOpcode < BODY_BOOLEAN_LITERAL) {
                  bodyInstructions += 4;
                } else {
                  bodyInstructions += 2;
                }
              } else {
                bodyInstructions += 2;
              }
            }
          }
        }

        emittedBodyOffset += 1;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, INSTRUCTION_FORM_UNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 2, U64);
      long exitTarget = instructionBase + 8 + bodyInstructions;
      long exitCursor = writeUnsignedLittleEndian(output, exitHeader + 16, exitTarget, U64);
      if (exitCursor != exitHeader + 24) {
        valid = false;
      }

      loop += 1;
    }

    drop(stagedBodies);
    drop(staging);
    if (valid == false) {
      return new LoopInstructionProductPlan(0, 0, false);
    }

    return new LoopInstructionProductPlan(instructionCount, cursor, true);
  }
}
