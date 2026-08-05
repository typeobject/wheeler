//! Classifies and decodes resolved two-local equality assertions.

module wheeler.compiler.resolved_local_pair_assertions;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalPairAssertions {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long BOOLEAN_PAIR_ASSERTION_END = STATEMENT_ASSERT_BOOLEAN_PAIR_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved two-local equality assertion.
  public boolean resolvedLocalPairAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_PAIR_BASE) {
      return false;
    }

    return opcode < BOOLEAN_PAIR_ASSERTION_END;
  }

  /// Reports whether a resolved two-local assertion compares signed values.
  public boolean resolvedLocalPairAssertionSigned(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_PAIR_BASE) {
      return false;
    }

    return opcode < STATEMENT_ASSERT_BOOLEAN_PAIR_BASE;
  }

  /// Returns the left source carried by a resolved two-local assertion.
  public long resolvedLocalPairAssertionSource(long opcode) {
    if (opcode < STATEMENT_ASSERT_LONG_PAIR_BASE) {
      return opcode - STATEMENT_ASSERT_BOOLEAN_PAIR_BASE;
    }

    if (opcode < STATEMENT_ASSERT_BOOLEAN_PAIR_BASE) {
      return opcode - STATEMENT_ASSERT_LONG_PAIR_BASE;
    }

    return opcode - STATEMENT_ASSERT_BOOLEAN_PAIR_BASE;
  }
}
