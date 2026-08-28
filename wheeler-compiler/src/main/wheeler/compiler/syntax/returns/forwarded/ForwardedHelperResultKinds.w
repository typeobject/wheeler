//! Owns resolved helper-call return identities and membership.

module wheeler.compiler.forwarded_helper_result_kinds;

import wheeler.compiler.forwarded_helper_result_statements;

classical class ForwardedHelperResultKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RESOLVED_SOURCE_CUBE = 16777216;
  private const long RETURN_HELPER_CALL_END = STATEMENT_RETURN_HELPER_CALL_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long RETURN_HELPER_CALL_TWO_END = STATEMENT_RETURN_HELPER_CALL_TWO_BASE
    + RESOLVED_SOURCE_COUNT * RESOLVED_SOURCE_COUNT;
  private const long RETURN_HELPER_CALL_THREE_END = STATEMENT_RETURN_HELPER_CALL_THREE_BASE
    + RESOLVED_SOURCE_CUBE;
  private const long RETURN_HELPER_CALL_FOUR_END = STATEMENT_RETURN_HELPER_CALL_FOUR_BASE
    + RESOLVED_SOURCE_CUBE * RESOLVED_SOURCE_COUNT;

  /// Checks whether one resolved return forwards a scalar helper call.
  public boolean resolvedReturnHelperCall(long opcode) {
    if (opcode < STATEMENT_RETURN_HELPER_CALL_BASE) {
      return false;
    }

    if (opcode < RETURN_HELPER_CALL_END) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_ZERO) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_FIVE) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_SIX) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_SEVEN) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_TWO_BASE) {
      return false;
    }

    if (opcode < RETURN_HELPER_CALL_TWO_END) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_THREE_BASE) {
      return false;
    }

    if (opcode < RETURN_HELPER_CALL_THREE_END) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_HELPER_CALL_FOUR_BASE) {
      return false;
    }

    return opcode < RETURN_HELPER_CALL_FOUR_END;
  }
}
