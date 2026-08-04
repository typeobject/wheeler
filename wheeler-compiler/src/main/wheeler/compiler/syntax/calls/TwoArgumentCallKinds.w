//! Classifies bounded two-argument scalar helper calls.

module wheeler.compiler.two_argument_call_kinds;

import wheeler.compiler.statement_kinds;

classical class TwoArgumentCallKinds {
  /// Checks for a signed or Boolean two-argument helper call.
  public boolean twoArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
  }

  /// Checks whether a two-argument call returns a signed value.
  public boolean twoArgumentSignedResultCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_CALL_TWO_LOCALS_NAMED;
  }

  /// Checks whether a two-argument helper call receives and returns Booleans.
  public boolean twoArgumentBooleanCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_TWO_LOCALS_NAMED;
  }

  /// Checks whether one Boolean-result call receives two signed values.
  public boolean twoArgumentBooleanSignedCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_FIRST_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_SECOND_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_TWO_LOCALS_NAMED;
  }
}
