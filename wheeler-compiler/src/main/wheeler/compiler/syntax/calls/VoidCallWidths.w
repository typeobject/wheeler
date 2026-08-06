//! Computes canonical instruction and encoded widths for ordinary void calls.

module wheeler.compiler.void_call_widths;

import wheeler.compiler.void_call_kinds;

classical class VoidCallWidths {
  /// Returns the canonical encoded width for one resolved void call.
  public long voidCallCodeLength(long kind) {
    long arity = voidCallArity(kind);
    if (arity == 0) {
      return 16;
    }

    if (arity == 1) {
      return 80;
    }

    if (arity == 2) {
      return 128;
    }

    if (arity == 3) {
      return 176;
    }

    return -1;
  }

  /// Returns the third source local encoded in a resolved three-argument call.
  public long voidCallThirdSource(long kind) {
    if (kind < STATEMENT_CALL_VOID_THREE_BASE) {
      return -1;
    }

    if (kind < STATEMENT_CALL_VOID_THREE_LIMIT) {
      return kind - STATEMENT_CALL_VOID_THREE_BASE;
    }

    return -1;
  }

  /// Returns the canonical instruction count for one resolved void call.
  public long voidCallInstructionCount(long kind) {
    long arity = voidCallArity(kind);
    if (arity == 0) {
      return 1;
    }

    if (arity == 1) {
      return 3;
    }

    if (arity == 2) {
      return 5;
    }

    if (arity == 3) {
      return 7;
    }

    return -1;
  }
}
