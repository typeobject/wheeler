//! Classifies resolved signed-local comparisons with literals.

module wheeler.compiler.resolved_local_literal_comparisons;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalLiteralComparisons {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long EQUALITY_END = STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE + RESOLVED_SOURCE_COUNT;
  private const long INEQUALITY_END = STATEMENT_LOCAL_LONG_NE_LITERAL_BASE + RESOLVED_SOURCE_COUNT;
  private const long LESS_THAN_END = STATEMENT_LOCAL_LONG_LT_LITERAL_BASE + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries signed equality with a literal.
  public boolean resolvedLocalLiteralEquality(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE) {
      return false;
    }

    return opcode < EQUALITY_END;
  }

  /// Checks whether an opcode carries signed inequality with a literal.
  public boolean resolvedLocalLiteralInequality(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_NE_LITERAL_BASE) {
      return false;
    }

    return opcode < INEQUALITY_END;
  }

  /// Checks whether an opcode carries signed less-than with a literal.
  public boolean resolvedLocalLiteralLessThan(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_LT_LITERAL_BASE) {
      return false;
    }

    return opcode < LESS_THAN_END;
  }

  /// Checks whether an opcode carries a signed comparison with a literal.
  public boolean resolvedLocalLiteralComparison(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_EQ_LITERAL_BASE) {
      return false;
    }

    if (opcode < LESS_THAN_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_LONG_NE_LITERAL_BASE) {
      return false;
    }

    return opcode < INEQUALITY_END;
  }
}
