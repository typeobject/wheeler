//! Classifies and decodes resolved Boolean assertions with literals.

module wheeler.compiler.resolved_boolean_literal_assertions;

import wheeler.compiler.resolved_statements;

classical class ResolvedBooleanLiteralAssertions {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long ASSERTION_END = STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode asserts Boolean equality against a literal.
  public boolean resolvedBooleanLiteralAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE) {
      return false;
    }

    return opcode < ASSERTION_END;
  }

  /// Returns the source local carried by a Boolean literal assertion.
  public long resolvedBooleanLiteralAssertionSource(long opcode) {
    return opcode - STATEMENT_ASSERT_BOOLEAN_LITERAL_BASE;
  }
}
