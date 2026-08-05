//! Classifies unresolved bounded scalar guard returns.

module wheeler.compiler.early_return_kinds;

import wheeler.compiler.statement_kinds;

classical class EarlyReturnKinds {
  /// Checks whether one unresolved statement is a supported scalar guard return.
  public boolean earlyReturnStatement(long opcode) {
    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_FALSE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED;
  }
}
