//! Validates operands for focused statements outside the general local classifier.

module wheeler.compiler.operand_validity;

import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.owned_utf8_copy_loops;

classical class OperandValidity {
  /// Carries one focused validity decision and whether it applies.
  public record FocusedOperandValidity(boolean valid, boolean applies) {}

  /// Checks operands for focused guarded-call and owner-copy statements.
  public FocusedOperandValidity focusedOperandValidity(long opcode, long operand) {
    if (earlyUtf8Call(opcode)) {
      return new FocusedOperandValidity(-1 < operand, true);
    }

    if (ownedUtf8CopyLoop(opcode)) {
      return new FocusedOperandValidity(-1 < operand, true);
    }

    return new FocusedOperandValidity(true, false);
  }
}
