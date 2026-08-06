//! Names bounded source and resolved ordinary void-call forms.

module wheeler.compiler.void_call_kinds;

classical class VoidCallKinds {
  /// Names a source zero-argument void call.
  public const long STATEMENT_CALL_VOID_ZERO_NAMED = 900;
  /// Names a source one-argument void call over a prior local.
  public const long STATEMENT_CALL_VOID_ONE_NAMED = 901;
  /// Names a source two-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_TWO_NAMED = 902;
  /// Names a source three-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_THREE_NAMED = 903;
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

    if (STATEMENT_CALL_VOID_THREE_BASE - 1 < kind) {
      return kind < STATEMENT_CALL_VOID_THREE_BASE + VOID_CALL_LOCAL_SOURCE_COUNT;
    }

    return false;
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

    if (STATEMENT_CALL_VOID_THREE_BASE - 1 < kind) {
      if (kind < STATEMENT_CALL_VOID_THREE_BASE + VOID_CALL_LOCAL_SOURCE_COUNT) {
        return 3;
      }
    }

    return -1;
  }

  /// Returns the canonical local width for one resolved void call.
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
