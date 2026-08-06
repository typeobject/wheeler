//! Classifies resolved parameter-comparison guard returns.

module wheeler.compiler.resolved_early_comparison_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedEarlyComparisonKinds {
  /// Bounds one resolved opcode column over source-local indices.
  private const long RESOLVED_SOURCE_COUNT = 256;
  /// Ends resolved Boolean equality guards.
  private const long SIGNED_EQ_RETURN_END = STATEMENT_IF_SIGNED_EQ_RETURN_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved signed equality guards.
  private const long SIGNED_EQ_RETURN_LONG_END = STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved Boolean ordering guards.
  private const long SIGNED_LT_RETURN_END = STATEMENT_IF_SIGNED_LT_RETURN_BASE
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
  /// Ends resolved division ordering guards.
  private const long SIGNED_LT_RETURN_DIV_END = STATEMENT_IF_SIGNED_LT_RETURN_DIV_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved equality guards returning prior locals.
  private const long SIGNED_EQ_RETURN_LOCAL_END = STATEMENT_IF_SIGNED_EQ_RETURN_LOCAL_BASE
    + RESOLVED_SOURCE_COUNT;
  /// Ends resolved ordering guards returning prior locals.
  private const long SIGNED_LT_RETURN_LOCAL_END = STATEMENT_IF_SIGNED_LT_RETURN_LOCAL_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode guards one resolved parameter equality.
  public boolean resolvedEarlyEqualityReturn(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_BASE) {
      return false;
    }

    if (opcode < SIGNED_EQ_RETURN_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE) {
      return false;
    }

    if (opcode < SIGNED_EQ_RETURN_LONG_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LOCAL_BASE) {
      return false;
    }

    return opcode < SIGNED_EQ_RETURN_LOCAL_END;
  }

  /// Checks whether an opcode guards one resolved parameter ordering.
  public boolean resolvedEarlyLessReturn(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_BASE) {
      return false;
    }

    if (opcode < SIGNED_LT_RETURN_END) {
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

    if (opcode < SIGNED_LT_RETURN_REMAINDER_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_DIV_BASE) {
      return false;
    }

    if (opcode < SIGNED_LT_RETURN_DIV_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_LOCAL_BASE) {
      return false;
    }

    return opcode < SIGNED_LT_RETURN_LOCAL_END;
  }

}
