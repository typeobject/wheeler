//! Maps resolved loop-body values onto exact planned physical locals.

module wheeler.compiler.closure.physical_loop_body_products;

import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.resolved_statements;

classical class PhysicalLoopBodyProducts {
  private const long BODY_COUNT_LIMIT = 4096;
  private const long FAILURE_BODY_BOUNDS = 2;
  private const long FAILURE_BODY_OPCODE = 3;
  private const long FAILURE_BODY_PACKED_OPERAND = 4;
  private const long FAILURE_BODY_VALUE_OPERAND = 5;
  private const long FAILURE_BODY_WIDTH = 1;
  private const long FAILURE_NONE = 0;
  private const long MAX_STATEMENTS = 4096;
  private const long NESTED_COUNT_LIMIT = 4096;
  private const long OPERAND_LOCAL = 1;

  /// Reports one atomic logical-to-physical body mapping.
  public record PhysicalLoopBodyPlan(
    long bodyCount,
    long nestedCount,
    long failureBody,
    long failureNested,
    long failureCode,
    boolean valid
  ) {}

  private long statementAtOrdinal(
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] == ordinal) {
          selected = statement;
          matches += 1;
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long physicalLocal(
    long owner,
    long local,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit LOOP_VALUE_COUNT_LIMIT {
      if (valueRows[value] == owner) {
        if (valueRows[3072 + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    long ordinal = valueRows[4096 + selected];
    if (ordinal == 0) {
      return local;
    }

    long statement = statementAtOrdinal(owner, ordinal, statementCount, statementRows);
    if (statement < 0) {
      return -1;
    }

    long logicalBase = statementLocalRows[statement];
    if (local < logicalBase) {
      return -1;
    }

    return statementPhysicalStarts[statement] + local - logicalBase;
  }

  private long packedLocal(
    long owner,
    long local,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts
  ) {
    long mapped = physicalLocal(
      owner,
      local,
      statementCount,
      statementRows,
      valueCount,
      valueRows,
      statementLocalRows,
      statementPhysicalStarts
    );
    if (mapped < 0) {
      return -1;
    }

    if (255 < mapped) {
      return -1;
    }

    return mapped;
  }

  private long mappedOpcode(
    long owner,
    long opcode,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts
  ) {
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

    long mapped = packedLocal(
      owner,
      opcode - base,
      statementCount,
      statementRows,
      valueCount,
      valueRows,
      statementLocalRows,
      statementPhysicalStarts
    );
    if (mapped < 0) {
      return -1;
    }

    return base + mapped;
  }

  private long mappedBufferOperand(
    long owner,
    long opcode,
    long operand,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts
  ) {
    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
      long sumReadBorrowed = operand / 2199023255552;
      long sumWriteBorrowed = operand / 1099511627776 % 2;
      long sumTuple = operand % 1099511627776;
      long sumWriteOwner = sumTuple / 4294967296;
      long sumWriteIndex = sumTuple / 16777216 % 256;
      long sumReadOwner = sumTuple / 65536 % 256;
      long sumReadBase = sumTuple / 256 % 256;
      long sumReadIndex = sumTuple % 256;
      sumWriteOwner = packedLocal(
        owner,
        sumWriteOwner,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      sumWriteIndex = packedLocal(
        owner,
        sumWriteIndex,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      sumReadOwner = packedLocal(
        owner,
        sumReadOwner,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      sumReadBase = packedLocal(
        owner,
        sumReadBase,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      sumReadIndex = packedLocal(
        owner,
        sumReadIndex,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      boolean valid = true;
      if (sumWriteOwner < 0) {
        valid = false;
      }

      if (sumWriteIndex < 0) {
        valid = false;
      }

      if (sumReadOwner < 0) {
        valid = false;
      }

      if (sumReadBase < 0) {
        valid = false;
      }

      if (sumReadIndex < 0) {
        valid = false;
      }

      if (valid == false) {
        return -1;
      }

      return sumReadBorrowed * 2199023255552 + sumWriteBorrowed * 1099511627776 + sumWriteOwner
        * 4294967296 + sumWriteIndex * 16777216 + sumReadOwner * 65536 + sumReadBase * 256
        + sumReadIndex;
    }

    if (opcode == BODY_WORDS_GET_OFFSET) {
      long offset = operand / 131072;
      long offsetTuple = operand % 131072;
      long offsetBorrowed = offsetTuple / 65536;
      long offsetPair = offsetTuple % 65536;
      long offsetSource = packedLocal(
        owner,
        offsetPair / 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long offsetIndex = packedLocal(
        owner,
        offsetPair % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      if (offsetSource < 0) {
        return -1;
      }

      if (offsetIndex < 0) {
        return -1;
      }

      return offset * 131072 + offsetBorrowed * 65536 + offsetSource * 256 + offsetIndex;
    }

    boolean read = opcode == BODY_WORDS_GET;
    if (opcode == BODY_BYTES_GET) {
      read = true;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      read = true;
    }

    if (read) {
      long readBorrowed = operand / 65536;
      long readPair = operand % 65536;
      long readSource = packedLocal(
        owner,
        readPair / 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long readIndex = packedLocal(
        owner,
        readPair % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      if (readSource < 0) {
        return -1;
      }

      if (readIndex < 0) {
        return -1;
      }

      return readBorrowed * 65536 + readSource * 256 + readIndex;
    }

    boolean write = opcode == BODY_WORDS_SET;
    if (opcode == BODY_BYTES_SET) {
      write = true;
    }

    if (write) {
      long writeBorrowed = operand / 16777216;
      long writeTuple = operand % 16777216;
      long writeTarget = packedLocal(
        owner,
        writeTuple / 65536,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long writeIndex = packedLocal(
        owner,
        writeTuple / 256 % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long writeSource = packedLocal(
        owner,
        writeTuple % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      if (writeTarget < 0) {
        return -1;
      }

      if (writeIndex < 0) {
        return -1;
      }

      if (writeSource < 0) {
        return -1;
      }

      return writeBorrowed * 16777216 + writeTarget * 65536 + writeIndex * 256 + writeSource;
    }

    boolean copy = opcode == BODY_WORDS_COPY;
    if (opcode == BODY_BYTES_COPY) {
      copy = true;
    }

    if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
      copy = true;
    }

    if (copy) {
      long copyReadBorrowed = operand / 8589934592;
      long copyWriteBorrowed = operand / 4294967296 % 2;
      long copyTuple = operand % 4294967296;
      long copyWriteOwner = packedLocal(
        owner,
        copyTuple / 16777216,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long copyWriteIndex = packedLocal(
        owner,
        copyTuple / 65536 % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long copyReadOwner = packedLocal(
        owner,
        copyTuple / 256 % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      long copyReadIndex = packedLocal(
        owner,
        copyTuple % 256,
        statementCount,
        statementRows,
        valueCount,
        valueRows,
        statementLocalRows,
        statementPhysicalStarts
      );
      if (copyWriteOwner < 0) {
        return -1;
      }

      if (copyWriteIndex < 0) {
        return -1;
      }

      if (copyReadOwner < 0) {
        return -1;
      }

      if (copyReadIndex < 0) {
        return -1;
      }

      return copyReadBorrowed * 8589934592 + copyWriteBorrowed * 4294967296 + copyWriteOwner
        * 16777216 + copyWriteIndex * 65536 + copyReadOwner * 256 + copyReadIndex;
    }

    return operand;
  }

  /// Publishes exact physical body, nested-condition, and scratch coordinates atomically.
  public PhysicalLoopBodyPlan materializePhysicalLoopBodyProducts(
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementLocalRows,
    borrow mut words statementPhysicalStarts,
    long bodyCount,
    borrow mut words bodyRows,
    long nestedCount,
    borrow mut words nestedRows
  ) {
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < LOOP_VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);
    assert(bufferLength(statementLocalRows) == 8192);
    assert(bufferLength(statementPhysicalStarts) == MAX_STATEMENTS);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(-1 < nestedCount);
    assert(nestedCount < NESTED_COUNT_LIMIT + 1);
    assert(bufferLength(nestedRows) == NESTED_ROWS);

    region staging = new region(/* bytes= */ 360448, /* allocations= */ 3);
    words stagedBodies = allocate(staging, BODY_ROWS);
    words stagedNested = allocate(staging, NESTED_ROWS);
    words stagedPhysicalStarts = allocate(staging, MAX_STATEMENTS);
    long row = 0;
    while (row < BODY_ROWS) limit BODY_ROWS {
      set(stagedBodies, row, bodyRows[row]);
      set(stagedNested, row, nestedRows[row]);
      row += 1;
    }

    row = 0;
    while (row < MAX_STATEMENTS) limit MAX_STATEMENTS {
      set(stagedPhysicalStarts, row, statementPhysicalStarts[row]);
      row += 1;
    }

    boolean valid = true;
    long failureBody = -1;
    long failureNested = -1;
    long failureCode = FAILURE_NONE;
    long plannedBody = 0;
    while (plannedBody < bodyCount) limit BODY_COUNT_LIMIT {
      long plannedStatement = stagedBodies[plannedBody];
      if (-1 < plannedStatement) {
        if (plannedStatement < statementCount) {
          long plannedOwner = statementRows[plannedStatement];
          long plannedOrdinal = statementRows[LOOP_STATEMENT_ORDINAL_ROW + plannedStatement];
          long plannedValue = -1;
          long plannedValueMatches = 0;
          long candidateValue = 0;
          while (candidateValue < valueCount) limit LOOP_VALUE_COUNT_LIMIT {
            if (valueRows[candidateValue] == plannedOwner) {
              if (valueRows[4096 + candidateValue] == plannedOrdinal) {
                plannedValue = candidateValue;
                plannedValueMatches += 1;
              }
            }

            candidateValue += 1;
          }

          if (plannedValueMatches == 1) {
            long plannedWidth = loopBodyLocalCount(
              stagedBodies[BODY_OPCODE_ROW + plannedBody],
              stagedBodies[BODY_OPERAND_ROW + plannedBody]
            );
            if (plannedWidth < 1) {
              failureBody = plannedBody;
              failureCode = FAILURE_BODY_WIDTH;
              valid = false;
            } else {
              long logicalOffset = valueRows[3072 + plannedValue]
                - statementLocalRows[plannedStatement];
              set(
                stagedPhysicalStarts,
                plannedStatement,
                statementPhysicalStarts[plannedStatement] + plannedWidth - 1 - logicalOffset
              );
            }
          }
        }
      }

      plannedBody += 1;
    }

    long body = 0;
    while (body < bodyCount) limit BODY_COUNT_LIMIT {
      boolean validBeforeBody = valid;
      long statement = stagedBodies[body];
      boolean statementValid = true;
      if (statement < 0) {
        statementValid = false;
      }

      if (statementCount - 1 < statement) {
        statementValid = false;
      }

      if (statementValid == false) {
        if (failureBody < 0) {
          failureBody = body;
          failureCode = FAILURE_BODY_BOUNDS;
        }

        valid = false;
      } else {
        long owner = statementRows[statement];
        long opcode = stagedBodies[BODY_OPCODE_ROW + body];
        long mapped = mappedOpcode(
          owner,
          opcode,
          statementCount,
          statementRows,
          valueCount,
          valueRows,
          statementLocalRows,
          stagedPhysicalStarts
        );
        if (mapped < 0) {
          if (failureBody < 0) {
            failureCode = FAILURE_BODY_OPCODE;
          }

          valid = false;
        } else {
          set(stagedBodies, BODY_OPCODE_ROW + body, mapped);
        }

        long operand = stagedBodies[BODY_OPERAND_ROW + body];
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

        if (opcode == BODY_BYTEVIEW_GET) {
          bufferOperand = true;
        }

        if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY) {
          bufferOperand = true;
        }

        if (opcode == BODY_WORDS_GET_OFFSET) {
          bufferOperand = true;
        }

        if (opcode == BODY_BYTEVIEW_TO_BYTES_COPY_SUM) {
          bufferOperand = true;
        }

        if (bufferOperand) {
          mapped = mappedBufferOperand(
            owner,
            opcode,
            operand,
            statementCount,
            statementRows,
            valueCount,
            valueRows,
            statementLocalRows,
            stagedPhysicalStarts
          );
          if (mapped < 0) {
            if (failureBody < 0) {
              failureCode = FAILURE_BODY_PACKED_OPERAND;
            }

            valid = false;
          } else {
            set(stagedBodies, BODY_OPERAND_ROW + body, mapped);
          }
        } else {
          if (stagedBodies[BODY_OPERAND_KIND_ROW + body] == OPERAND_LOCAL) {
            mapped = physicalLocal(
              owner,
              operand,
              statementCount,
              statementRows,
              valueCount,
              valueRows,
              statementLocalRows,
              stagedPhysicalStarts
            );
            if (mapped < 0) {
              if (failureBody < 0) {
                failureCode = FAILURE_BODY_VALUE_OPERAND;
              }

              valid = false;
            } else {
              set(stagedBodies, BODY_OPERAND_ROW + body, mapped);
            }
          }
        }

        set(stagedBodies, BODY_LOCAL_BASE_ROW + body, statementPhysicalStarts[statement]);
      }

      if (validBeforeBody) {
        if (valid == false) {
          if (failureBody < 0) {
            failureBody = body;
          }
        }
      }

      body += 1;
    }

    long nested = 0;
    while (nested < nestedCount) limit NESTED_COUNT_LIMIT {
      long nestedStatement = stagedNested[nested];
      boolean nestedStatementValid = true;
      if (nestedStatement < 0) {
        nestedStatementValid = false;
      }

      if (statementCount - 1 < nestedStatement) {
        nestedStatementValid = false;
      }

      if (nestedStatementValid == false) {
        if (failureNested < 0) {
          failureNested = nested;
        }

        valid = false;
      } else {
        long nestedStart = statementRows[LOOP_STATEMENT_START_ROW + nestedStatement];
        long nestedPhysicalBase = -1;
        long candidateBody = 0;
        while (candidateBody < bodyCount) limit BODY_COUNT_LIMIT {
          long candidateStatement = stagedBodies[candidateBody];
          if (statementRows[candidateStatement] == statementRows[nestedStatement]) {
            long candidateStart = statementRows[LOOP_STATEMENT_START_ROW + candidateStatement];
            if (candidateStart < nestedStart) {
              long candidateWidth = loopBodyLocalCount(
                stagedBodies[BODY_OPCODE_ROW + candidateBody],
                stagedBodies[BODY_OPERAND_ROW + candidateBody]
              );
              long candidateEnd = statementPhysicalStarts[candidateStatement] + candidateWidth;
              if (nestedPhysicalBase < candidateEnd) {
                nestedPhysicalBase = candidateEnd;
              }
            }
          }

          candidateBody += 1;
        }

        long mappedNested = physicalLocal(
          statementRows[nestedStatement],
          stagedNested[NESTED_CONDITION_LOCAL_ROW + nested],
          statementCount,
          statementRows,
          valueCount,
          valueRows,
          statementLocalRows,
          stagedPhysicalStarts
        );
        if (mappedNested < 0) {
          if (failureNested < 0) {
            failureNested = nested;
          }

          valid = false;
        }

        if (nestedPhysicalBase < 0) {
          nestedPhysicalBase = statementPhysicalStarts[nestedStatement];
        }

        if (valid) {
          set(stagedNested, NESTED_CONDITION_LOCAL_ROW + nested, mappedNested);
          set(stagedNested, NESTED_LOCAL_BASE_ROW + nested, nestedPhysicalBase);
        }
      }

      nested += 1;
    }

    if (valid) {
      row = 0;
      while (row < BODY_ROWS) limit BODY_ROWS {
        set(bodyRows, row, stagedBodies[row]);
        set(nestedRows, row, stagedNested[row]);
        row += 1;
      }

    }

    drop(stagedPhysicalStarts);
    drop(stagedNested);
    drop(stagedBodies);
    drop(staging);
    if (valid == false) {
      return new PhysicalLoopBodyPlan(0, 0, failureBody, failureNested, failureCode, false);
    }

    return new PhysicalLoopBodyPlan(bodyCount, nestedCount, -1, -1, FAILURE_NONE, true);
  }
}
