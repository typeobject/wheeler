//! Names bounded source and resolved ordinary void-call forms.

module wheeler.compiler.void_call_kinds;

classical class VoidCallKinds {
  /// Names a source zero-argument void call.
  public const long STATEMENT_CALL_VOID_ZERO_NAMED = 900;
  /// Names a source one-argument void call over a prior local.
  public const long STATEMENT_CALL_VOID_ONE_NAMED = 901;
  /// Names a source two-argument void call over prior locals.
  public const long STATEMENT_CALL_VOID_TWO_NAMED = 902;
  /// Names a resolved zero-argument void call.
  public const long STATEMENT_CALL_VOID_ZERO = 131079;
  /// Names a resolved one-argument void call.
  public const long STATEMENT_CALL_VOID_ONE = 131080;
  /// Names a resolved two-argument void call.
  public const long STATEMENT_CALL_VOID_TWO = 131081;

  /// Reports whether one identity is an unresolved void call.
  public boolean voidCallSourceStatement(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO_NAMED) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_ONE_NAMED) {
      return true;
    }

    return kind == STATEMENT_CALL_VOID_TWO_NAMED;
  }

  /// Reports whether one identity is a resolved void call.
  public boolean voidCallStatement(long kind) {
    if (kind == STATEMENT_CALL_VOID_ZERO) {
      return true;
    }

    if (kind == STATEMENT_CALL_VOID_ONE) {
      return true;
    }

    return kind == STATEMENT_CALL_VOID_TWO;
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
