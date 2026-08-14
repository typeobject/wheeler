//! Composes callable-local direct and structured-loop instruction windows.

module wheeler.compiler.closure.callable_instruction_plans;

classical class CallableInstructionPlans {
  private const long CALLABLE_CAPACITY = 64;
  private const long CALLABLE_PLAN_ROWS = 256;
  private const long CODE_CAPACITY = 262144;
  private const long COMPOSITION_ROWS = 33024;
  private const long INSTRUCTION_CAPACITY = 65535;
  private const long STATEMENT_CAPACITY = 4096;
  private const long STATEMENT_ROWS = 28672;
  private const long WINDOW_ROWS = 20480;

  /// Reports one complete callable-local instruction composition.
  public record CallableInstructionPlan(
    long productCount,
    long instructionCount,
    long directLength,
    long loopLength,
    boolean valid
  ) {}

  /// Publishes root-statement instruction windows in exact source order.
  public CallableInstructionPlan materializeCallableInstructionPlans(
    long callableCount,
    borrow mut words callablePlanRows,
    long statementCount,
    borrow mut words statementRows,
    long windowCount,
    borrow mut words windowRows,
    borrow mut words compositionRows
  ) {
    assert(-1 < callableCount);
    assert(callableCount < CALLABLE_CAPACITY + 1);
    assert(bufferLength(callablePlanRows) == CALLABLE_PLAN_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < STATEMENT_CAPACITY + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(-1 < windowCount);
    assert(windowCount < STATEMENT_CAPACITY + 1);
    assert(bufferLength(windowRows) == WINDOW_ROWS);
    assert(bufferLength(compositionRows) == COMPOSITION_ROWS);

    region staging = new region(/* bytes= */ 264192, /* allocations= */ 1);
    words staged = allocate(staging, COMPOSITION_ROWS);
    boolean valid = true;
    long directLength = 0;
    long loopLength = 0;
    long window = 0;
    while (window < windowCount) limit STATEMENT_CAPACITY {
      long windowStatement = windowRows[window];
      long kind = windowRows[4096 + window];
      long instructionCount = windowRows[8192 + window];
      long codeStart = windowRows[12288 + window];
      long codeLength = windowRows[16384 + window];
      if (windowStatement < 0) {
        valid = false;
      } else {
        if (statementCount < windowStatement + 1) {
          valid = false;
        }
      }

      if (kind < 0) {
        valid = false;
      } else {
        if (1 < kind) {
          valid = false;
        }
      }

      if (instructionCount < 1) {
        valid = false;
      } else {
        if (INSTRUCTION_CAPACITY < instructionCount) {
          valid = false;
        }
      }

      boolean extentValid = true;
      if (codeStart < 0) {
        extentValid = false;
      }

      if (codeLength < 1) {
        extentValid = false;
      } else {
        if (CODE_CAPACITY < codeLength) {
          extentValid = false;
        } else {
          if (-1 < codeStart) {
            if (CODE_CAPACITY - codeLength < codeStart) {
              extentValid = false;
            }
          }
        }
      }

      if (extentValid == false) {
        valid = false;
      } else {
        if (kind == 0) {
          if (codeStart != directLength) {
            valid = false;
          } else {
            directLength += codeLength;
          }
        }

        if (kind == 1) {
          if (codeStart != loopLength) {
            valid = false;
          } else {
            loopLength += codeLength;
          }
        }
      }

      window += 1;
    }

    long productCount = 0;
    long totalInstructionCount = 0;
    long consumedWindows = 0;
    long expectedFirstBlock = 0;
    long expectedFirstStatement = 0;
    long callable = 0;
    while (callable < callableCount) limit CALLABLE_CAPACITY {
      long firstBlock = callablePlanRows[callable];
      long blockCount = callablePlanRows[64 + callable];
      long firstStatement = callablePlanRows[128 + callable];
      long localStatementCount = callablePlanRows[192 + callable];
      if (firstBlock != expectedFirstBlock) {
        valid = false;
      }

      if (blockCount < 1) {
        valid = false;
      }

      if (firstStatement != expectedFirstStatement) {
        valid = false;
      }

      if (localStatementCount < 0) {
        valid = false;
      } else {
        if (statementCount - expectedFirstStatement < localStatementCount) {
          valid = false;
        }
      }

      long localOffset = 0;
      while (localOffset < localStatementCount) limit STATEMENT_CAPACITY {
        long localStatement = firstStatement + localOffset;
        if (statementRows[localStatement] != callable) {
          valid = false;
        }

        long block = statementRows[4096 + localStatement];
        if (block < firstBlock) {
          valid = false;
        } else {
          if (firstBlock + blockCount < block + 1) {
            valid = false;
          }
        }

        localOffset += 1;
      }

      long rootStatementCount = 0;
      long statement = 0;
      while (statement < statementCount) limit STATEMENT_CAPACITY {
        if (statementRows[statement] == callable) {
          if (statementRows[4096 + statement] == firstBlock) {
            rootStatementCount += 1;
          }
        }

        statement += 1;
      }

      set(staged, 32768 + callable, productCount);
      set(staged, 32832 + callable, rootStatementCount);
      long callableInstructionCount = 0;
      long priorOrdinal = -1;
      long rootOffset = 0;
      while (rootOffset < rootStatementCount) limit STATEMENT_CAPACITY {
        long selected = statementCount;
        long selectedOrdinal = statementCount + 1;
        statement = 0;
        while (statement < statementCount) limit STATEMENT_CAPACITY {
          if (statementRows[statement] == callable) {
            if (statementRows[4096 + statement] == firstBlock) {
              long ordinal = statementRows[8192 + statement];
              if (priorOrdinal < ordinal) {
                if (ordinal < selectedOrdinal) {
                  selected = statement;
                  selectedOrdinal = ordinal;
                }
              }
            }
          }

          statement += 1;
        }

        if (selected == statementCount) {
          valid = false;
        } else {
          long selectedWindow = windowCount;
          long matches = 0;
          window = 0;
          while (window < windowCount) limit STATEMENT_CAPACITY {
            if (windowRows[window] == selected) {
              selectedWindow = window;
              matches += 1;
            }

            window += 1;
          }

          if (matches != 1) {
            valid = false;
          } else {
            long selectedInstructionCount = windowRows[8192 + selectedWindow];
            boolean instructionExtentValid = 0 < selectedInstructionCount;
            if (instructionExtentValid) {
              if (
                INSTRUCTION_CAPACITY - callableInstructionCount < selectedInstructionCount
              ) {
                instructionExtentValid = false;
              }
            }

            if (instructionExtentValid == false) {
              valid = false;
            } else {
              set(staged, productCount, callable);
              set(staged, 4096 + productCount, selected);
              set(staged, 8192 + productCount, windowRows[4096 + selectedWindow]);
              set(staged, 12288 + productCount, selectedWindow);
              set(staged, 16384 + productCount, callableInstructionCount);
              set(staged, 20480 + productCount, selectedInstructionCount);
              set(staged, 24576 + productCount, windowRows[12288 + selectedWindow]);
              set(staged, 28672 + productCount, windowRows[16384 + selectedWindow]);
              callableInstructionCount += selectedInstructionCount;
              totalInstructionCount += selectedInstructionCount;
              productCount += 1;
            }

            consumedWindows += 1;
          }

          priorOrdinal = selectedOrdinal;
        }

        rootOffset += 1;
      }

      set(staged, 32896 + callable, callableInstructionCount);
      set(staged, 32960 + callable, productCount);
      expectedFirstBlock += blockCount;
      expectedFirstStatement += localStatementCount;
      callable += 1;
    }

    if (expectedFirstStatement != statementCount) {
      valid = false;
    }

    if (consumedWindows != windowCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < COMPOSITION_ROWS) limit COMPOSITION_ROWS {
        set(compositionRows, row, staged[row]);
        row += 1;
      }
    }

    drop(staged);
    drop(staging);
    if (valid == false) {
      return new CallableInstructionPlan(0, 0, 0, 0, false);
    }

    return new CallableInstructionPlan(
      productCount,
      totalInstructionCount,
      directLength,
      loopLength,
      true
    );
  }
}
