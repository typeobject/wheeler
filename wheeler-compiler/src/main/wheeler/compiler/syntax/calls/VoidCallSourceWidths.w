//! Computes canonical local widths for source and resolved ordinary void calls.

module wheeler.compiler.void_call_source_widths;

import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallSourceWidths {
  /// Returns the canonical local width for one source or resolved void call.
  public long voidCallLocalCount(long kind) {
    long arity = voidCallArity(kind);
    if (kind == STATEMENT_CALL_VOID_ZERO_NAMED) {
      arity = 0;
    }

    if (kind == STATEMENT_CALL_VOID_ONE_NAMED) {
      arity = 1;
    }

    if (kind == STATEMENT_CALL_VOID_TWO_NAMED) {
      arity = 2;
    }

    if (kind == STATEMENT_CALL_VOID_THREE_NAMED) {
      arity = 3;
    }

    if (arity < 0) {
      return -1;
    }

    return arity * 2;
  }
}
