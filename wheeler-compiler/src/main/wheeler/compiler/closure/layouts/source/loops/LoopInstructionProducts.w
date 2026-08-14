//! Emits canonical root and nested loop windows from resolved source products.

module wheeler.compiler.closure.loop_instruction_products;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_buffer_operands;
import wheeler.compiler.closure.loop_nested_loop_products;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.resolved_statements;

classical class LoopInstructionProducts {
  private const long BLOCK_COUNT_LIMIT = 1024;
  private const long BODY_COUNT_LIMIT = 4096;
  private const long CONDITION_LEFT_KIND_ROW = 256;
  private const long CONDITION_LEFT_OPERAND_ROW = 512;
  private const long CONDITION_RIGHT_KIND_ROW = 768;
  private const long CONDITION_RIGHT_OPERAND_ROW = 1024;
  private const long CONDITION_ROWS = 1536;
  private const long LOOP_BODY_STATEMENT_COUNT_ROW = 1792;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_DEPTH_ROW = 2048;
  private const long LOOP_FIRST_BODY_STATEMENT_ROW = 1536;
  private const long LOOP_FRAME_LOCAL_COUNT = 5;
  private const long LOOP_STATEMENT_ORDINAL_ROW = 512;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STATEMENTS = 4096;
  private const long OPERAND_LOCAL = 1;
  private const long STAGING_BYTES = 178688;
  private const long STATEMENT_BLOCK_ROW = 4096;
  private const long STATEMENT_ORDINAL_ROW = 8192;

  /// Reports one complete canonical loop code extent.
  public record LoopInstructionProductPlan(long instructionCount, long length, boolean valid) {}

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

    if (BODY_BOOLEAN_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_EQ_LITERAL_BASE + 256) {
        base = BODY_BOOLEAN_EQ_LITERAL_BASE;
      }
    }

    if (BODY_ASSERT_LITERAL_LT_BASE - 1 < opcode) {
      if (opcode < BODY_ASSERT_LOCAL_LT_BASE + 256) {
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

    if (opcode == BODY_WORDS_GET_OFFSET) {
      bufferOperand = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
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

  private void rebaseConditionOperand(
    long condition,
    long kindRow,
    long operandRow,
    long boundary,
    borrow mut words conditionRows
  ) {
    if (conditionRows[kindRow + condition] == OPERAND_LOCAL) {
      long operand = conditionRows[operandRow + condition];
      if (boundary < operand + 1) {
        set(conditionRows, operandRow + condition, operand + LOOP_FRAME_LOCAL_COUNT);
      }
    }
  }

  /// Emits every validated root loop and its nested loop windows atomically.
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
    assert(bufferLength(loopRows) == 2304);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < blockCount);
    assert(blockCount < BLOCK_COUNT_LIMIT + 1);
    assert(bufferLength(blockRows) == 6144);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(-1 < nestedCount);
    assert(nestedCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(nestedRows) == NESTED_ROWS);
    assert(bufferLength(loopLocalBases) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopInstructionStarts) == LOOP_COUNT_LIMIT);
    assert(bufferLength(loopWindowRows) == 768);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 4);
    words stagedBodies = allocate(staging, BODY_ROWS);
    words stagedConditions = allocate(staging, CONDITION_ROWS);
    words stagedInstructionStarts = allocate(staging, LOOP_COUNT_LIMIT);
    words ownerInstructionBiases = allocate(staging, /* length= */ 64);
    long row = 0;
    while (row < BODY_ROWS) limit BODY_ROWS {
      set(stagedBodies, row, bodyRows[row]);
      row += 1;
    }

    row = 0;
    while (row < CONDITION_ROWS) limit CONDITION_ROWS {
      set(stagedConditions, row, conditionRows[row]);
      row += 1;
    }

    boolean valid = true;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long owner = loopRows[loop];
      if (owner < 0) {
        valid = false;
      }

      if (63 < owner) {
        valid = false;
      }

      long depth = loopRows[LOOP_DEPTH_ROW + loop];
      if (depth < 1) {
        valid = false;
      }

      if (4 < depth) {
        valid = false;
      }

      long bodyStatementCount = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
      long firstBodyStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
      if (bodyStatementCount < 0) {
        valid = false;
      }

      if (64 < bodyStatementCount) {
        valid = false;
      }

      if (0 < bodyStatementCount) {
        if (firstBodyStatement < 0) {
          valid = false;
        }

        if (statementCount - bodyStatementCount < firstBodyStatement) {
          valid = false;
        }
      }

      long loopBlock = -1;
      if (valid) {
        if (0 < bodyStatementCount) {
          loopBlock = statementRows[STATEMENT_BLOCK_ROW + firstBodyStatement];
          if (loopBlock < 0) {
            valid = false;
          }

          if (blockCount - 1 < loopBlock) {
            valid = false;
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

      if (valid) {
        if (0 < bodyStatementCount) {
          long body = 0;
          while (body < bodyCount) limit BODY_COUNT_LIMIT {
            long statement = stagedBodies[body];
            if (statementRows[statement] == loopRows[loop]) {
              if (
                loopRows[LOOP_STATEMENT_ORDINAL_ROW + loop] < statementRows[STATEMENT_ORDINAL_ROW
                  + statement]
              ) {
                rebaseBodyProduct(body, localBase, LOOP_FRAME_LOCAL_COUNT, stagedBodies);
              }
            }

            body += 1;
          }

          long descendant = 0;
          while (descendant < loopCount) limit LOOP_COUNT_LIMIT {
            if (loopRows[descendant] == loopRows[loop]) {
              if (
                loopRows[LOOP_STATEMENT_ORDINAL_ROW + loop] < loopRows[LOOP_STATEMENT_ORDINAL_ROW
                  + descendant]
              ) {
                long condition = loopRows[768 + descendant];
                rebaseConditionOperand(
                  condition,
                  CONDITION_LEFT_KIND_ROW,
                  CONDITION_LEFT_OPERAND_ROW,
                  localBase,
                  stagedConditions
                );
                rebaseConditionOperand(
                  condition,
                  CONDITION_RIGHT_KIND_ROW,
                  CONDITION_RIGHT_OPERAND_ROW,
                  localBase,
                  stagedConditions
                );
              }
            }

            descendant += 1;
          }
        }
      }

      loop += 1;
    }

    long requiredLength = 0;
    long requiredInstructions = 0;
    loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      if (loopRows[LOOP_DEPTH_ROW + loop] == 1) {
        long rootOwner = loopRows[loop];
        long instructionStart = loopInstructionStarts[loop] + ownerInstructionBiases[rootOwner];
        set(stagedInstructionStarts, loop, instructionStart);
        NestedLoopInstructionPlan measured = writeNestedLoopInstructionProduct(
          loop,
          loopCount,
          loopRows,
          stagedConditions,
          statementCount,
          statementRows,
          blockCount,
          blockRows,
          bodyCount,
          stagedBodies,
          nestedCount,
          nestedRows,
          loopLocalBases,
          instructionStart,
          /* depth= */ 1,
          /* publish= */ false,
          /* outputStart= */ 0,
          loopWindowRows,
          output
        );
        if (measured.valid) {
          requiredLength += measured.length;
          requiredInstructions += measured.instructionCount;
          set(
            ownerInstructionBiases,
            rootOwner,
            ownerInstructionBiases[rootOwner] + measured.instructionCount
          );
        } else {
          valid = false;
        }
      }

      loop += 1;
    }

    if (MAX_CODE_BYTES < requiredLength) {
      valid = false;
    }

    if (valid == false) {
      drop(ownerInstructionBiases);
      drop(stagedInstructionStarts);
      drop(stagedConditions);
      drop(stagedBodies);
      drop(staging);
      return new LoopInstructionProductPlan(0, 0, false);
    }

    long cursor = 0;
    long instructionCount = 0;
    loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      if (loopRows[LOOP_DEPTH_ROW + loop] == 1) {
        NestedLoopInstructionPlan emitted = writeNestedLoopInstructionProduct(
          loop,
          loopCount,
          loopRows,
          stagedConditions,
          statementCount,
          statementRows,
          blockCount,
          blockRows,
          bodyCount,
          stagedBodies,
          nestedCount,
          nestedRows,
          loopLocalBases,
          stagedInstructionStarts[loop],
          /* depth= */ 1,
          /* publish= */ true,
          cursor,
          loopWindowRows,
          output
        );
        assert(emitted.valid);
        cursor += emitted.length;
        instructionCount += emitted.instructionCount;
      }

      loop += 1;
    }

    assert(cursor == requiredLength);
    assert(instructionCount == requiredInstructions);
    drop(ownerInstructionBiases);
    drop(stagedInstructionStarts);
    drop(stagedConditions);
    drop(stagedBodies);
    drop(staging);
    return new LoopInstructionProductPlan(instructionCount, cursor, true);
  }
}
