//! Publishes exact root-product instruction prefixes for source loops.

module wheeler.compiler.closure.callable_instruction_prefixes;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.source_call_layout_products;

classical class CallableInstructionPrefixes {
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_ROWS = 1024;
  private const long DIRECT_COUNT_LIMIT = 4096;
  private const long DIRECT_ROWS = 28672;
  private const long DIRECT_INSTRUCTION_COUNT_ROW = 8192;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_ROWS = 2304;
  private const long LOOP_STATEMENT_ORDINAL_ROW = 512;
  private const long STATEMENT_COUNT_LIMIT = 4096;
  private const long STATEMENT_ORDINAL_ROW = 8192;
  private const long STATEMENT_SOURCE_START_ROW = 12288;
  private const long STATEMENT_SOURCE_LENGTH_ROW = 16384;

  /// Reports one complete source-ordered loop instruction-prefix product.
  public record CallableInstructionPrefixPlan(long loopCount, boolean valid) {}

  private long statementForLoop(
    long loop,
    long loopCount,
    borrow mut words loopRows,
    long statementCount,
    borrow mut words statementRows
  ) {
    assert(-1 < loop);
    assert(loop < loopCount);
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit STATEMENT_COUNT_LIMIT {
      if (statementRows[statement] == loopRows[loop]) {
        if (
          statementRows[STATEMENT_ORDINAL_ROW + statement] == loopRows[LOOP_STATEMENT_ORDINAL_ROW
            + loop]
        ) {
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

  private boolean rootProductStatement(
    long directStatement,
    long loopCount,
    borrow mut words loopRows,
    long statementCount,
    borrow mut words statementRows
  ) {
    long owner = statementRows[directStatement];
    long directStart = statementRows[STATEMENT_SOURCE_START_ROW + directStatement];
    long directEnd = directStart + statementRows[STATEMENT_SOURCE_LENGTH_ROW + directStatement];
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      if (loopRows[loop] == owner) {
        long loopStatement = statementForLoop(
          loop,
          loopCount,
          loopRows,
          statementCount,
          statementRows
        );
        if (-1 < loopStatement) {
          long loopStart = statementRows[STATEMENT_SOURCE_START_ROW + loopStatement];
          long loopEnd = loopStart + statementRows[STATEMENT_SOURCE_LENGTH_ROW + loopStatement];
          if (loopStart < directStart + 1) {
            if (directEnd < loopEnd + 1) {
              return false;
            }
          }
        }
      }

      loop += 1;
    }

    return true;
  }

  /// Publishes each loop's exact preceding root direct-and-call instruction count atomically.
  public CallableInstructionPrefixPlan materializeCallableInstructionPrefixes(
    long loopCount,
    borrow mut words loopRows,
    long statementCount,
    borrow mut words statementRows,
    long directCount,
    borrow mut words directRows,
    long callCount,
    borrow mut words callRows,
    borrow mut words callStatements,
    borrow mut words callArgumentCounts,
    borrow mut words loopInstructionStarts
  ) {
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == LOOP_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < STATEMENT_COUNT_LIMIT + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < directCount);
    assert(directCount < DIRECT_COUNT_LIMIT + 1);
    assert(bufferLength(directRows) == DIRECT_ROWS);
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(bufferLength(loopInstructionStarts) == LOOP_COUNT_LIMIT);

    region staging = new region(/* bytes= */ 2048, /* allocations= */ 1);
    words stagedStarts = allocate(staging, LOOP_COUNT_LIMIT);
    boolean valid = true;
    long loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      long loopStatement = statementForLoop(
        loop,
        loopCount,
        loopRows,
        statementCount,
        statementRows
      );
      if (loopStatement < 0) {
        valid = false;
      }

      long prefix = 0;
      if (-1 < loopStatement) {
        long owner = statementRows[loopStatement];
        long loopStart = statementRows[STATEMENT_SOURCE_START_ROW + loopStatement];
        long direct = 0;
        while (direct < directCount) limit DIRECT_COUNT_LIMIT {
          long directStatement = directRows[direct];
          if (statementRows[directStatement] == owner) {
            if (
              rootProductStatement(
                directStatement,
                loopCount,
                loopRows,
                statementCount,
                statementRows
              )
            ) {
              if (
                statementRows[STATEMENT_SOURCE_START_ROW + directStatement] < loopStart
              ) {
                prefix += directRows[DIRECT_INSTRUCTION_COUNT_ROW + direct];
                if (32767 < prefix) {
                  valid = false;
                }
              }
            }
          }

          direct += 1;
        }

        long call = 0;
        while (call < callCount) limit CALL_COUNT_LIMIT {
          long callStatement = callStatements[call];
          if (callStatement < 0) {
            valid = false;
          } else {
            if (statementCount - 1 < callStatement) {
              valid = false;
            } else {
              if (statementRows[callStatement] == owner) {
                if (
                  rootProductStatement(
                    callStatement,
                    loopCount,
                    loopRows,
                    statementCount,
                    statementRows
                  )
                ) {
                  if (
                    statementRows[STATEMENT_SOURCE_START_ROW + callStatement] < loopStart
                  ) {
                    prefix += sourceCallInstructionCount(
                      callRows[256 + call],
                      callArgumentCounts[call]
                    );
                    if (32767 < prefix) {
                      valid = false;
                    }
                  }
                }
              }
            }
          }

          call += 1;
        }
      }

      set(stagedStarts, loop, prefix);
      loop += 1;
    }

    if (valid == false) {
      drop(stagedStarts);
      drop(staging);
      return new CallableInstructionPrefixPlan(0, false);
    }

    loop = 0;
    while (loop < loopCount) limit LOOP_COUNT_LIMIT {
      set(loopInstructionStarts, loop, stagedStarts[loop]);
      loop += 1;
    }

    drop(stagedStarts);
    drop(staging);
    return new CallableInstructionPrefixPlan(loopCount, true);
  }
}
