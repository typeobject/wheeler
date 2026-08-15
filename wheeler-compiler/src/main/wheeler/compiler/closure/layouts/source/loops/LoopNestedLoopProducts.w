//! Emits bounded loop windows, including nested loops, from resolved products.

module wheeler.compiler.closure.loop_nested_loop_products;

import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_nested_block_products;
import wheeler.compiler.closure.nested_source_call_windows;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.opcodes;

classical class LoopNestedLoopProducts {
  private const long BODY_COUNT_LIMIT = 4096;
  private const long BLOCK_COUNT_LIMIT = 1024;
  private const long CONDITION_LEFT_KIND_ROW = 256;
  private const long CONDITION_LEFT_OPERAND_ROW = 512;
  private const long CONDITION_RIGHT_KIND_ROW = 768;
  private const long CONDITION_RIGHT_OPERAND_ROW = 1024;
  private const long LOOP_BODY_STATEMENT_COUNT_ROW = 1792;
  private const long LOOP_CONDITION_ROW = 768;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_DEPTH_ROW = 2048;
  private const long LOOP_FIRST_BODY_STATEMENT_ROW = 1536;
  private const long LOOP_LIMIT_ROW = 1024;
  private const long LOOP_STATEMENT_ORDINAL_ROW = 512;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STATEMENTS = 4096;
  private const long NESTED_CONDITION_LITERAL_ROW = 12288;
  private const long NESTED_CONDITION_LOCAL_ROW = 8192;
  private const long NESTED_KIND_ROW = 4096;
  private const long NESTED_LOCAL_BASE_ROW = 16384;
  private const long OPERAND_LOCAL = 1;
  private const long STATEMENT_CHILD_COUNT_ROW = 24576;
  private const long STATEMENT_ORDINAL_ROW = 8192;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one complete loop window.
  public record NestedLoopInstructionPlan(long instructionCount, long length, boolean valid) {}

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

  private long loopAtStatement(
    long statement,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words statementRows
  ) {
    long owner = statementRows[statement];
    long ordinal = statementRows[STATEMENT_ORDINAL_ROW + statement];
    long selected = -1;
    long matches = 0;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      if (loopRows[loop] == owner) {
        if (loopRows[LOOP_STATEMENT_ORDINAL_ROW + loop] == ordinal) {
          selected = loop;
          matches += 1;
        }
      }

      loop += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long frameBiasForStatement(
    long statement,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words statementRows
  ) {
    long owner = statementRows[statement];
    long ordinal = statementRows[STATEMENT_ORDINAL_ROW + statement];
    long priorLoops = 0;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      if (loopRows[loop] == owner) {
        if (loopRows[LOOP_STATEMENT_ORDINAL_ROW + loop] < ordinal) {
          priorLoops += 1;
        }
      }

      loop += 1;
    }

    return priorLoops * 5;
  }

  private long rebaseLocalForStatement(
    long local,
    long statement,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words loopLocalBases,
    borrow mut words statementRows
  ) {
    long owner = statementRows[statement];
    long ordinal = statementRows[STATEMENT_ORDINAL_ROW + statement];
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      if (loopRows[loop] == owner) {
        if (loopRows[LOOP_STATEMENT_ORDINAL_ROW + loop] < ordinal) {
          if (loopLocalBases[loop] < local + 1) {
            local += 5;
          }
        }
      }

      loop += 1;
    }

    return local;
  }

  private long writeOperand(borrow mut bytes output, long cursor, long kind, long operand) {
    if (kind == OPERAND_LOCAL) {
      return writeUnsignedLittleEndian(output, cursor, operand, U64);
    }

    if (kind == 0) {
      return writeSignedLittleEndian(output, cursor, operand, U64);
    }

    return -1;
  }

  private NestedLoopInstructionPlan measureBody(
    long loop,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words conditionRows,
    long statementCount,
    borrow mut words statementRows,
    long blockCount,
    borrow mut words blockRows,
    long bodyCount,
    borrow mut words bodyRows,
    long callCount,
    borrow mut words callStatements,
    borrow mut words callWindowRows,
    borrow mut words callInstructionStarts,
    borrow byteview callCode,
    long nestedCount,
    borrow mut words nestedRows,
    borrow mut words loopLocalBases,
    long instructionBase,
    long depth,
    borrow mut words loopWindowRows,
    borrow mut bytes output
  ) {
    long firstStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
    long statementCountForLoop = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
    if (statementCountForLoop < 0) {
      return new NestedLoopInstructionPlan(0, 0, false);
    }

    if (64 < statementCountForLoop) {
      return new NestedLoopInstructionPlan(0, 0, false);
    }

    if (0 < statementCountForLoop) {
      if (firstStatement < 0) {
        return new NestedLoopInstructionPlan(0, 0, false);
      }

      if (statementCount - statementCountForLoop < firstStatement) {
        return new NestedLoopInstructionPlan(0, 0, false);
      }
    }

    long bodyInstructions = 0;
    long length = 192;
    long offset = 0;
    while (offset < statementCountForLoop) limit 64 {
      long statement = firstStatement + offset;
      if (statementRows[STATEMENT_CHILD_COUNT_ROW + statement] == 0) {
        long body = bodyAtStatement(statement, bodyCount, bodyRows);
        if (body < 0) {
          NestedSourceCallWindow callWindow = resolveNestedSourceCallWindow(
            statement,
            callCount,
            callStatements,
            callWindowRows
          );
          if (callWindow.valid == false) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          set(callInstructionStarts, callWindow.call, instructionBase + 7 + bodyInstructions);
          bodyInstructions += callWindow.instructionCount;
          length += callWindow.length;
        } else {
          LoopBodyInstructionExtent extent = loopBodyInstructionExtent(
            bodyRows[BODY_OPCODE_ROW + body],
            bodyRows[BODY_OPERAND_ROW + body]
          );
          if (extent.valid == false) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          bodyInstructions += extent.instructionCount;
          length += extent.length;
        }
      } else {
        long childLoop = loopAtStatement(statement, loopCount, loopRows, statementRows);
        if (-1 < childLoop) {
          if (4 < depth + 1) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          if (loopRows[LOOP_DEPTH_ROW + childLoop] != depth + 1) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          NestedLoopInstructionPlan child = measureBody(
            childLoop,
            loopCount,
            loopRows,
            conditionRows,
            statementCount,
            statementRows,
            blockCount,
            blockRows,
            bodyCount,
            bodyRows,
            callCount,
            callStatements,
            callWindowRows,
            callInstructionStarts,
            callCode,
            nestedCount,
            nestedRows,
            loopLocalBases,
            instructionBase + 7 + bodyInstructions,
            depth + 1,
            loopWindowRows,
            output
          );
          if (child.valid == false) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          bodyInstructions += child.instructionCount;
          length += child.length;
        } else {
          long nested = nestedAtStatement(statement, nestedCount, nestedRows);
          if (nested < 0) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          LoopNestedBlockPlan nestedPlan = writeLoopNestedBlockProducts(
            statement,
            statementCount,
            statementRows,
            blockCount,
            blockRows,
            bodyCount,
            bodyRows,
            callCount,
            callStatements,
            callWindowRows,
            callInstructionStarts,
            callCode,
            nestedRows[NESTED_KIND_ROW + nested],
            rebaseLocalForStatement(
              nestedRows[NESTED_CONDITION_LOCAL_ROW + nested],
              statement,
              loopCount,
              loopRows,
              loopLocalBases,
              statementRows
            ),
            nestedRows[NESTED_CONDITION_LITERAL_ROW + nested],
            nestedRows[NESTED_LOCAL_BASE_ROW + nested] + frameBiasForStatement(
              statement,
              loopCount,
              loopRows,
              statementRows
            ),
            instructionBase + 7 + bodyInstructions,
            /* publish= */ false,
            /* outputStart= */ 0,
            output
          );
          if (nestedPlan.valid == false) {
            return new NestedLoopInstructionPlan(0, 0, false);
          }

          bodyInstructions += nestedPlan.instructionCount;
          length += nestedPlan.length;
        }
      }

      offset += 1;
    }

    return new NestedLoopInstructionPlan(bodyInstructions + 8, length, true);
  }

  /// Emits one root or nested loop after a complete recursive extent pass.
  public NestedLoopInstructionPlan writeNestedLoopInstructionProduct(
    long loop,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words conditionRows,
    long statementCount,
    borrow mut words statementRows,
    long blockCount,
    borrow mut words blockRows,
    long bodyCount,
    borrow mut words bodyRows,
    long callCount,
    borrow mut words callStatements,
    borrow mut words callWindowRows,
    borrow mut words callInstructionStarts,
    borrow byteview callCode,
    long nestedCount,
    borrow mut words nestedRows,
    borrow mut words loopLocalBases,
    long instructionBase,
    long depth,
    boolean publish,
    long outputStart,
    borrow mut words loopWindowRows,
    borrow mut bytes output
  ) {
    assert(-1 < loop);
    assert(loop < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(blockCount < BLOCK_COUNT_LIMIT + 1);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(callCount < 257);
    assert(bufferLength(callStatements) == 256);
    assert(bufferLength(callWindowRows) == 768);
    assert(bufferLength(callInstructionStarts) == 256);
    assert(bufferLength(callCode) == MAX_CODE_BYTES);
    assert(nestedCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(output) == MAX_CODE_BYTES);
    NestedLoopInstructionPlan measured = measureBody(
      loop,
      loopCount,
      loopRows,
      conditionRows,
      statementCount,
      statementRows,
      blockCount,
      blockRows,
      bodyCount,
      bodyRows,
      callCount,
      callStatements,
      callWindowRows,
      callInstructionStarts,
      callCode,
      nestedCount,
      nestedRows,
      loopLocalBases,
      instructionBase,
      depth,
      loopWindowRows,
      output
    );
    if (measured.valid == false) {
      return measured;
    }

    if (publish == false) {
      return measured;
    }

    if (MAX_CODE_BYTES - outputStart < measured.length) {
      return new NestedLoopInstructionPlan(0, 0, false);
    }

    long cursor = outputStart;
    long condition = loopRows[LOOP_CONDITION_ROW + loop];
    long localBase = loopLocalBases[loop];
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

    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeSignedLittleEndian(output, cursor, loopRows[LOOP_LIMIT_ROW + loop], U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_CONST, INSTRUCTION_FORM_BINARY);
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

    long firstStatement = loopRows[LOOP_FIRST_BODY_STATEMENT_ROW + loop];
    long count = loopRows[LOOP_BODY_STATEMENT_COUNT_ROW + loop];
    long bodyInstructions = 0;
    long offset = 0;
    while (offset < count) limit 64 {
      long statement = firstStatement + offset;
      if (statementRows[STATEMENT_CHILD_COUNT_ROW + statement] == 0) {
        long body = bodyAtStatement(statement, bodyCount, bodyRows);
        if (-1 < body) {
          long next = writeLoopBodyInstructionProduct(output, cursor, body, bodyRows);
          assert(-1 < next);
          cursor = next;
          LoopBodyInstructionExtent extent = loopBodyInstructionExtent(
            bodyRows[BODY_OPCODE_ROW + body],
            bodyRows[BODY_OPERAND_ROW + body]
          );
          assert(extent.valid);
          bodyInstructions += extent.instructionCount;
        } else {
          NestedSourceCallWindow callWindow = resolveNestedSourceCallWindow(
            statement,
            callCount,
            callStatements,
            callWindowRows
          );
          assert(callWindow.valid);
          long emittedCallEnd = writeNestedSourceCallWindow(
            callWindow.call,
            callWindowRows,
            callCode,
            cursor,
            output
          );
          assert(-1 < emittedCallEnd);
          cursor = emittedCallEnd;
          bodyInstructions += callWindow.instructionCount;
        }
      } else {
        long childLoop = loopAtStatement(statement, loopCount, loopRows, statementRows);
        if (-1 < childLoop) {
          NestedLoopInstructionPlan child = writeNestedLoopInstructionProduct(
            childLoop,
            loopCount,
            loopRows,
            conditionRows,
            statementCount,
            statementRows,
            blockCount,
            blockRows,
            bodyCount,
            bodyRows,
            callCount,
            callStatements,
            callWindowRows,
            callInstructionStarts,
            callCode,
            nestedCount,
            nestedRows,
            loopLocalBases,
            instructionBase + 7 + bodyInstructions,
            depth + 1,
            true,
            cursor,
            loopWindowRows,
            output
          );
          assert(child.valid);
          bodyInstructions += child.instructionCount;
          cursor += child.length;
        } else {
          long nested = nestedAtStatement(statement, nestedCount, nestedRows);
          assert(-1 < nested);
          LoopNestedBlockPlan nestedPlan = writeLoopNestedBlockProducts(
            statement,
            statementCount,
            statementRows,
            blockCount,
            blockRows,
            bodyCount,
            bodyRows,
            callCount,
            callStatements,
            callWindowRows,
            callInstructionStarts,
            callCode,
            nestedRows[NESTED_KIND_ROW + nested],
            rebaseLocalForStatement(
              nestedRows[NESTED_CONDITION_LOCAL_ROW + nested],
              statement,
              loopCount,
              loopRows,
              loopLocalBases,
              statementRows
            ),
            nestedRows[NESTED_CONDITION_LITERAL_ROW + nested],
            nestedRows[NESTED_LOCAL_BASE_ROW + nested] + frameBiasForStatement(
              statement,
              loopCount,
              loopRows,
              statementRows
            ),
            instructionBase + 7 + bodyInstructions,
            true,
            cursor,
            output
          );
          assert(nestedPlan.valid);
          bodyInstructions += nestedPlan.instructionCount;
          cursor += nestedPlan.length;
        }
      }

      offset += 1;
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_JUMP, INSTRUCTION_FORM_UNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, instructionBase + 2, U64);
    long exitTarget = instructionBase + 8 + bodyInstructions;
    long exitCursor = writeUnsignedLittleEndian(output, exitHeader + 16, exitTarget, U64);
    assert(exitCursor == exitHeader + 24);
    assert(cursor - outputStart == measured.length);
    set(loopWindowRows, loop, outputStart);
    set(loopWindowRows, 256 + loop, measured.instructionCount);
    set(loopWindowRows, 512 + loop, measured.length);
    return measured;
  }
}
