//! Classifies unresolved signed comparison helper returns.

module wheeler.compiler.named_signed_return_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedSignedReturnKinds {
  /// Checks for a direct signed equality helper return.
  public boolean returnSignedEqualityStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED;
  }

  /// Checks for a direct signed inequality helper return.
  public boolean returnSignedInequalityStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_SIGNED_NE_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED;
  }

  /// Checks for a direct signed less-than helper return.
  public boolean returnSignedLessThanStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_SIGNED_LT_LITERAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
  }
}
