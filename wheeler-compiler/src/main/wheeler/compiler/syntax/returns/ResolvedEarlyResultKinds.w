//! Classifies resolved helper guards and signed early results.

module wheeler.compiler.resolved_early_result_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedEarlyResultKinds {
  /// Bounds one resolved opcode column over source-local indices.
  private const long RESOLVED_SOURCE_COUNT = 256;
  /// Ends resolved Boolean helper-call guards.
  private const long HELPER_RETURN_END = STATEMENT_IF_HELPER_CALL_RETURN_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved signed equality guards.
  private const long SIGNED_EQ_RETURN_LONG_END = STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved signed helper-call guards.
  private const long HELPER_RETURN_LONG_END = STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved signed ordering guards.
  private const long SIGNED_LT_RETURN_LONG_END = STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved computed ordering guards.
  private const long SIGNED_LT_RETURN_SUB_END = STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved remainder ordering guards.
  private const long SIGNED_LT_RETURN_REMAINDER_END = STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved helper guards forwarding another call.
  private const long HELPER_FORWARD_RETURN_END = STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode forwards a call result behind a helper-call guard.
  public boolean resolvedEarlyHelperForwardingReturn(long opcode) {
    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_BASE) {
      return false;
    }

    return opcode < HELPER_FORWARD_RETURN_END;
  }

  /// Checks whether an opcode guards one resolved helper call.
  public boolean resolvedEarlyHelperReturn(long opcode) {
    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_BASE) {
      return false;
    }

    if (opcode < HELPER_RETURN_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE) {
      return false;
    }

    if (opcode < HELPER_RETURN_LONG_END) {
      return true;
    }

    return resolvedEarlyHelperForwardingReturn(opcode);
  }

  /// Checks whether one resolved guard returns a signed value.
  public boolean resolvedEarlySignedReturn(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE) {
      return false;
    }

    if (opcode < SIGNED_EQ_RETURN_LONG_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE) {
      return false;
    }

    if (opcode < HELPER_RETURN_LONG_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE) {
      return false;
    }

    if (opcode < SIGNED_LT_RETURN_LONG_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE) {
      return false;
    }

    if (opcode < SIGNED_LT_RETURN_SUB_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_BASE) {
      return false;
    }

    return opcode < SIGNED_LT_RETURN_REMAINDER_END;
  }

  /// Checks whether one resolved guard computes a signed result.
  public boolean resolvedEarlyComputedReturn(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE) {
      return false;
    }

    if (opcode < SIGNED_LT_RETURN_SUB_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_BASE) {
      return false;
    }

    return opcode < SIGNED_LT_RETURN_REMAINDER_END;
  }

  /// Checks whether one resolved guard computes checked remainder.
  public boolean resolvedEarlyRemainderReturn(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_BASE) {
      return false;
    }

    return opcode < SIGNED_LT_RETURN_REMAINDER_END;
  }
}
