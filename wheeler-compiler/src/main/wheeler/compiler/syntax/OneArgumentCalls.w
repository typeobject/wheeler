//! Classifies bounded one-argument scalar helper calls.

module wheeler.compiler.one_argument_calls;

import wheeler.compiler.statement_kinds;

classical class OneArgumentCalls {
  /// Checks for a signed or Boolean one-argument helper call.
  public boolean oneArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one helper call argument names a prior local.
  public boolean oneArgumentCallNamed(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one helper call receives and returns a Boolean.
  public boolean oneArgumentBooleanCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_LOCAL_ARGUMENT_NAMED;
  }

  /// Checks whether one Boolean-result call receives a signed value.
  public boolean oneArgumentBooleanSignedCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_LOCAL_ARGUMENT_NAMED;
  }
}
