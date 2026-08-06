//! Classifies resolved scalar helper returns that forward one call result.

module wheeler.compiler.resolved_return_call_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedReturnCallKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RESOLVED_SOURCE_SQUARE = 65536;
  private const long RETURN_HELPER_CALL_END = STATEMENT_RETURN_HELPER_CALL_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long RETURN_HELPER_CALL_TWO_END = STATEMENT_RETURN_HELPER_CALL_TWO_BASE
    + RESOLVED_SOURCE_COUNT * RESOLVED_SOURCE_COUNT;
  private const long RETURN_HELPER_CALL_THREE_END = STATEMENT_RETURN_HELPER_CALL_THREE_BASE
    + RESOLVED_SOURCE_SQUARE * RESOLVED_SOURCE_COUNT;
  /// Removes the aligned two-argument opcode column from its first source.
  public const long RETURN_HELPER_CALL_TWO_SOURCE_OFFSET = 256;

  /// Checks whether one resolved return forwards a scalar helper call.
  public boolean resolvedReturnHelperCall(long opcode) {
    if (opcode < STATEMENT_RETURN_HELPER_CALL_BASE) {
      return false;
    }

    if (opcode < RETURN_HELPER_CALL_END) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_ZERO) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_TWO_BASE) {
      return false;
    }

    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_THREE_BASE) {
      return false;
    }

    return opcode < RETURN_HELPER_CALL_THREE_END;
  }

  /// Returns the call arity, or minus one when the opcode is not this family.
  public long returnHelperCallArity(long opcode) {
    if (opcode < STATEMENT_RETURN_HELPER_CALL_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_END) {
      return 1;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_ZERO) {
      return 0;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_TWO_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return 2;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_THREE_BASE) {
      return -1;
    }

    if (opcode < RETURN_HELPER_CALL_THREE_END) {
      return 3;
    }

    return -1;
  }

  /// Returns the first or sole encoded source of one forwarding helper call.
  public long returnHelperCallFirstSource(long opcode) {
    if (opcode < STATEMENT_RETURN_HELPER_CALL_TWO_BASE) {
      return opcode - STATEMENT_RETURN_HELPER_CALL_BASE;
    }

    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return opcode / RESOLVED_SOURCE_COUNT;
    }

    long packed = opcode - STATEMENT_RETURN_HELPER_CALL_THREE_BASE;
    return packed / RESOLVED_SOURCE_SQUARE;
  }

  /// Returns the second source local of one resolved multi-argument helper call.
  public long returnHelperCallSecondSource(long opcode) {
    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return opcode % RESOLVED_SOURCE_COUNT;
    }

    long packed = opcode - STATEMENT_RETURN_HELPER_CALL_THREE_BASE;
    long quotient = packed / RESOLVED_SOURCE_COUNT;
    return quotient % RESOLVED_SOURCE_COUNT;
  }

  /// Returns the third source local of one resolved three-argument helper call.
  public long returnHelperCallThirdSource(long opcode) {
    long packed = opcode - STATEMENT_RETURN_HELPER_CALL_THREE_BASE;
    return packed % RESOLVED_SOURCE_COUNT;
  }
}
