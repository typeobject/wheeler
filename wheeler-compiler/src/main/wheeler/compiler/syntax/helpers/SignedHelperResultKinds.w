//! Classifies signed scalar-helper tail result statements.

module wheeler.compiler.signed_helper_result_kinds;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.forwarded_helper_result_statements;
import wheeler.compiler.resolved_local_return_statements;
import wheeler.compiler.signed_return_statements;

classical class SignedHelperResultKinds {
  private const long RETURN_HELPER_CALL_END = 27904;
  private const long RETURN_HELPER_CALL_TWO_END = 131072;
  private const long RETURN_HELPER_CALL_THREE_END = 33554432;
  private const long RETURN_HELPER_CALL_FOUR_END = 4328521728;

  /// Checks whether one statement returns a signed helper result.
  public boolean signedHelperResult(long opcode) {
    if (opcode == STATEMENT_RETURN_LONG) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_ADD_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_MOD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_ADD_LOCAL_NAMED) {
      return false;
    }

    if (opcode < STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_AND_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_RETURN_SIGNED_LOCAL_BASE) {
      return false;
    }

    if (opcode < STATEMENT_RETURN_BOOLEAN_LOCAL_BASE) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_LENGTH) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BUFFER_GET) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET) {
      return true;
    }

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
