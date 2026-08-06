//! Computes canonical local widths for source and resolved ordinary void calls.

module wheeler.compiler.void_call_source_widths;

import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallSourceWidths {
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

    long arity = voidCallArity(kind);
    if (arity < 0) {
      return -1;
    }

    return arity * 2;
  }
}
