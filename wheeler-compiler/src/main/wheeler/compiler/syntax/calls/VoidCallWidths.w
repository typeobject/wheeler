//! Computes canonical local, instruction, and encoded widths for ordinary void calls.

module wheeler.compiler.void_call_widths;

import wheeler.compiler.void_call_kinds;
import wheeler.compiler.void_call_source_kinds;

classical class VoidCallWidths {
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

    if (-1 < arity) {
      return arity * 2;
    }

    return -1;
  }

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
    if (voidCallArity(kind) == 3) {
      return kind - STATEMENT_CALL_VOID_THREE_BASE;
    }

    return -1;
  }

  /// Returns the canonical instruction count for one resolved void call.
  public long voidCallInstructionCount(long kind) {
    long arity = voidCallArity(kind);
    if (-1 < arity) {
      return arity * 2 + 1;
    }

    return -1;
  }
}
