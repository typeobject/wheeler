//! Decodes bounded local-loop form bits.

module wheeler.compiler.resolved_local_loop_forms;

import wheeler.compiler.loop_kinds;

classical class ResolvedLocalLoopForms {
  private const long CONDITION_FORM_COUNT = 2;
  private const long LIMIT_FORM_DIVISOR = 2;

  /// Returns the condition-source bit from one decoded while form.
  public long localWhileConditionBit(long form) {
    return form % CONDITION_FORM_COUNT;
  }

  /// Returns the limit-source pair from one decoded while form.
  public long localWhileLimitPair(long form) {
    return form / LIMIT_FORM_DIVISOR;
  }

  /// Checks whether a decoded while compares zero with its target.
  public boolean localWhileReversed(long form) {
    if (form < STATEMENT_LOCAL_WHILE_REVERSED_FORM) {
      return false;
    }

    return true;
  }

  /// Returns the direction and update bits from one decoded while form.
  public long localWhileUpdateBits(long form) {
    return form % STATEMENT_LOCAL_WHILE_REVERSED_FORM;
  }
}
