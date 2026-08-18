//! Measures typed call locals before callable coordinate publication.

module wheeler.compiler.closure.source_call_layout_products;

import wheeler.compiler.type_codes;

classical class SourceCallLayoutProducts {
  private const long ARGUMENT_COUNT_LIMIT = 1792;
  private const long ARGUMENT_TYPE_ROW = 1792;
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_ROWS = 1024;
  private const long CALL_VOID = 0;
  /// Names a Boolean helper call guarding an exact `return false;` child.
  public const long CALL_CONDITION_FALSE_BOOLEAN = 5;
  /// Names a Boolean helper call guarding an exact `return true;` child.
  public const long CALL_CONDITION_TRUE_BOOLEAN = 6;
  /// Names a Boolean helper call guarding an exact signed-constant return.
  public const long CALL_CONDITION_SIGNED_CONSTANT = 7;
  /// Names a Boolean helper call guarding an exact signed-literal return.
  public const long CALL_CONDITION_SIGNED_LITERAL = 8;
  private const long CALL_FORWARD_BOOLEAN = 4;
  private const long CALL_FORWARD_SIGNED = 3;
  private const long CALL_VALUE_BOOLEAN = 2;
  private const long CALL_VALUE_SIGNED = 1;
  private const long MAX_ARGUMENTS_PER_CALL = 7;
  private const long MAX_SIGNATURE_TYPES = 4096;
  private const long MAX_STATEMENTS = 4096;

  /// Reports one complete call-kind and physical-width product set.
  public record SourceCallLayoutPlan(long callCount, long localTypeCount, boolean valid) {}

  /// Reports whether a call result kind has a canonical encoding.
  public boolean validSourceCallKind(long kind) {
    if (kind == CALL_VOID) {
      return true;
    }

    if (kind == CALL_VALUE_SIGNED) {
      return true;
    }

    if (kind == CALL_VALUE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_FORWARD_SIGNED) {
      return true;
    }

    if (kind == CALL_FORWARD_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_FALSE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_TRUE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_SIGNED_CONSTANT) {
      return true;
    }

    return kind == CALL_CONDITION_SIGNED_LITERAL;
  }

  /// Reports whether one call condition returns a signed child value.
  public boolean sourceCallReturnsSignedChild(long kind) {
    if (kind == CALL_CONDITION_SIGNED_CONSTANT) {
      return true;
    }

    return kind == CALL_CONDITION_SIGNED_LITERAL;
  }

  /// Reports whether one Boolean call result controls an exact return child.
  public boolean sourceCallConditionsResult(long kind) {
    if (kind == CALL_CONDITION_FALSE_BOOLEAN) {
      return true;
    }

    if (kind == CALL_CONDITION_TRUE_BOOLEAN) {
      return true;
    }

    return sourceCallReturnsSignedChild(kind);
  }

  /// Reports whether one value call returns its result directly.
  public boolean sourceCallForwardsResult(long kind) {
    if (kind == CALL_FORWARD_SIGNED) {
      return true;
    }

    return kind == CALL_FORWARD_BOOLEAN;
  }

  /// Returns the exact instruction count for one typed call.
  public long sourceCallInstructionCount(long kind, long arity) {
    assert(validSourceCallKind(kind));
    assert(-1 < arity);
    assert(arity < MAX_ARGUMENTS_PER_CALL + 1);
    if (kind == CALL_VOID) {
      if (arity == 0) {
        return 1;
      }

      return arity * 2 + 1;
    }

    if (sourceCallConditionsResult(kind)) {
      return arity * 2 + 5;
    }

    return arity * 2 + 2;
  }

  /// Returns the exact encoded byte length for one typed call.
  public long sourceCallLength(long kind, long arity) {
    assert(validSourceCallKind(kind));
    assert(-1 < arity);
    assert(arity < MAX_ARGUMENTS_PER_CALL + 1);
    if (kind == CALL_VOID) {
      if (arity == 0) {
        return 16;
      }

      return arity * 48 + 32;
    }

    if (sourceCallForwardsResult(kind)) {
      return arity * 48 + 56;
    }

    if (sourceCallConditionsResult(kind)) {
      return arity * 48 + 120;
    }

    return arity * 48 + 64;
  }

  /// Returns the exact physical local width for one typed call.
  public long sourceCallLocalCount(long kind, long arity) {
    assert(validSourceCallKind(kind));
    assert(-1 < arity);
    assert(arity < MAX_ARGUMENTS_PER_CALL + 1);
    if (kind == CALL_VOID) {
      return arity * 2;
    }

    if (sourceCallForwardsResult(kind)) {
      return arity * 2 + 1;
    }

    if (sourceCallConditionsResult(kind)) {
      return arity * 2 + 1;
    }

    return arity * 2 + 2;
  }

  /// Validates and publishes exact typed call-statement widths atomically.
  public SourceCallLayoutPlan materializeSourceCallLayoutProducts(
    long callCount,
    borrow mut words sourceCalls,
    borrow mut words callStatements,
    borrow mut words callArgumentStarts,
    borrow mut words callArgumentCounts,
    borrow mut words arguments,
    long targetCount,
    borrow mut words targetParameterStarts,
    borrow mut words targetParameterCounts,
    borrow mut words targetParameterTypes,
    borrow mut words targetResultTypes,
    borrow mut words statementRows,
    borrow mut words statementPhysicalWidths,
    borrow mut words resolvedCalls,
    borrow mut words callLocalWidths
  ) {
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(sourceCalls) == CALL_ROWS);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentStarts) == CALL_COUNT_LIMIT);
    assert(bufferLength(callArgumentCounts) == CALL_COUNT_LIMIT);
    assert(bufferLength(arguments) == 3584);
    assert(-1 < targetCount);
    assert(targetCount < MAX_SIGNATURE_TYPES + 1);
    assert(bufferLength(targetParameterStarts) == MAX_SIGNATURE_TYPES);
    assert(bufferLength(targetParameterCounts) == MAX_SIGNATURE_TYPES);
    assert(bufferLength(targetParameterTypes) == 16384);
    assert(bufferLength(targetResultTypes) == MAX_SIGNATURE_TYPES);
    assert(bufferLength(statementRows) == 28672);
    assert(bufferLength(statementPhysicalWidths) == MAX_STATEMENTS);
    assert(bufferLength(resolvedCalls) == CALL_ROWS);
    assert(bufferLength(callLocalWidths) == CALL_COUNT_LIMIT);

    region staging = new region(/* bytes= */ 43008, /* allocations= */ 3);
    words stagedCalls = allocate(staging, CALL_ROWS);
    words stagedWidths = allocate(staging, MAX_STATEMENTS);
    words stagedCallWidths = allocate(staging, CALL_COUNT_LIMIT);
    long statement = 0;
    while (statement < MAX_STATEMENTS) limit MAX_STATEMENTS {
      set(stagedWidths, statement, statementPhysicalWidths[statement]);
      statement += 1;
    }

    boolean valid = true;
    long localTypeCount = 0;
    long argumentEnd = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long target = sourceCalls[768 + call];
      long ownedStatement = callStatements[call];
      long firstArgument = callArgumentStarts[call];
      long arity = callArgumentCounts[call];
      if (target < 0) {
        valid = false;
      }

      if (targetCount - 1 < target) {
        valid = false;
      }

      if (ownedStatement < 0) {
        valid = false;
      }

      if (MAX_STATEMENTS - 1 < ownedStatement) {
        valid = false;
      }

      if (firstArgument != argumentEnd) {
        valid = false;
      }

      if (arity < 0) {
        valid = false;
      }

      if (MAX_ARGUMENTS_PER_CALL < arity) {
        valid = false;
      }

      if (ARGUMENT_COUNT_LIMIT - firstArgument < arity) {
        valid = false;
      }

      long kind = -1;
      if (-1 < target) {
        if (target < targetCount) {
          kind = targetResultTypes[target];
          if (targetParameterCounts[target] != arity) {
            valid = false;
          }
        }
      }

      if (validSourceCallKind(kind) == false) {
        valid = false;
      }

      long argument = 0;
      while (argument < arity) limit MAX_ARGUMENTS_PER_CALL {
        long expectedType = targetParameterTypes[targetParameterStarts[target] + argument];
        if (expectedType < 0) {
          valid = false;
        }

        if (arguments[ARGUMENT_TYPE_ROW + firstArgument + argument] != expectedType) {
          valid = false;
        }

        argument += 1;
      }

      if (valid) {
        long width = sourceCallLocalCount(kind, arity);
        if (statementPhysicalWidths[ownedStatement] == width - 1) {
          if (kind == CALL_VALUE_SIGNED) {
            kind = CALL_FORWARD_SIGNED;
          }

          if (kind == CALL_VALUE_BOOLEAN) {
            kind = CALL_FORWARD_BOOLEAN;
          }

          width = sourceCallLocalCount(kind, arity);
        }

        if (statementPhysicalWidths[ownedStatement] != width) {
          valid = false;
        }

        if (255 < width) {
          valid = false;
        } else {
          set(stagedWidths, ownedStatement, width);
          set(stagedCallWidths, call, width);
          set(stagedCalls, call, statementRows[ownedStatement]);
          set(stagedCalls, 256 + call, kind);
          set(stagedCalls, 512 + call, sourceCalls[call]);
          set(stagedCalls, 768 + call, target);
          localTypeCount += width;
        }
      }

      argumentEnd = firstArgument + arity;
      call += 1;
    }

    if (MAX_SIGNATURE_TYPES < localTypeCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < CALL_ROWS) limit CALL_ROWS {
        set(resolvedCalls, row, stagedCalls[row]);
        row += 1;
      }

      row = 0;
      while (row < MAX_STATEMENTS) limit MAX_STATEMENTS {
        set(statementPhysicalWidths, row, stagedWidths[row]);
        row += 1;
      }

      row = 0;
      while (row < CALL_COUNT_LIMIT) limit CALL_COUNT_LIMIT {
        set(callLocalWidths, row, stagedCallWidths[row]);
        row += 1;
      }
    }

    drop(stagedCallWidths);
    drop(stagedWidths);
    drop(stagedCalls);
    drop(staging);
    return new SourceCallLayoutPlan(callCount, localTypeCount, valid);
  }
}
