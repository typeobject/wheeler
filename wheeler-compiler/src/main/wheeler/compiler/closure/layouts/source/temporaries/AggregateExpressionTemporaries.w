//! Publishes primitive-frontend locals for nested aggregate expressions.

module wheeler.compiler.closure.aggregate_expression_temporaries;

classical class AggregateExpressionTemporaries {
  private const long FUNCTION_LOCAL_ROWS = 64;
  private const long MAX_FUNCTIONS = 64;
  private const long MAX_LOCALS = 256;
  private const long MAX_OPERATIONS = 256;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_VALUES = 1024;
  private const long OPERATION_ROWS = 2048;
  private const long STATEMENT_ROWS = 24576;
  private const long VALUE_ROWS = 7168;

  /// Reports the complete frontend value extent and appended temporary count.
  public record AggregateExpressionTemporaryPlan(
    long valueCount,
    long temporaryCount,
    boolean valid
  ) {}

  /// Appends one local for each nested operation not already named by the frontend.
  public AggregateExpressionTemporaryPlan appendAggregateExpressionTemporaries(
    long operationCount,
    borrow mut words operationRows,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words functionLocalCounts
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(functionLocalCounts) == FUNCTION_LOCAL_ROWS);

    region staging = new region(/* bytes= */ 57856, /* allocations= */ 2);
    words stagedValues = allocate(staging, VALUE_ROWS);
    words stagedLocalCounts = allocate(staging, FUNCTION_LOCAL_ROWS);
    long row = 0;
    while (row < VALUE_ROWS) limit VALUE_ROWS {
      set(stagedValues, row, valueRows[row]);
      row += 1;
    }

    row = 0;
    while (row < FUNCTION_LOCAL_ROWS) limit FUNCTION_LOCAL_ROWS {
      set(stagedLocalCounts, row, functionLocalCounts[row]);
      row += 1;
    }

    boolean valid = true;
    long temporaryCount = 0;
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long expressionStart = operationRows[1280 + operation];
      long expressionLength = operationRows[1536 + operation];
      if (expressionStart < 0) {
        valid = false;
      }

      if (expressionLength < 1) {
        valid = false;
      }

      long selectedStatement = -1;
      long statementMatches = 0;
      long statement = 0;
      while (statement < statementCount) limit MAX_STATEMENTS {
        long statementStart = statementRows[16384 + statement];
        long statementLength = statementRows[20480 + statement];
        if (statementStart < expressionStart + 1) {
          if (expressionStart + expressionLength < statementStart + statementLength + 1) {
            selectedStatement = statement;
            statementMatches += 1;
          }
        }

        statement += 1;
      }

      if (statementMatches != 1) {
        valid = false;
      }

      long function = 0;
      if (-1 < selectedStatement) {
        function = statementRows[selectedStatement];
      }

      if (function < 0) {
        valid = false;
      }

      if (MAX_FUNCTIONS < function + 1) {
        valid = false;
      }

      long exactMatches = 0;
      long value = 0;
      while (value < valueCount + temporaryCount) limit MAX_VALUES {
        if (stagedValues[value] == function) {
          if (stagedValues[5120 + value] == expressionStart) {
            if (stagedValues[6144 + value] == expressionLength) {
              exactMatches += 1;
            }
          }
        }

        value += 1;
      }

      if (1 < exactMatches) {
        valid = false;
      }

      if (exactMatches == 0) {
        boolean nested = false;
        long owner = 0;
        while (owner < operationCount) limit MAX_OPERATIONS {
          if (owner != operation) {
            long ownerStart = operationRows[1280 + owner];
            long ownerEnd = ownerStart + operationRows[1536 + owner];
            if (ownerStart < expressionStart + 1) {
              if (expressionStart + expressionLength < ownerEnd + 1) {
                nested = true;
              }
            }
          }

          owner += 1;
        }

        if (nested == false) {
          valid = false;
        }

        long local = stagedLocalCounts[function];
        if (local < 0) {
          valid = false;
        }

        if (MAX_LOCALS < local + 1) {
          valid = false;
        }

        if (MAX_VALUES < valueCount + temporaryCount + 1) {
          valid = false;
        } else {
          long target = valueCount + temporaryCount;
          set(stagedValues, target, function);
          set(stagedValues, 1024 + target, operationRows[256 + operation]);
          set(stagedValues, 2048 + target, operationRows[512 + operation]);
          set(stagedValues, 3072 + target, local);
          if (-1 < selectedStatement) {
            set(stagedValues, 4096 + target, statementRows[8192 + selectedStatement]);
          }

          set(stagedValues, 5120 + target, expressionStart);
          set(stagedValues, 6144 + target, expressionLength);
          set(stagedLocalCounts, function, local + 1);
          temporaryCount += 1;
        }
      }

      operation += 1;
    }

    if (valid) {
      row = 0;
      while (row < VALUE_ROWS) limit VALUE_ROWS {
        set(valueRows, row, stagedValues[row]);
        row += 1;
      }

      row = 0;
      while (row < FUNCTION_LOCAL_ROWS) limit FUNCTION_LOCAL_ROWS {
        set(functionLocalCounts, row, stagedLocalCounts[row]);
        row += 1;
      }
    }

    drop(stagedLocalCounts);
    drop(stagedValues);
    drop(staging);
    if (valid == false) {
      return new AggregateExpressionTemporaryPlan(valueCount, 0, false);
    }

    return new AggregateExpressionTemporaryPlan(
      valueCount + temporaryCount,
      temporaryCount,
      true
    );
  }
}
