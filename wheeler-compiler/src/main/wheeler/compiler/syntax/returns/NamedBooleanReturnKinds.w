//! Classifies unresolved Boolean comparison helper returns.

module wheeler.compiler.named_boolean_return_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedBooleanReturnKinds {
  /// Checks for a Boolean helper equality return.
  public boolean returnBooleanEqualityStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED;
  }

  /// Checks for a Boolean helper inequality return.
  public boolean returnBooleanInequalityStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED;
  }

  /// Checks for any direct Boolean comparison helper return.
  public boolean returnBooleanComparisonStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LITERAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      return true;
    }

    return returnBooleanInequalityStatement(opcode);
  }
}
