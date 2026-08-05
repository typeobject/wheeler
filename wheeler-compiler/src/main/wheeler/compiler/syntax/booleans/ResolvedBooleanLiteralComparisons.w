//! Classifies and decodes resolved Boolean-local comparisons with literals.

module wheeler.compiler.resolved_boolean_literal_comparisons;

import wheeler.compiler.resolved_statements;

classical class ResolvedBooleanLiteralComparisons {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long EQUALITY_END = STATEMENT_LOCAL_BOOLEAN_EQ_LITERAL_BASE + RESOLVED_SOURCE_COUNT;
  private const long INEQUALITY_END = STATEMENT_LOCAL_BOOLEAN_NE_LITERAL_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries Boolean equality with a literal.
  public boolean resolvedBooleanLiteralEquality(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_EQ_LITERAL_BASE) {
      return false;
    }

    return opcode < EQUALITY_END;
  }

  /// Checks whether an opcode carries Boolean inequality with a literal.
  public boolean resolvedBooleanLiteralInequality(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_NE_LITERAL_BASE) {
      return false;
    }

    return opcode < INEQUALITY_END;
  }

  /// Checks whether an opcode compares one Boolean local with a literal.
  public boolean resolvedBooleanLiteralComparison(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_EQ_LITERAL_BASE) {
      return false;
    }

    return opcode < INEQUALITY_END;
  }

  /// Returns the source local carried by a Boolean literal comparison.
  public long resolvedBooleanLiteralComparisonSource(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_NE_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_BOOLEAN_EQ_LITERAL_BASE;
    }

    return opcode - STATEMENT_LOCAL_BOOLEAN_NE_LITERAL_BASE;
  }
}
