//! Emits canonical instructions from resolved loop and direct-body products.

module wheeler.compiler.closure.loop_instruction_products;

import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_buffer_operands;
import wheeler.compiler.closure.loop_nested_block_products;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.storage_opcodes;

classical class LoopInstructionProducts {
  private const long BODY_COUNT_LIMIT = 4096;
  private const long BLOCK_COUNT_LIMIT = 1024;
  private const long BLOCK_PARENT_ROW = 1024;
  private const long BLOCK_ROWS = 6144;
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
  private const long MAX_STATEMENTS = 4096;
  private const long OPERAND_LOCAL = 1;
  private const long STATEMENT_BLOCK_ROW = 4096;
  private const long STATEMENT_CHILD_COUNT_ROW = 24576;
  private const long U64 = ENCODING_WIDTH_U64;
  private const long WINDOW_ROWS = 768;

  /// Reports one complete canonical loop code extent.
  public record LoopInstructionProductPlan(long instructionCount, long length, boolean valid) {}

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

  private long nestedAtStatement(long statement, long nestedCount, borrow mut words nestedRows) {
    long selected = -1;
    long matches = 0;
    long nested = 0;
    while (nested < nestedCount) limit BODY_COUNT_LIMIT {
      if (nestedRows[nested] == statement) {
        selected = nested;
        matches += 1;
      }

      nested += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private boolean blockDescendsFrom(long block, long root, borrow mut words blockRows) {
    long selected = block;
    long depth = 0;
    while (-1 < selected) limit 5 {
      if (selected == root) {
        return true;
      }

      selected = blockRows[BLOCK_PARENT_ROW + selected];
      depth += 1;
    }

    return false;
  }

  private void rebaseBodyProduct(long body, long boundary, long bias, borrow mut words bodyRows) {
    long localBase = bodyRows[BODY_LOCAL_BASE_ROW + body];
    set(bodyRows, BODY_LOCAL_BASE_ROW + body, localBase + bias);
    long opcode = bodyRows[BODY_OPCODE_ROW + body];
    set(bodyRows, BODY_OPCODE_ROW + body, rebaseBodyOpcode(opcode, boundary, bias));
    long operand = bodyRows[BODY_OPERAND_ROW + body];
    boolean bufferOperand = opcode == BODY_WORDS_GET;
    if (opcode == BODY_WORDS_SET) {
      bufferOperand = true;
    }

    if (opcode == BODY_WORDS_COPY) {
      bufferOperand = true;
    }

    if (opcode == BODY_BYTES_GET) {
      bufferOperand = true;
    }

    if (opcode == BODY_BYTES_SET) {
      bufferOperand = true;
    }

    if (opcode == BODY_BYTES_COPY) {
      bufferOperand = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
      bufferOperand = true;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      bufferOperand = true;
    }

    if (bufferOperand) {
      set(
        bodyRows,
        BODY_OPERAND_ROW + body,
        rebaseLoopBufferOperand(opcode, operand, boundary, bias)
      );
    } else {
      if (bodyRows[BODY_OPERAND_KIND_ROW + body] == OPERAND_LOCAL) {
        if (boundary < operand + 1) {
          set(bodyRows, BODY_OPERAND_ROW + body, operand + bias);
        }
      }
    }
  }

  /// Emits every validated loop and nested-control window atomically.
  public LoopInstructionProductPlan writeLoopInstructionProducts(
    long loopCount,
    borrow mut words conditionRows,
    borrow mut words loopRows,
    long statementCount,
    borrow mut words statementRows,
    long blockCount,
    borrow mut words blockRows,
    long bodyCount,
    borrow mut words bodyRows,
    long nestedCount,
    borrow mut words nestedRows,
    borrow mut words loopLocalBases,
    borrow mut words loopInstructionStarts,
    borrow mut words loopWindowRows,
    borrow mut bytes output
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(conditionRows) == CONDITION_ROWS);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < blockCount);
    assert(blockCount < BLOCK_COUNT_LIMIT + 1);
    assert(bufferLength(blockRows) == BLOCK_ROWS);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(-1 < nestedCount);
    assert(nestedCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(nestedRows) == NESTED_ROWS);
    assert(bufferLength(loopLocalBases) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopInstructionStarts) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopWindowRows) == WINDOW_ROWS);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ BODY_STAGING_BYTES, /* allocations= */ 1);
    words stagedBodies = allocate(staging, BODY_ROWS);
    long bodyRow = 0;
    while (bodyRow < BODY_ROWS) limit BODY_ROWS {
      set(stagedBodies, bodyRow, bodyRows[bodyRow]);
      bodyRow += 1;
    }

    boolean valid = true;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long bodyStatementCount = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      if (bodyStatementCount < 0) {
        valid = false;
      }

      if (64 < bodyStatementCount) {
        valid = false;
      }

      long firstBodyStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
      long loopBlock = -1;
      if (0 < bodyStatementCount) {
        if (firstBodyStatement < 0) {
          valid = false;
        } else {
          if (statementCount - bodyStatementCount < firstBodyStatement) {
            valid = false;
          } else {
            loopBlock = statementRows[STATEMENT_BLOCK_ROW + firstBodyStatement];
            if (loopBlock < 0) {
              valid = false;
            } else {
              if (blockCount - 1 < loopBlock) {
                valid = false;
              }
            }
          }
        }
      }

      long localBase = loopLocalBases[loop];
      if (localBase < 0) {
        valid = false;
      }

      if (loopInstructionStarts[loop] < 0) {
        valid = false;
      }

      if (0 < bodyStatementCount) {
        long rebaseBody = 0;
        while (rebaseBody < bodyCount) limit BODY_COUNT_LIMIT {
          long bodyStatement = stagedBodies[rebaseBody];
          long bodyBlock = statementRows[STATEMENT_BLOCK_ROW + bodyStatement];
          if (blockDescendsFrom(bodyBlock, loopBlock, blockRows)) {
            rebaseBodyProduct(rebaseBody, localBase, LOOP_FRAME_LOCAL_COUNT, stagedBodies);
          }

          rebaseBody += 1;
        }
      }

      loop += 1;
    }

    long requiredLength = 0;
    long requiredInstructionCount = 0;
    loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long measuredFirstBodyStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
      long measuredBodyStatementCount = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      long measuredLocalBase = loopLocalBases[loop];
      long measuredInstructionBase = loopInstructionStarts[loop];
      long measuredBodyInstructions = 0;
      long measuredLoopLength = 192;
      long measuredBodyOffset = 0;
      while (measuredBodyOffset < measuredBodyStatementCount) limit 64 {
        long measuredStatement = measuredFirstBodyStatement + measuredBodyOffset;
        if (statementRows[STATEMENT_CHILD_COUNT_ROW + measuredStatement] == 0) {
          long measuredBody = bodyAtStatement(measuredStatement, bodyCount, stagedBodies);
          if (measuredBody < 0) {
            valid = false;
          } else {
            LoopBodyInstructionExtent measuredExtent = loopBodyInstructionExtent(
              stagedBodies[BODY_OPCODE_ROW + measuredBody],
              stagedBodies[BODY_OPERAND_ROW + measuredBody]
            );
            if (measuredExtent.valid == false) {
              valid = false;
            } else {
              measuredBodyInstructions += measuredExtent.instructionCount;
              measuredLoopLength += measuredExtent.length;
            }
          }
        } else {
          long measuredNested = nestedAtStatement(measuredStatement, nestedCount, nestedRows);
          if (measuredNested < 0) {
            valid = false;
          } else {
            long measuredNestedCondition = nestedRows[NESTED_CONDITION_LOCAL_ROW + measuredNested];
            if (measuredLocalBase < measuredNestedCondition + 1) {
              measuredNestedCondition += LOOP_FRAME_LOCAL_COUNT;
            }

            LoopNestedBlockPlan measuredNestedPlan = writeLoopNestedBlockProducts(
              measuredStatement,
              statementCount,
              statementRows,
              blockCount,
              blockRows,
              bodyCount,
              stagedBodies,
              nestedRows[NESTED_KIND_ROW + measuredNested],
              measuredNestedCondition,
              nestedRows[NESTED_CONDITION_LITERAL_ROW + measuredNested],
              nestedRows[NESTED_LOCAL_BASE_ROW + measuredNested] + LOOP_FRAME_LOCAL_COUNT,
              measuredInstructionBase + 7 + measuredBodyInstructions,
              /* publish= */ false,
              /* outputStart= */ 0,
              output
            );
            if (measuredNestedPlan.valid) {
              measuredBodyInstructions += measuredNestedPlan.instructionCount;
              measuredLoopLength += measuredNestedPlan.length;
            } else {
              valid = false;
            }
          }
        }

        measuredBodyOffset += 1;
      }

      requiredLength += measuredLoopLength;
      requiredInstructionCount += measuredBodyInstructions + 8;
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
    long instructionCount = 0;
    loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long loopCodeStart = cursor;
      long condition = loopRows[LOOP_CONDITION_ROW + loop];
      long emittedLocalBase = loopLocalBases[loop];
      long emittedInstructionBase = loopInstructionStarts[loop];
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
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase, U64);
      cursor = writeSignedLittleEndian(output, cursor, loopRows[LOOP_LIMIT_ROW + loop], U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 1, U64);
      cursor = writeSignedLittleEndian(output, cursor, 0, U64);
      cursor = writeInstructionHeader(output, cursor, leftOpcode, INSTRUCTION_FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 2, U64);
      cursor = writeLoopInstructionOperand(
        output,
        cursor,
        leftKind,
        conditionRows[CONDITION_LEFT_OPERAND_ROW + condition]
      );
      cursor = writeInstructionHeader(output, cursor, rightOpcode, INSTRUCTION_FORM_BINARY);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 3, U64);
      cursor = writeLoopInstructionOperand(
        output,
        cursor,
        rightKind,
        conditionRows[CONDITION_RIGHT_OPERAND_ROW + condition]
      );
      cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_LT, INSTRUCTION_FORM_TERNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 2, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 3, U64);
      long exitHeader = cursor;
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_JUMP_IF_ZERO,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 4, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, 0, U64);
      cursor = writeInstructionHeader(
        output,
        cursor,
        OPCODE_LOCAL_LOOP_CHECK,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase + 1, U64);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedLocalBase, U64);

      long emittedFirstBodyStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
      long emittedBodyStatementCount = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      long emittedBodyInstructions = 0;
      long emittedBodyOffset = 0;
      while (emittedBodyOffset < emittedBodyStatementCount) limit 64 {
        long emittedStatement = emittedFirstBodyStatement + emittedBodyOffset;
        if (statementRows[STATEMENT_CHILD_COUNT_ROW + emittedStatement] == 0) {
          long emittedBody = bodyAtStatement(emittedStatement, bodyCount, stagedBodies);
          long next = writeLoopBodyInstructionProduct(output, cursor, emittedBody, stagedBodies);
          assert(-1 < next);
          cursor = next;
          LoopBodyInstructionExtent emittedExtent = loopBodyInstructionExtent(
            stagedBodies[BODY_OPCODE_ROW + emittedBody],
            stagedBodies[BODY_OPERAND_ROW + emittedBody]
          );
          assert(emittedExtent.valid);
          emittedBodyInstructions += emittedExtent.instructionCount;
        } else {
          long emittedNested = nestedAtStatement(emittedStatement, nestedCount, nestedRows);
          long emittedNestedCondition = nestedRows[NESTED_CONDITION_LOCAL_ROW + emittedNested];
          if (emittedLocalBase < emittedNestedCondition + 1) {
            emittedNestedCondition += LOOP_FRAME_LOCAL_COUNT;
          }

          LoopNestedBlockPlan emittedNestedPlan = writeLoopNestedBlockProducts(
            emittedStatement,
            statementCount,
            statementRows,
            blockCount,
            blockRows,
            bodyCount,
            stagedBodies,
            nestedRows[NESTED_KIND_ROW + emittedNested],
            emittedNestedCondition,
            nestedRows[NESTED_CONDITION_LITERAL_ROW + emittedNested],
            nestedRows[NESTED_LOCAL_BASE_ROW + emittedNested] + LOOP_FRAME_LOCAL_COUNT,
            emittedInstructionBase + 7 + emittedBodyInstructions,
            /* publish= */ true,
            cursor,
            output
          );
          assert(emittedNestedPlan.valid);
          emittedBodyInstructions += emittedNestedPlan.instructionCount;
          cursor += emittedNestedPlan.length;
        }

        emittedBodyOffset += 1;
      }

      cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, INSTRUCTION_FORM_UNARY);
      cursor = writeUnsignedLittleEndian(output, cursor, emittedInstructionBase + 2, U64);
      long exitTarget = emittedInstructionBase + 8 + emittedBodyInstructions;
      long exitCursor = writeUnsignedLittleEndian(output, exitHeader + 16, exitTarget, U64);
      assert(exitCursor == exitHeader + 24);
      long loopInstructionCount = emittedBodyInstructions + 8;
      set(loopWindowRows, loop, loopCodeStart);
      set(loopWindowRows, 256 + loop, loopInstructionCount);
      set(loopWindowRows, 512 + loop, cursor - loopCodeStart);
      instructionCount += loopInstructionCount;
      loop += 1;
    }

    assert(cursor == requiredLength);
    assert(instructionCount == requiredInstructionCount);
    drop(stagedBodies);
    drop(staging);
    return new LoopInstructionProductPlan(instructionCount, cursor, true);
  }
}
