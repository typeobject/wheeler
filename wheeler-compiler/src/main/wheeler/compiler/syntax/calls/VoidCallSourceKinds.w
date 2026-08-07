//! Names and classifies unresolved ordinary void-call forms.

module wheeler.compiler.void_call_source_kinds;

classical class VoidCallSourceKinds {
  /// Names a source zero-argument void call.
  public const long STATEMENT_CALL_VOID_ZERO_NAMED = 900;
  /// Names a source one-argument void call over a prior local.
  public const long STATEMENT_CALL_VOID_ONE_NAMED = 901;
  /// Names a source two-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_TWO_NAMED = 902;
  /// Names a source three-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_THREE_NAMED = 903;
  /// Names a source four-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_FOUR_NAMED = 922;
  /// Names a source five-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_FIVE_NAMED = 923;
  /// Names a source six-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_SIX_NAMED = 924;
  /// Names a source seven-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_SEVEN_NAMED = 925;

  /// Reports whether one identity is an unresolved void call.
  public boolean voidCallSourceStatement(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO_NAMED) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_ONE_NAMED) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_TWO_NAMED) {
      return true;
    }

    return kind == STATEMENT_CALL_VOID_THREE_NAMED;
  }

}
