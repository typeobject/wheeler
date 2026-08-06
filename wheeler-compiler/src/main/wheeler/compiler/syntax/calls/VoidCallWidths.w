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
