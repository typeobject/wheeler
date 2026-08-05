//! Classifies unresolved direct Boolean and signed comparison returns.

module wheeler.compiler.named_comparison_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedComparisonKinds {
  /// Checks for any direct typed comparison helper return.
  public boolean returnComparisonStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
  }

  /// Checks for any direct typed inequality helper return.
  public boolean returnInequalityStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED;
  }

  /// Checks whether one direct comparison receives signed values.
  public boolean returnComparisonSigned(long opcode) {
    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
  }
}
