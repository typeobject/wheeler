//! Computes canonical local widths for source and resolved ordinary void calls.

module wheeler.compiler.void_call_source_widths;

import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallSourceWidths {
  private const long VOID_CALL_FOUR_LOCALS = 8;
  private const long VOID_CALL_FIVE_LOCALS = 10;
  private const long VOID_CALL_SIX_LOCALS = 12;
  private const long VOID_CALL_SEVEN_LOCALS = 14;

  /// Returns the canonical local width for one source or resolved void call.
  public long voidCallLocalCount(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO_NAMED) {
      return 0;
    }

    if (kind == STATEMENT_CALL_VOID_ONE_NAMED) {
      return 2;
    }

    if (kind == STATEMENT_CALL_VOID_TWO_NAMED) {
      return 4;
    }

    if (kind == STATEMENT_CALL_VOID_THREE_NAMED) {
      return 6;
    }

    if (kind == STATEMENT_CALL_VOID_FOUR_NAMED) {
      return VOID_CALL_FOUR_LOCALS;
    }

    if (kind == STATEMENT_CALL_VOID_FIVE_NAMED) {
      return VOID_CALL_FIVE_LOCALS;
    }

    if (kind == STATEMENT_CALL_VOID_SIX_NAMED) {
      return VOID_CALL_SIX_LOCALS;
    }

    if (kind == STATEMENT_CALL_VOID_SEVEN_NAMED) {
      return VOID_CALL_SEVEN_LOCALS;
    }

    long arity = voidCallArity(kind);
    if (arity < 0) {
      return -1;
    }

    return arity * 2;
  }
}
