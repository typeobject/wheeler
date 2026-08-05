//! Classifies and decodes resolved signed less-than assertions.

module wheeler.compiler.resolved_less_than_assertions;

import wheeler.compiler.resolved_statements;

classical class ResolvedLessThanAssertions {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LOCAL_LESS_THAN_ASSERTION_END = STATEMENT_ASSERT_LONG_LT_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long LITERAL_LESS_THAN_ASSERTION_END = STATEMENT_ASSERT_LONG_LT_LITERAL_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved signed less-than assertion source.
  public boolean resolvedLocalLessThanAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_LT_BASE) {
      return false;
    }

    return opcode < LOCAL_LESS_THAN_ASSERTION_END;
  }

  /// Checks whether an opcode carries a resolved signed less-than literal assertion.
  public boolean resolvedLiteralLessThanAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_LT_LITERAL_BASE) {
      return false;
    }

    return opcode < LITERAL_LESS_THAN_ASSERTION_END;
  }

  /// Returns the signed local carried by a less-than literal assertion.
  public long resolvedLiteralLessThanAssertionSource(long opcode) {
    return opcode - STATEMENT_ASSERT_LONG_LT_LITERAL_BASE;
  }
}
