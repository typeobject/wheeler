//! Plans root source-call instruction and code windows.

module wheeler.compiler.closure.source_call_instruction_products;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_call_layout_products;

classical class SourceCallInstructionProducts {
  private const long CALL_COUNT_LIMIT = 256;
  private const long DIRECT_COUNT_LIMIT = 4096;
  private const long LOOP_COUNT_LIMIT = 256;
  private const long MAX_CODE_BYTES = 262144;
  private const long STATEMENT_COUNT_LIMIT = 4096;

  /// Reports complete callable-local root-call coordinates.
  public record SourceCallInstructionPlan(
    long callCount,
    long instructionCount,
    long length,
    boolean valid
  ) {}

  private long nextCall(
    long priorStart,
    long callCount,
    borrow mut words callStatements,
    borrow mut words statementRows
  ) {
    long selected = callCount;
    long selectedStart = 32768;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long statement = callStatements[call];
      long start = statementRows[LOOP_STATEMENT_START_ROW + statement];
      if (priorStart < start) {
        if (start < selectedStart) {
          selected = call;
          selectedStart = start;
        }
      }

      call += 1;
    }

    return selected;
  }

  private boolean rootStatement(
    long statement,
    long statementCount,
    borrow mut words statementRows
  ) {
    long owner = statementRows[statement];
    return statementRows[4096 + statement] == loopBodyRootBlockForOwner(
      owner,
      statementCount,
      statementRows
    );
  }

  /// Publishes exact instruction starts and source-ordered code windows atomically.
  public SourceCallInstructionPlan materializeSourceCallInstructionProducts(
    long callCount,
    borrow mut words callRows,
    borrow mut words callStatements,
    borrow mut words callArgumentCounts,
    long statementCount,
    borrow mut words statementRows,
    long directCount,
    borrow mut words directRows,
    long loopCount,
    borrow mut words loopRows,
    borrow mut words loopWindowRows,
    borrow mut words callInstructionStarts,
    borrow mut words callWindowRows
  ) {
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == 1024);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(-1 < statementCount);
    assert(statementCount < STATEMENT_COUNT_LIMIT + 1);
    assert(bufferLength(statementRows) == 28672);
    assert(-1 < directCount);
    assert(directCount < DIRECT_COUNT_LIMIT + 1);
    assert(bufferLength(directRows) == 28672);
    assert(-1 < loopCount);
    assert(loopCount < LOOP_COUNT_LIMIT + 1);
    assert(bufferLength(loopRows) == 2304);
    assert(bufferLength(loopWindowRows) == 768);
    assert(bufferLength(callInstructionStarts) == CALL_COUNT_LIMIT);
    assert(bufferLength(callWindowRows) == 768);

    region staging = new region(/* bytes= */ 8192, /* allocations= */ 2);
    words stagedStarts = allocate(staging, CALL_COUNT_LIMIT);
    words stagedWindows = allocate(staging, /* length= */ 768);
    long retainedCall = 0;
    while (retainedCall < CALL_COUNT_LIMIT) limit CALL_COUNT_LIMIT {
      set(stagedStarts, retainedCall, callInstructionStarts[retainedCall]);
      retainedCall += 1;
    }

    boolean valid = true;
    long checkedCall = 0;
    while (checkedCall < callCount) limit CALL_COUNT_LIMIT {
      if (callStatements[checkedCall] < 0) {
        valid = false;
      } else {
        if (statementCount - 1 < callStatements[checkedCall]) {
          valid = false;
        }
      }

      checkedCall += 1;
    }

    long codeCursor = 0;
    long instructionCount = 0;
    long priorStart = -1;
    long processed = 0;
    while (processed < callCount) limit CALL_COUNT_LIMIT {
      if (valid == false) {
        processed = callCount;
      } else {
        long call = nextCall(priorStart, callCount, callStatements, statementRows);
        if (call == callCount) {
          valid = false;
          processed = callCount;
        } else {
          long statement = callStatements[call];
          if (statement < 0) {
            valid = false;
          }

          if (statementCount - 1 < statement) {
            valid = false;
          }

          boolean callIsRoot = false;
          if (valid) {
            callIsRoot = rootStatement(statement, statementCount, statementRows);
          }

          long owner = 0;
          long callStart = 0;
          if (valid) {
            owner = statementRows[statement];
            callStart = statementRows[LOOP_STATEMENT_START_ROW + statement];
            priorStart = callStart;
          }

          long instructionStart = 0;
          long direct = 0;
          while (direct < directCount) limit DIRECT_COUNT_LIMIT {
            long directStatement = directRows[direct];
            if (callIsRoot) {
              if (statementRows[directStatement] == owner) {
                if (rootStatement(directStatement, statementCount, statementRows)) {
                  if (
                    statementRows[LOOP_STATEMENT_START_ROW + directStatement] < callStart
                  ) {
                    instructionStart += directRows[8192 + direct];
                  }
                }
              }
            }

            direct += 1;
          }

          long loop = 0;
          while (loop < loopCount) limit LOOP_COUNT_LIMIT {
            if (callIsRoot) {
              if (loopRows[loop] == owner) {
                if (loopRows[2048 + loop] == 1) {
                  long loopStatement = 0;
                  long matches = 0;
                  long candidate = 0;
                  while (candidate < statementCount) limit STATEMENT_COUNT_LIMIT {
                    if (statementRows[candidate] == owner) {
                      if (statementRows[8192 + candidate] == loopRows[512 + loop]) {
                        loopStatement = candidate;
                        matches += 1;
                      }
                    }

                    candidate += 1;
                  }

                  if (matches != 1) {
                    valid = false;
                  } else {
                    if (
                      statementRows[LOOP_STATEMENT_START_ROW + loopStatement] < callStart
                    ) {
                      instructionStart += loopWindowRows[256 + loop];
                    }
                  }
                }
              }
            }

            loop += 1;
          }

          long priorCall = 0;
          while (priorCall < callCount) limit CALL_COUNT_LIMIT {
            long priorStatement = callStatements[priorCall];
            if (callIsRoot) {
              if (statementRows[priorStatement] == owner) {
                if (rootStatement(priorStatement, statementCount, statementRows)) {
                  if (
                    statementRows[LOOP_STATEMENT_START_ROW + priorStatement] < callStart
                  ) {
                    instructionStart += sourceCallInstructionCount(
                      callRows[256 + priorCall],
                      callArgumentCounts[priorCall]
                    );
                  }
                }
              }
            }

            priorCall += 1;
          }

          long selectedInstructionCount = sourceCallInstructionCount(
            callRows[256 + call],
            callArgumentCounts[call]
          );
          long selectedLength = sourceCallLength(callRows[256 + call], callArgumentCounts[call]);
          if (32767 < instructionStart) {
            valid = false;
          }

          if (MAX_CODE_BYTES - codeCursor < selectedLength) {
            valid = false;
          }

          if (callIsRoot) {
            set(stagedStarts, call, instructionStart);
          }

          set(stagedWindows, call, codeCursor);
          set(stagedWindows, 256 + call, selectedInstructionCount);
          set(stagedWindows, 512 + call, selectedLength);
          instructionCount += selectedInstructionCount;
          codeCursor += selectedLength;
          processed += 1;
        }
      }
    }

    if (valid) {
      long row = 0;
      while (row < CALL_COUNT_LIMIT) limit CALL_COUNT_LIMIT {
        set(callInstructionStarts, row, stagedStarts[row]);
        row += 1;
      }

      row = 0;
      while (row < 768) limit 768 {
        set(callWindowRows, row, stagedWindows[row]);
        row += 1;
      }
    }

    drop(stagedWindows);
    drop(stagedStarts);
    drop(staging);
    return new SourceCallInstructionPlan(callCount, instructionCount, codeCursor, valid);
  }
}
