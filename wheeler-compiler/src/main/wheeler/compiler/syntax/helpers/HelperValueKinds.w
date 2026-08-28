//! Classifies the closed unresolved scalar helper-value statement ranges.

module wheeler.compiler.helper_value_kinds;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.signed_return_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class HelperValueKinds {
  /// Checks for one bounded helper value statement.
  public boolean helperValueStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_BYTES_ALLOCATE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_DROP_OWNED_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_FREEZE_UTF8_NAMED) {
      return true;
    }

    if (voidCallSourceStatement(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_CALL_VOID_FOUR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_CALL_VOID_FIVE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_CALL_VOID_SIX_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_CALL_VOID_SEVEN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_SET_WORD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_SET_BYTE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_MAP_PUT_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_THREE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FOUR_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_THREE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

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

    if (opcode == STATEMENT_RETURN_BUFFER_GET_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_SCALAR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_GET_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_MAP_GET_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BUFFER_GET_NAMED;
  }
}
