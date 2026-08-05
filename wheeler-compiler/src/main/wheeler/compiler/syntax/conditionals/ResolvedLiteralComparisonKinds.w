//! Classifies resolved signed literal-comparison condition forms.

module wheeler.compiler.resolved_literal_comparison_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedLiteralComparisonKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RESOLVED_LITERAL_COMPARISON_END = STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks for a resolved signed literal-comparison condition.
  public boolean resolvedLiteralComparisonConditional(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE) {
      return false;
    }

    return opcode < RESOLVED_LITERAL_COMPARISON_END;
  }

  /// Checks whether a resolved condition compares with signed less-than.
  public boolean resolvedLiteralComparisonConditionalLessThan(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return false;
    }

    return opcode < RESOLVED_LITERAL_COMPARISON_END;
  }
}
