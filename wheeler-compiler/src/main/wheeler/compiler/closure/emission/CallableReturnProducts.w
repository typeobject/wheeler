//! Plans canonical implicit void returns after all source-backed callable products.

module wheeler.compiler.closure.callable_return_products;

import wheeler.compiler.closure.source_call_layout_products;

classical class CallableReturnProducts {
  private const long CALLABLE_LIMIT = 64;
  private const long CALL_COUNT_LIMIT = 256;
  private const long DIRECT_INSTRUCTION_COUNT_ROW = 8192;
  private const long DIRECT_LENGTH_ROW = 16384;
  private const long DIRECT_LIMIT = 4096;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long LOOP_DEPTH_ROW = 2048;
  private const long LOOP_INSTRUCTION_COUNT_ROW = 256;
  private const long LOOP_LENGTH_ROW = 512;
  private const long STATEMENT_COUNT_LIMIT = 4096;

  /// Reports atomic implicit-return coordinate publication.
  public record CallableReturnPlan(long returnCount, boolean valid) {}

  /// Publishes required bits and callable-local instruction and code starts.
  public CallableReturnPlan materializeCallableReturnProducts(
    long callableCount,
    borrow mut words functionResultTypes,
    long statementCount,
    borrow mut words statementRows,
    long directCount,
    borrow mut words directRows,
    long callCount,
    borrow mut words callRows,
    borrow mut words callStatements,
    borrow mut words callArgumentCounts,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words loopWindowRows,
    borrow mut words returnRows
  ) {
    assert(-1 < callableCount);
    assert(callableCount < CALLABLE_LIMIT + 1);
    assert(bufferLength(functionResultTypes) == CALLABLE_LIMIT);
    assert(-1 < statementCount);
    assert(statementCount < STATEMENT_COUNT_LIMIT + 1);
    assert(bufferLength(statementRows) == 28672);
    assert(-1 < directCount);
    assert(directCount < DIRECT_LIMIT + 1);
    assert(bufferLength(directRows) == 28672);
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == 1024);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == 2304);
    assert(bufferLength(loopWindowRows) == 768);
    assert(bufferLength(returnRows) == 192);

    region staging = new region(/* bytes= */ 1536, /* allocations= */ 1);
    words staged = allocate(staging, /* length= */ 192);
    boolean valid = true;
    long returnCount = 0;
    long callable = 0;
    while (callable < callableCount) limit CALLABLE_LIMIT {
      long instructionStart = 0;
      long codeStart = 0;
      long direct = 0;
      while (direct < directCount) limit DIRECT_LIMIT {
        long statement = directRows[direct];
        if (statement < 0) {
          valid = false;
        } else {
          if (statementCount - 1 < statement) {
            valid = false;
          } else {
            if (statementRows[statement] == callable) {
              long directInstructions = directRows[DIRECT_INSTRUCTION_COUNT_ROW + direct];
              long directLength = directRows[DIRECT_LENGTH_ROW + direct];
              if (directInstructions < 1) {
                valid = false;
              }

              if (directLength < 1) {
                valid = false;
              }

              instructionStart += directInstructions;
              codeStart += directLength;
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
            if (statementRows[callStatement] == callable) {
              instructionStart += sourceCallInstructionCount(
                callRows[256 + call],
                callArgumentCounts[call]
              );
              codeStart += sourceCallLength(callRows[256 + call], callArgumentCounts[call]);
            }
          }
        }

        call += 1;
      }

      long loop = 0;
      while (loop < loopCount) limit LOOP_COUNT_LIMIT {
        if (loopRows[LOOP_DEPTH_ROW + loop] == 1) {
          if (loopRows[loop] == callable) {
            long loopInstructions = loopWindowRows[LOOP_INSTRUCTION_COUNT_ROW + loop];
            long loopLength = loopWindowRows[LOOP_LENGTH_ROW + loop];
            if (loopInstructions < 1) {
              valid = false;
            }

            if (loopLength < 1) {
              valid = false;
            }

            instructionStart += loopInstructions;
            codeStart += loopLength;
          }
        }

        loop += 1;
      }

      if (32767 < instructionStart) {
        valid = false;
      }

      if (262144 < codeStart) {
        valid = false;
      }

      if (functionResultTypes[callable] == 0) {
        set(staged, callable, 1);
        set(staged, 64 + callable, instructionStart);
        set(staged, 128 + callable, codeStart);
        returnCount += 1;
      } else {
        set(staged, callable, 0);
        set(staged, 64 + callable, -1);
        set(staged, 128 + callable, -1);
      }

      callable += 1;
    }

    if (valid) {
      long row = 0;
      while (row < 192) limit 192 {
        set(returnRows, row, staged[row]);
        row += 1;
      }
    }

    drop(staged);
    drop(staging);
    if (valid == false) {
      return new CallableReturnPlan(0, false);
    }

    return new CallableReturnPlan(returnCount, true);
  }
}
