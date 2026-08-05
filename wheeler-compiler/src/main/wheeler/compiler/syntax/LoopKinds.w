//! Defines resolved bounded loop form identities.

module wheeler.compiler.loop_kinds;

classical class LoopKinds {
  /// Marks while condition whose right operand names a prior local.
  public const long STATEMENT_LOCAL_WHILE_CONDITION_NAMED = 1;
  /// Marks while limit that names a prior local.
  public const long STATEMENT_LOCAL_WHILE_LIMIT_NAMED = 2;
  /// Checked subtraction for a resolved while update.
  public const long STATEMENT_LOCAL_WHILE_SUB_FORM = 4;
  /// Bitwise XOR for a resolved while update.
  public const long STATEMENT_LOCAL_WHILE_XOR_FORM = 8;
  /// Marks zero-to-local less-than condition.
  public const long STATEMENT_LOCAL_WHILE_REVERSED_FORM = 16;
  /// Bounds the closed while form column encoded beside one target local.
  public const long STATEMENT_LOCAL_WHILE_FORM_COUNT = 24;
}
