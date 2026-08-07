//! Names and classifies resolved ordinary void-call forms.

module wheeler.compiler.void_call_kinds;

classical class VoidCallKinds {
  /// Bounds ordinary void calls by the scalar call-frame profile.
  public const long MAX_VOID_CALL_ARGUMENTS = 7;
  /// Names a resolved zero-argument void call.
  public const long STATEMENT_CALL_VOID_ZERO = 131079;
  /// Names a resolved one-argument void call.
  public const long STATEMENT_CALL_VOID_ONE = 131080;
  /// Names a resolved two-argument void call.
  public const long STATEMENT_CALL_VOID_TWO = 131081;
  /// Begins resolved three-argument calls indexed by their third source local.
  public const long STATEMENT_CALL_VOID_THREE_BASE = 131082;
  /// Names the bounded local-source column width encoded in a call identity.
  public const long VOID_CALL_LOCAL_SOURCE_COUNT = 256;
  /// Ends the resolved three-argument source-local column.
  public const long STATEMENT_CALL_VOID_THREE_LIMIT = STATEMENT_CALL_VOID_THREE_BASE
    + VOID_CALL_LOCAL_SOURCE_COUNT;
  /// Names a resolved four-argument void call.
  public const long STATEMENT_CALL_VOID_FOUR = 30976;
  /// Names a resolved five-argument void call.
  public const long STATEMENT_CALL_VOID_FIVE = 31232;
  /// Names a resolved six-argument void call.
  public const long STATEMENT_CALL_VOID_SIX = 31488;
  /// Names a resolved seven-argument void call.
  public const long STATEMENT_CALL_VOID_SEVEN = 31744;

  /// Reports whether one identity is a resolved void call.
  public boolean voidCallStatement(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_ONE) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_TWO) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_FOUR) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_FIVE) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_SIX) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_SEVEN) {
      return true;
    }

    if (kind < STATEMENT_CALL_VOID_THREE_BASE) {
      return false;
    }

    return kind < STATEMENT_CALL_VOID_THREE_LIMIT;
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

  /// Returns the exact argument count for one resolved void call.
  public long voidCallArity(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO) {
      return 0;
    }

    if (kind == STATEMENT_CALL_VOID_ONE) {
      return 1;
    }

    if (kind == STATEMENT_CALL_VOID_TWO) {
      return 2;
    }

    if (kind == STATEMENT_CALL_VOID_FOUR) {
      return 4;
    }

    if (kind == STATEMENT_CALL_VOID_FIVE) {
      return 5;
    }

    if (kind == STATEMENT_CALL_VOID_SIX) {
      return 6;
    }

    if (kind == STATEMENT_CALL_VOID_SEVEN) {
      return MAX_VOID_CALL_ARGUMENTS;
    }

    if (kind < STATEMENT_CALL_VOID_THREE_BASE) {
      return -1;
    }

    if (kind < STATEMENT_CALL_VOID_THREE_LIMIT) {
      return 3;
    }

    return -1;
  }

}
