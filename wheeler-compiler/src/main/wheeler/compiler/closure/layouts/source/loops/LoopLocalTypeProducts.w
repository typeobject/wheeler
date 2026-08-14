//! Publishes canonical local types for resolved direct loop products.

module wheeler.compiler.closure.loop_local_type_products;

import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.type_codes;

classical class LoopLocalTypeProducts {
  private const long BODY_COUNT_LIMIT = 4096;
  private const long LOOP_BODY_STATEMENT_COUNT_ROW = 1792;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_FIRST_BODY_STATEMENT_ROW = 1536;
  private const long LOOP_ROWS = 2304;
  private const long MAX_LOCALS = 256;
  private const long MAX_STATEMENTS = 4096;
  private const long STATEMENT_BLOCK_ROW = 4096;
  private const long STATEMENT_CHILD_COUNT_ROW = 24576;
  private const long STATEMENT_FIRST_CHILD_ROW = 20480;
  private const long TYPE_ROWS = 12288;
  private const long TYPE_LOCAL_ROW = 4096;
  private const long TYPE_CODE_ROW = 8192;

  /// Reports one complete loop-local type extent.
  public record LoopLocalTypePlan(long typeCount, boolean valid) {}

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

  private long bodyLocalType(long opcode, long operand, long localOffset) {
    long localType = TYPE_SIGNED;
    if (opcode == BODY_BOOLEAN_LITERAL) {
      localType = TYPE_BOOLEAN;
    }

    if (opcode == BODY_ASSERT_BOOLEAN) {
      localType = TYPE_BOOLEAN;
    }

    if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + MAX_LOCALS) {
        localType = TYPE_BOOLEAN;
      }
    }

    if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
      if (opcode < BODY_BOOLEAN_LITERAL) {
        if (localOffset == 2) {
          localType = TYPE_BOOLEAN;
        }
      }
    }

    long bufferType = TYPE_WORDS_BORROW;
    if (opcode == BODY_BYTES_GET) {
      bufferType = TYPE_BYTES_BORROW;
    }

    if (opcode == BODY_BYTES_SET) {
      bufferType = TYPE_BYTES_BORROW;
    }

    if (opcode == BODY_BYTES_COPY) {
      bufferType = TYPE_BYTES_BORROW;
    }

    if (opcode == BODY_BYTEVIEW_GET) {
      bufferType = TYPE_BYTE_VIEW;
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
        if (localOffset == 0) {
          localType = bufferType;
        }
      }
    }

    boolean bufferSet = opcode == BODY_WORDS_SET;
    if (opcode == BODY_BYTES_SET) {
      bufferSet = true;
    }

    if (bufferSet) {
      if (0 < operand / 16777216) {
        if (localOffset == 0) {
          localType = bufferType;
        }
      }
    }

    boolean bufferCopy = opcode == BODY_WORDS_COPY;
    if (opcode == BODY_BYTES_COPY) {
      bufferCopy = true;
    }

    if (bufferCopy) {
      long writeBorrowed = operand / 4294967296 % 2;
      long readBorrowed = operand / 8589934592;
      if (0 < writeBorrowed) {
        if (localOffset == 0) {
          localType = bufferType;
        }
      }

      if (0 < readBorrowed) {
        if (localOffset == writeBorrowed + 1) {
          localType = bufferType;
        }
      }
    }

    return localType;
  }

  private long appendType(borrow mut words rows, long type, long owner, long local, long code) {
    if (BODY_COUNT_LIMIT - 1 < type) {
      return -1;
    }

    if (local < 0) {
      return -1;
    }

    if (MAX_LOCALS - 1 < local) {
      return -1;
    }

    set(rows, type, owner);
    set(rows, TYPE_LOCAL_ROW + type, local);
    set(rows, TYPE_CODE_ROW + type, code);
    return type + 1;
  }

  /// Publishes exact loop-frame and direct-body local types after complete validation.
  public LoopLocalTypePlan materializeLoopLocalTypeProducts(
    long loopCount,
    borrow mut words loopRows,
    long statementCount,
    borrow mut words statementRows,
    long bodyCount,
    borrow mut words bodyRows,
    long nestedCount,
    borrow mut words nestedRows,
    borrow mut words loopLocalBases,
    borrow mut words typeRows
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(-1 < nestedCount);
    assert(nestedCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(nestedRows) == NESTED_ROWS);
    assert(bufferLength(loopLocalBases) == LOOP_COUNT_LIMIT);
    assert(bufferLength(typeRows) == TYPE_ROWS);

    region staging = new region(/* bytes= */ 98304, /* allocations= */ 1);
    words stagedTypes = allocate(staging, TYPE_ROWS);
    boolean valid = true;
    long typeCount = 0;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long owner = loopRows[loop];
      long localBase = loopLocalBases[loop];
      if (owner < 0) {
        valid = false;
      }

      if (63 < owner) {
        valid = false;
      }

      if (localBase < 0) {
        valid = false;
      }

      if (MAX_LOCALS < localBase + 5) {
        valid = false;
      }

      if (valid) {
        typeCount = appendType(stagedTypes, typeCount, owner, localBase, TYPE_SIGNED);
        typeCount = appendType(stagedTypes, typeCount, owner, localBase + 1, TYPE_SIGNED);
        typeCount = appendType(stagedTypes, typeCount, owner, localBase + 2, TYPE_SIGNED);
        typeCount = appendType(stagedTypes, typeCount, owner, localBase + 3, TYPE_SIGNED);
        typeCount = appendType(stagedTypes, typeCount, owner, localBase + 4, TYPE_BOOLEAN);
      }

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
        if (statementRows[STATEMENT_CHILD_COUNT_ROW + statement] == 0) {
          long body = bodyAtStatement(statement, bodyCount, bodyRows);
          if (body < 0) {
            valid = false;
          } else {
            long opcode = bodyRows[BODY_OPCODE_ROW + body];
            long operand = bodyRows[BODY_OPERAND_ROW + body];
            long localCount = loopBodyLocalCount(opcode, operand);
            long bodyLocalBase = bodyRows[BODY_LOCAL_BASE_ROW + body] + 5;
            if (localCount < 0) {
              valid = false;
            }

            if (MAX_LOCALS - bodyLocalBase < localCount) {
              valid = false;
            }

            long localOffset = 0;
            while (localOffset < localCount) limit 5 {
              if (valid) {
                typeCount = appendType(
                  stagedTypes,
                  typeCount,
                  owner,
                  bodyLocalBase + localOffset,
                  bodyLocalType(opcode, operand, localOffset)
                );
                if (typeCount < 0) {
                  valid = false;
                }
              }

              localOffset += 1;
            }
          }
        } else {
          long nested = nestedAtStatement(statement, nestedCount, nestedRows);
          if (nested < 0) {
            valid = false;
          } else {
            long nestedLocalBase = nestedRows[NESTED_LOCAL_BASE_ROW + nested] + 5;
            long nestedKind = nestedRows[NESTED_KIND_ROW + nested];
            long nestedLocalCount = 3;
            if (nestedKind == 3) {
              nestedLocalCount = 1;
            }

            if (MAX_LOCALS - nestedLocalBase < nestedLocalCount) {
              valid = false;
            }

            long nestedLocalOffset = 0;
            while (nestedLocalOffset < nestedLocalCount) limit 3 {
              long nestedLocalType = TYPE_SIGNED;
              if (nestedKind == 3) {
                nestedLocalType = TYPE_BOOLEAN;
              } else {
                if (nestedLocalOffset == 2) {
                  nestedLocalType = TYPE_BOOLEAN;
                }
              }

              if (valid) {
                typeCount = appendType(
                  stagedTypes,
                  typeCount,
                  owner,
                  nestedLocalBase + nestedLocalOffset,
                  nestedLocalType
                );
                if (typeCount < 0) {
                  valid = false;
                }
              }

              nestedLocalOffset += 1;
            }

            long childBlock = statementRows[STATEMENT_FIRST_CHILD_ROW + statement];
            long childStatement = 0;
            while (childStatement < statementCount) limit MAX_STATEMENTS {
              if (statementRows[STATEMENT_BLOCK_ROW + childStatement] == childBlock) {
                long childBody = bodyAtStatement(childStatement, bodyCount, bodyRows);
                if (childBody < 0) {
                  valid = false;
                } else {
                  long childOpcode = bodyRows[BODY_OPCODE_ROW + childBody];
                  long childOperand = bodyRows[BODY_OPERAND_ROW + childBody];
                  long childLocalCount = loopBodyLocalCount(childOpcode, childOperand);
                  long childLocalBase = bodyRows[BODY_LOCAL_BASE_ROW + childBody] + 5;
                  if (childLocalCount < 0) {
                    valid = false;
                  }

                  if (MAX_LOCALS - childLocalBase < childLocalCount) {
                    valid = false;
                  }

                  long childLocalOffset = 0;
                  while (childLocalOffset < childLocalCount) limit 5 {
                    if (valid) {
                      typeCount = appendType(
                        stagedTypes,
                        typeCount,
                        owner,
                        childLocalBase + childLocalOffset,
                        bodyLocalType(childOpcode, childOperand, childLocalOffset)
                      );
                      if (typeCount < 0) {
                        valid = false;
                      }
                    }

                    childLocalOffset += 1;
                  }
                }
              }

              childStatement += 1;
            }
          }
        }

        bodyOffset += 1;
      }

      loop += 1;
    }

    if (valid) {
      long row = 0;
      while (row < TYPE_ROWS) limit TYPE_ROWS {
        set(typeRows, row, stagedTypes[row]);
        row += 1;
      }
    }

    drop(stagedTypes);
    drop(staging);
    if (valid == false) {
      return new LoopLocalTypePlan(0, false);
    }

    return new LoopLocalTypePlan(typeCount, true);
  }
}
