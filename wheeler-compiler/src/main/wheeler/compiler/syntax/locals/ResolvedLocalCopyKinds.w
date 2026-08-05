//! Classifies resolved scalar assertions, copies, and Boolean negation.

module wheeler.compiler.resolved_local_copy_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalCopyKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LONG_ASSERTION_END = STATEMENT_ASSERT_LOCAL_LONG_BASE + RESOLVED_SOURCE_COUNT;
  private const long LONG_COPY_END = STATEMENT_LOCAL_LONG_COPY_BASE + RESOLVED_SOURCE_COUNT;
  private const long BOOLEAN_COPY_END = STATEMENT_LOCAL_BOOLEAN_COPY_BASE + RESOLVED_SOURCE_COUNT;
  private const long BOOLEAN_NOT_END = STATEMENT_LOCAL_BOOLEAN_NOT_BASE + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries one resolved signed-local identity.
  public boolean resolvedLocalLongAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LOCAL_LONG_BASE) {
      return false;
    }

    return opcode < LONG_ASSERTION_END;
  }

  /// Checks whether an opcode carries one resolved signed-local copy source.
  public boolean resolvedLocalLongCopy(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_COPY_BASE) {
      return false;
    }

    return opcode < LONG_COPY_END;
  }

  /// Checks whether an opcode carries one resolved Boolean-local copy source.
  public boolean resolvedLocalBooleanCopy(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_COPY_BASE) {
      return false;
    }

    return opcode < BOOLEAN_COPY_END;
  }

  /// Checks whether an opcode carries one resolved negated Boolean-local source.
  public boolean resolvedLocalBooleanNot(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_NOT_BASE) {
      return false;
    }

    return opcode < BOOLEAN_NOT_END;
  }
}
