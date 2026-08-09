//! Publishes bounded primitive-frontend values and statement coordinates.

module wheeler.compiler.closure.primitive_frontend_products;

import wheeler.compiler.local_opcodes;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.statements;

classical class PrimitiveFrontendProducts {
  private const long MAX_FUNCTIONS = 64;
  private const long MAX_LOCALS = 256;
  private const long MAX_PARAMETERS = 64;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_STATEMENTS_PER_FUNCTION = 64;
  private const long MAX_VALUES = 1024;
  private const long PARAMETER_ROWS = 256;
  private const long SPLICE_ROWS = 64;
  private const long STATEMENT_ROWS = 24576;
  private const long TOKEN_ROWS = 4096;
  private const long VALUE_ROWS = 7168;

  /// Reports appended value and statement extents without source allocation identity.
  public record PrimitiveFrontendProductPlan(
    long valueCount,
    long statementCount,
    long localCount,
    boolean valid
  ) {}

  private boolean sourceRangeValid(borrow utf8 source, long start, long length) {
    if (start < 0) {
      return false;
    }

    if (length < 1) {
      return false;
    }

    if (bufferLength(source) < start) {
      return false;
    }

    return length < bufferLength(source) - start + 1;
  }

  /// Appends one function's parameter, result-value, and statement products atomically.
  public PrimitiveFrontendProductPlan appendPrimitiveFrontendProducts(
    borrow utf8 source,
    long function,
    long direction,
    long parameterCount,
    borrow mut words parameterNameStarts,
    borrow mut words parameterNameLengths,
    borrow mut words parameterLocals,
    long statementCount,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    borrow mut words spliceOrdinals,
    long firstStatementLocal,
    long valueCount,
    long frontendStatementCount,
    borrow mut words valueRows,
    borrow mut words statementRows
  ) {
    assert(-1 < function);
    assert(function < MAX_FUNCTIONS);
    assert(-1 < direction);
    assert(direction < 2);
    assert(-1 < parameterCount);
    assert(parameterCount < MAX_PARAMETERS + 1);
    assert(bufferLength(parameterNameStarts) == PARAMETER_ROWS);
    assert(bufferLength(parameterNameLengths) == PARAMETER_ROWS);
    assert(bufferLength(parameterLocals) == PARAMETER_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS_PER_FUNCTION + 1);
    assert(bufferLength(tokenKinds) == TOKEN_ROWS);
    assert(bufferLength(tokenStarts) == TOKEN_ROWS);
    assert(bufferLength(tokenLengths) == TOKEN_ROWS);
    assert(bufferLength(statementStarts) == MAX_STATEMENTS_PER_FUNCTION);
    assert(bufferLength(spliceOrdinals) == SPLICE_ROWS);
    assert(-1 < firstStatementLocal);
    assert(firstStatementLocal < MAX_LOCALS + 1);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(-1 < frontendStatementCount);
    assert(frontendStatementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    if (parameterCount < MAX_VALUES - valueCount + 1) {} else {
      return new PrimitiveFrontendProductPlan(
        valueCount,
        frontendStatementCount,
        firstStatementLocal,
        false
      );
    }

    if (statementCount < MAX_STATEMENTS - frontendStatementCount + 1) {} else {
      return new PrimitiveFrontendProductPlan(
        valueCount,
        frontendStatementCount,
        firstStatementLocal,
        false
      );
    }

    region staging = new region(/* bytes= */ 253952, /* allocations= */ 2);
    words stagedValues = allocate(staging, VALUE_ROWS);
    words stagedStatements = allocate(staging, STATEMENT_ROWS);
    boolean valid = true;
    long appendedValues = 0;
    long parameter = 0;
    while (parameter < parameterCount) limit MAX_PARAMETERS {
      long nameStart = parameterNameStarts[parameter];
      long nameLength = parameterNameLengths[parameter];
      long local = parameterLocals[parameter];
      if (sourceRangeValid(source, nameStart, nameLength) == false) {
        valid = false;
      }

      if (local < 0) {
        valid = false;
      }

      if (MAX_LOCALS < local + 1) {
        valid = false;
      }

      long target = valueCount + appendedValues;
      set(stagedValues, target, function);
      set(stagedValues, 1024 + target, nameStart);
      set(stagedValues, 2048 + target, nameLength);
      set(stagedValues, 3072 + target, local);
      set(stagedValues, 4096 + target, 0);
      set(stagedValues, 5120 + target, nameStart);
      set(stagedValues, 6144 + target, nameLength);
      appendedValues += 1;
      parameter += 1;
    }

    long localBase = firstStatementLocal;
    long statement = 0;
    long previousSplice = -1;
    while (statement < statementCount) limit MAX_STATEMENTS_PER_FUNCTION {
      long statementToken = statementStarts[statement];
      if (statementToken < 0) {
        valid = false;
      }

      if (TOKEN_ROWS < statementToken + 1) {
        valid = false;
      }

      long width = 0;
      if (valid) {
        width = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, statementToken);
      }

      if (width < 1) {
        valid = false;
      }

      long statementStart = 0;
      long statementLength = 0;
      long sourceOpcode = -1;
      if (valid) {
        long endToken = statementToken + width - 1;
        if (TOKEN_ROWS < endToken + 1) {
          valid = false;
        } else {
          statementStart = tokenStarts[statementToken];
          statementLength = tokenStarts[endToken] + tokenLengths[endToken] - statementStart;
          if (sourceRangeValid(source, statementStart, statementLength) == false) {
            valid = false;
          }

          sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementToken);
          if (sourceOpcode < 0) {
            valid = false;
          }
        }
      }

      long splice = spliceOrdinals[statement];
      if (splice < 0) {
        valid = false;
      }

      if (splice < previousSplice) {
        valid = false;
      }

      previousSplice = splice;
      long statementTarget = frontendStatementCount + statement;
      set(stagedStatements, statementTarget, function);
      set(stagedStatements, 4096 + statementTarget, direction);
      set(stagedStatements, 8192 + statementTarget, statement + 1);
      set(stagedStatements, 12288 + statementTarget, splice);
      set(stagedStatements, 16384 + statementTarget, statementStart);
      set(stagedStatements, 20480 + statementTarget, statementLength);

      long resultLocal = -1;
      long localWidth = 0;
      if (-1 < sourceOpcode) {
        resultLocal = statementResultLocal(sourceOpcode, localBase);
        localWidth = statementLocalCount(sourceOpcode);
        if (localWidth < 0) {
          valid = false;
        }
      }

      if (-1 < resultLocal) {
        if (MAX_LOCALS < resultLocal + 1) {
          valid = false;
        }

        if (MAX_VALUES < valueCount + appendedValues + 1) {
          valid = false;
        } else {
          long nameToken = statementToken + 1;
          if (tokenKinds[nameToken] != 1) {
            valid = false;
          }

          long valueTarget = valueCount + appendedValues;
          set(stagedValues, valueTarget, function);
          set(stagedValues, 1024 + valueTarget, tokenStarts[nameToken]);
          set(stagedValues, 2048 + valueTarget, tokenLengths[nameToken]);
          set(stagedValues, 3072 + valueTarget, resultLocal);
          set(stagedValues, 4096 + valueTarget, statement + 1);
          set(stagedValues, 5120 + valueTarget, statementStart);
          set(stagedValues, 6144 + valueTarget, statementLength);
          appendedValues += 1;
        }
      }

      localBase += localWidth;
      if (MAX_LOCALS < localBase) {
        valid = false;
      }

      statement += 1;
    }

    if (valid) {
      long publishedValue = valueCount;
      while (publishedValue < valueCount + appendedValues) limit MAX_VALUES {
        long valueColumn = 0;
        while (valueColumn < 7) limit 7 {
          set(
            valueRows,
            valueColumn * 1024 + publishedValue,
            stagedValues[valueColumn * 1024 + publishedValue]
          );
          valueColumn += 1;
        }

        publishedValue += 1;
      }

      long publishedStatement = frontendStatementCount;
      while (publishedStatement < frontendStatementCount + statementCount) limit MAX_STATEMENTS {
        long statementColumn = 0;
        while (statementColumn < 6) limit 6 {
          set(
            statementRows,
            statementColumn * 4096 + publishedStatement,
            stagedStatements[statementColumn * 4096 + publishedStatement]
          );
          statementColumn += 1;
        }

        publishedStatement += 1;
      }
    }

    drop(stagedStatements);
    drop(stagedValues);
    drop(staging);
    return new PrimitiveFrontendProductPlan(
      valueCount + appendedValues,
      frontendStatementCount + statementCount,
      localBase,
      valid
    );
  }
}
