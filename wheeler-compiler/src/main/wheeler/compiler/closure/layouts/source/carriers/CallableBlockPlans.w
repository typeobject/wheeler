//! Joins callable-local root blocks to exact source statement windows.

module wheeler.compiler.closure.callable_block_plans;

classical class CallableBlockPlans {
  private const long BLOCK_CAPACITY = 1024;
  private const long BLOCK_ROWS = 6144;
  private const long CALLABLE_CAPACITY = 64;
  private const long PLAN_ROWS = 256;
  private const long STATEMENT_CAPACITY = 4096;
  private const long STATEMENT_ROWS = 24576;

  /// Reports one complete callable-to-root-block plan table.
  public record CallableBlockPlan(long callableCount, boolean valid) {}

  /// Publishes exact root block and direct statement windows for each local callable.
  public CallableBlockPlan materializeCallableBlockPlans(
    long callableCount,
    long blockCount,
    borrow mut words blockRows,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words planRows
  ) {
    assert(-1 < callableCount);
    assert(callableCount < CALLABLE_CAPACITY + 1);
    assert(-1 < blockCount);
    assert(blockCount < BLOCK_CAPACITY + 1);
    assert(bufferLength(blockRows) == BLOCK_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < STATEMENT_CAPACITY + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(bufferLength(planRows) == PLAN_ROWS);

    region staging = new region(/* bytes= */ 2048, /* allocations= */ 1);
    words staged = allocate(staging, PLAN_ROWS);
    boolean valid = true;
    long callable = 0;
    long expectedFirstBlock = 0;
    long expectedFirstStatement = 0;
    while (callable < callableCount) limit CALLABLE_CAPACITY {
      long firstBlock = blockCount;
      long localBlockCount = 0;
      long rootCount = 0;
      long block = 0;
      while (block < blockCount) limit BLOCK_CAPACITY {
        long blockOwner = blockRows[block];
        if (blockOwner < 0) {
          valid = false;
        }

        if (callableCount < blockOwner + 1) {
          valid = false;
        }

        if (blockOwner == callable) {
          if (localBlockCount == 0) {
            firstBlock = block;
          }

          if (block != firstBlock + localBlockCount) {
            valid = false;
          }

          if (blockRows[5120 + block] != localBlockCount) {
            valid = false;
          }

          if (blockRows[2048 + block] == 0) {
            rootCount += 1;
            if (blockRows[1024 + block] + 1 != 0) {
              valid = false;
            }

            if (blockRows[5120 + block] != 0) {
              valid = false;
            }
          }

          localBlockCount += 1;
        }

        block += 1;
      }

      if (rootCount != 1) {
        valid = false;
      }

      if (firstBlock != expectedFirstBlock) {
        valid = false;
      }

      long firstStatement = statementCount;
      long localStatementCount = 0;
      long statement = 0;
      while (statement < statementCount) limit STATEMENT_CAPACITY {
        long statementOwner = statementRows[statement];
        if (statementOwner < 0) {
          valid = false;
        }

        if (callableCount < statementOwner + 1) {
          valid = false;
        }

        if (statementOwner == callable) {
          if (localStatementCount == 0) {
            firstStatement = statement;
          }

          if (statement != firstStatement + localStatementCount) {
            valid = false;
          }

          if (statementRows[4096 + statement] != 0) {
            valid = false;
          }

          if (statementRows[8192 + statement] != localStatementCount + 1) {
            valid = false;
          }

          if (statementRows[12288 + statement] != 0) {
            valid = false;
          }

          localStatementCount += 1;
        }

        statement += 1;
      }

      if (localStatementCount == 0) {
        firstStatement = expectedFirstStatement;
      }

      if (firstStatement != expectedFirstStatement) {
        valid = false;
      }

      set(staged, callable, firstBlock);
      set(staged, 64 + callable, localBlockCount);
      set(staged, 128 + callable, firstStatement);
      set(staged, 192 + callable, localStatementCount);
      expectedFirstBlock += localBlockCount;
      expectedFirstStatement += localStatementCount;
      callable += 1;
    }

    if (expectedFirstBlock != blockCount) {
      valid = false;
    }

    if (expectedFirstStatement != statementCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < PLAN_ROWS) limit PLAN_ROWS {
        set(planRows, row, staged[row]);
        row += 1;
      }
    }

    drop(staged);
    drop(staging);
    if (valid == false) {
      return new CallableBlockPlan(0, false);
    }

    return new CallableBlockPlan(callableCount, true);
  }
}
