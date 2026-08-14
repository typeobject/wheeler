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
    long bodyCount,
    borrow mut words bodyRows,
    borrow mut words loopLocalBases,
    borrow mut words typeRows
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(-1 < bodyCount);
    assert(bodyCount < BODY_COUNT_LIMIT + 1);
    assert(bufferLength(bodyRows) == BODY_ROWS);
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

      long nextLocal = localBase + 5;
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
        long body = bodyAtStatement(statement, bodyCount, bodyRows);
        if (body < 0) {
          valid = false;
        } else {
          long localCount = loopBodyLocalCount(
            bodyRows[BODY_OPCODE_ROW + body],
            bodyRows[BODY_OPERAND_ROW + body]
          );
          if (localCount < 0) {
            valid = false;
          }

          if (MAX_LOCALS - nextLocal < localCount) {
            valid = false;
          }

          long localOffset = 0;
          while (localOffset < localCount) limit 4 {
            if (valid) {
              long localType = TYPE_SIGNED;
              long bodyOpcode = bodyRows[BODY_OPCODE_ROW + body];
              if (bodyOpcode == BODY_BOOLEAN_LITERAL) {
                localType = TYPE_BOOLEAN;
              }

              if (bodyOpcode == BODY_ASSERT_BOOLEAN) {
                localType = TYPE_BOOLEAN;
              }

              if (BODY_ASSIGN_BOOLEAN_LITERAL_BASE - 1 < bodyOpcode) {
                if (bodyOpcode < BODY_ASSIGN_BOOLEAN_LOCAL_BASE + MAX_LOCALS) {
                  localType = TYPE_BOOLEAN;
                }
              }

              if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < bodyOpcode) {
                if (bodyOpcode < BODY_BOOLEAN_LITERAL) {
                  if (localOffset == 2) {
                    localType = TYPE_BOOLEAN;
                  }
                }
              }

              if (bodyOpcode == BODY_WORDS_GET) {
                if (0 < bodyRows[BODY_OPERAND_ROW + body] / 65536) {
                  if (localOffset == 0) {
                    localType = TYPE_WORDS_BORROW;
                  }
                }
              }

              if (bodyOpcode == BODY_WORDS_SET) {
                if (0 < bodyRows[BODY_OPERAND_ROW + body] / 16777216) {
                  if (localOffset == 0) {
                    localType = TYPE_WORDS_BORROW;
                  }
                }
              }

              typeCount = appendType(stagedTypes, typeCount, owner, nextLocal, localType);
              if (typeCount < 0) {
                valid = false;
              }
            }

            nextLocal += 1;
            localOffset += 1;
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
