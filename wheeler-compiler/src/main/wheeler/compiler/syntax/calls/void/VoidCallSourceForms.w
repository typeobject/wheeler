//! Maps unresolved ordinary void-call identities to exact arities.

module wheeler.compiler.void_call_source_forms;

import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallSourceForms {
  /// Reports whether one identity is any unresolved void call.
  public boolean anyVoidCallSourceStatement(long kind) {
    if (voidCallSourceStatement(kind)) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_FOUR_NAMED) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_FIVE_NAMED) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_SIX_NAMED) {
      return true;
    }

    return kind == STATEMENT_CALL_VOID_SEVEN_NAMED;
  }

  /// Returns the exact source-call arity, or minus one.
  public long voidCallSourceArity(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO_NAMED) {
      return 0;
    }

    if (kind == STATEMENT_CALL_VOID_ONE_NAMED) {
      return 1;
    }

    if (kind == STATEMENT_CALL_VOID_TWO_NAMED) {
      return 2;
    }

    if (kind == STATEMENT_CALL_VOID_THREE_NAMED) {
      return 3;
    }

    if (kind == STATEMENT_CALL_VOID_FOUR_NAMED) {
      return 4;
    }

    if (kind == STATEMENT_CALL_VOID_FIVE_NAMED) {
      return 5;
    }

    if (kind == STATEMENT_CALL_VOID_SIX_NAMED) {
      return 6;
    }

    if (kind == STATEMENT_CALL_VOID_SEVEN_NAMED) {
      return MAX_VOID_CALL_ARGUMENTS;
    }

    return -1;
  }

  /// Returns one unresolved void-call identity for an exact arity.
  public long voidCallSourceKind(long arity) {
    if (arity == 0) {
      return STATEMENT_CALL_VOID_ZERO_NAMED;
    }

    if (arity == 1) {
      return STATEMENT_CALL_VOID_ONE_NAMED;
    }

    if (arity == 2) {
      return STATEMENT_CALL_VOID_TWO_NAMED;
    }

    if (arity == 3) {
      return STATEMENT_CALL_VOID_THREE_NAMED;
    }

    if (arity == 4) {
      return STATEMENT_CALL_VOID_FOUR_NAMED;
    }

    if (arity == 5) {
      return STATEMENT_CALL_VOID_FIVE_NAMED;
    }

    if (arity == 6) {
      return STATEMENT_CALL_VOID_SIX_NAMED;
    }

    if (arity == MAX_VOID_CALL_ARGUMENTS) {
      return STATEMENT_CALL_VOID_SEVEN_NAMED;
    }

    return -1;
  }
}
