//! Joins one-arm nested loop blocks to canonical branch windows.

module wheeler.compiler.closure.loop_nested_block_products;

import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.opcodes;

classical class LoopNestedBlockProducts {
  private const long BLOCK_COUNT_LIMIT = 1024;
  private const long BLOCK_PARENT_ROW = 1024;
  private const long BLOCK_ROWS = 6144;
  private const long BODY_COUNT_LIMIT = 4096;
  private const long CONDITION_BOOLEAN = 3;
  private const long CONDITION_EQ_LITERAL = 1;
  private const long CONDITION_LT_LITERAL = 2;
  private const long MAX_CODE_BYTES = 262144;
  private const long MAX_STATEMENTS = 4096;
  private const long STATEMENT_BLOCK_ROW = 4096;
  private const long STATEMENT_CHILD_COUNT_ROW = 24576;
  private const long STATEMENT_FIRST_CHILD_ROW = 20480;
  private const long STATEMENT_ROWS = 28672;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one complete one-arm branch and direct child-body extent.
  public record LoopNestedBlockPlan(
    long instructionCount,
    long length,
    long childBodyCount,
    boolean valid
  ) {}

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

  private long childStatementAt(
    long childBlock,
    long offset,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long found = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[STATEMENT_BLOCK_ROW + statement] == childBlock) {
        if (found == offset) {
          selected = statement;
        }

        found += 1;
      }

      statement += 1;
    }

    return selected;
  }

  private long childStatementCount(
    long childBlock,
    long statementCount,
    borrow mut words statementRows
  ) {
    long count = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[STATEMENT_BLOCK_ROW + statement] == childBlock) {
        count += 1;
      }

      statement += 1;
    }

    return count;
  }

  /// Emits one resolved equality or less-than guard and its direct update body atomically.
  public LoopNestedBlockPlan writeLoopNestedBlockProducts(
    long parentStatement,
    long statementCount,
    borrow mut words statementRows,
    long blockCount,
    borrow mut words blockRows,
    long bodyCount,
    borrow mut words bodyRows,
    long conditionKind,
    long conditionLocal,
    long conditionLiteral,
    long conditionLocalBase,
    long instructionBase,
    boolean publish,
    long outputStart,
    borrow mut bytes output
  ) {
    assert(-1 < parentStatement);
    assert(parentStatement < statementCount);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(-1 < blockCount);
    assert(blockCount < BLOCK_COUNT_LIMIT + 1);
    assert(bufferLength(blockRows) == BLOCK_ROWS);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(-1 < instructionBase);
    assert(-1 < outputStart);
    assert(outputStart < MAX_CODE_BYTES + 1);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    boolean valid = true;
    if (conditionKind != CONDITION_EQ_LITERAL) {
      if (conditionKind != CONDITION_LT_LITERAL) {
        if (conditionKind != CONDITION_BOOLEAN) {
          valid = false;
        }
      }
    }

    if (conditionLocal < 0) {
      valid = false;
    }

    if (255 < conditionLocal) {
      valid = false;
    }

    if (conditionLocalBase < 0) {
      valid = false;
    }

    if (conditionKind == CONDITION_BOOLEAN) {
      if (255 < conditionLocalBase) {
        valid = false;
      }
    } else {
      if (253 < conditionLocalBase) {
        valid = false;
      }
    }

    long childBlock = statementRows[STATEMENT_FIRST_CHILD_ROW + parentStatement];
    if (statementRows[STATEMENT_CHILD_COUNT_ROW + parentStatement] != 1) {
      valid = false;
    }

    if (childBlock < 0) {
      valid = false;
    } else {
      if (blockCount - 1 < childBlock) {
        valid = false;
      } else {
        if (
          blockRows[BLOCK_PARENT_ROW + childBlock] != statementRows[STATEMENT_BLOCK_ROW
            + parentStatement]
        ) {
          valid = false;
        }
      }
    }

    long selectedBodyCount = 0;
    if (valid) {
      selectedBodyCount = childStatementCount(childBlock, statementCount, statementRows);
      if (selectedBodyCount < 1) {
        valid = false;
      }

      if (64 < selectedBodyCount) {
        valid = false;
      }
    }

    long bodyInstructionCount = 0;
    long bodyLength = 0;
    long childOffset = 0;
    while (childOffset < selectedBodyCount) limit 64 {
      long childStatement = childStatementAt(
        childBlock,
        childOffset,
        statementCount,
        statementRows
      );
      if (childStatement < 0) {
        valid = false;
      } else {
        if (statementRows[STATEMENT_CHILD_COUNT_ROW + childStatement] != 0) {
          valid = false;
        }

        long body = bodyAtStatement(childStatement, bodyCount, bodyRows);
        if (body < 0) {
          valid = false;
        } else {
          long opcode = bodyRows[BODY_OPCODE_ROW + body];
          LoopBodyInstructionExtent extent = loopBodyInstructionExtent(
            opcode,
            bodyRows[BODY_OPERAND_ROW + body]
          );
          if (extent.valid == false) {
            valid = false;
          } else {
            bodyInstructionCount += extent.instructionCount;
            bodyLength += extent.length;
            if (MAX_CODE_BYTES < bodyLength) {
              valid = false;
            }
          }
        }
      }

      childOffset += 1;
    }

    long guardLength = 104;
    long guardInstructionCount = 4;
    if (conditionKind == CONDITION_BOOLEAN) {
      guardLength = 48;
      guardInstructionCount = 2;
    }

    long requiredLength = guardLength + bodyLength + 16;
    long requiredInstructions = guardInstructionCount + bodyInstructionCount + 1;
    if (MAX_CODE_BYTES < requiredLength) {
      valid = false;
    }

    if (MAX_CODE_BYTES - outputStart < requiredLength) {
      valid = false;
    }

    if (valid == false) {
      return new LoopNestedBlockPlan(0, 0, 0, false);
    }

    if (publish == false) {
      return new LoopNestedBlockPlan(
        requiredInstructions,
        requiredLength,
        selectedBodyCount,
        true
      );
    }

    region staging = new region(/* bytes= */ MAX_CODE_BYTES, /* allocations= */ 1);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    long cursor = writeInstructionHeader(
      stagedCode,
      0,
      OPCODE_LOCAL_MOVE,
      INSTRUCTION_FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionLocalBase, U64);
    cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionLocal, U64);
    long conditionResult = conditionLocalBase;
    if (conditionKind != CONDITION_BOOLEAN) {
      cursor = writeInstructionHeader(
        stagedCode,
        cursor,
        OPCODE_LOCAL_CONST,
        INSTRUCTION_FORM_BINARY
      );
      cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionLocalBase + 1, U64);
      cursor = writeSignedLittleEndian(stagedCode, cursor, conditionLiteral, U64);
      long comparisonOpcode = OPCODE_LOCAL_EQ;
      if (conditionKind == CONDITION_LT_LITERAL) {
        comparisonOpcode = OPCODE_LOCAL_LT;
      }

      cursor = writeInstructionHeader(
        stagedCode,
        cursor,
        comparisonOpcode,
        INSTRUCTION_FORM_TERNARY
      );
      cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionLocalBase + 2, U64);
      cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionLocalBase, U64);
      cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionLocalBase + 1, U64);
      conditionResult = conditionLocalBase + 2;
    }

    cursor = writeInstructionHeader(
      stagedCode,
      cursor,
      OPCODE_JUMP_IF_ZERO,
      INSTRUCTION_FORM_BINARY
    );
    cursor = writeUnsignedLittleEndian(stagedCode, cursor, conditionResult, U64);
    cursor = writeUnsignedLittleEndian(
      stagedCode,
      cursor,
      instructionBase + requiredInstructions,
      U64
    );
    childOffset = 0;
    while (childOffset < selectedBodyCount) limit 64 {
      long emittedStatement = childStatementAt(
        childBlock,
        childOffset,
        statementCount,
        statementRows
      );
      long emittedBody = bodyAtStatement(emittedStatement, bodyCount, bodyRows);
      cursor = writeLoopBodyInstructionProduct(stagedCode, cursor, emittedBody, bodyRows);
      childOffset += 1;
    }

    cursor = writeInstructionHeader(stagedCode, cursor, OPCODE_JUMP, INSTRUCTION_FORM_UNARY);
    cursor = writeUnsignedLittleEndian(
      stagedCode,
      cursor,
      instructionBase + requiredInstructions,
      U64
    );
    long codeByte = 0;
    while (codeByte < cursor) limit MAX_CODE_BYTES {
      setByte(output, outputStart + codeByte, stagedCode[codeByte]);
      codeByte += 1;
    }

    drop(stagedCode);
    drop(staging);
    return new LoopNestedBlockPlan(requiredInstructions, cursor, selectedBodyCount, true);
  }
}
