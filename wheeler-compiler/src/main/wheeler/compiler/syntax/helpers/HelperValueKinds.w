//! Classifies the closed unresolved scalar helper-value statement ranges.

module wheeler.compiler.helper_value_kinds;

import wheeler.compiler.borrowed_intrinsic_returns;
import wheeler.compiler.statement_kinds;

classical class HelperValueKinds {
  /// Checks for one bounded helper value statement.
  public boolean helperValueStatement(long opcode) {
    if (opcode < STATEMENT_LOCAL_CALL_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_LOCAL_LONG_AND_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_AND_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_LOCAL_BOOLEAN_NE_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_BOOLEAN_NE_LITERAL_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED;
  }
}
