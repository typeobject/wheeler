//! Classifies local sources in bounded two-argument scalar calls.

module wheeler.compiler.call_argument_sources;

import wheeler.compiler.statement_kinds;

classical class CallArgumentSources {
  /// Checks whether the first call argument names a prior local.
  public boolean twoArgumentCallFirstNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
  }

  /// Checks whether the second call argument names a prior local.
  public boolean twoArgumentCallSecondNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
  }
}
