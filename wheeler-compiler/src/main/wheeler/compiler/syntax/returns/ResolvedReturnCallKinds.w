//! Classifies resolved scalar helper returns that forward one call result.

module wheeler.compiler.resolved_return_call_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedReturnCallKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RETURN_HELPER_CALL_END = STATEMENT_RETURN_HELPER_CALL_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether one resolved return forwards a scalar helper call.
  public boolean resolvedReturnHelperCall(long opcode) {
    if (opcode == STATEMENT_RETURN_HELPER_CALL_ZERO) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_BASE) {
      return false;
    }

    return opcode < RETURN_HELPER_CALL_END;
  }

  /// Checks whether one resolved return forwards a zero-argument helper call.
  public boolean resolvedReturnHelperCallZero(long opcode) {
    return opcode == STATEMENT_RETURN_HELPER_CALL_ZERO;
  }

  /// Returns the source local of one resolved forwarding helper call.
  public long returnHelperCallSource(long opcode) {
    return opcode - STATEMENT_RETURN_HELPER_CALL_BASE;
  }
}
