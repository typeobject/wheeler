//! Classifies bounded four-local scalar helper calls.

module wheeler.compiler.four_argument_calls;

import wheeler.compiler.statement_kinds;

classical class FourArgumentCalls {
  /// Packs the last two signed-result call sources into the statement identity.
  public const long STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE = 262144;
  /// Packs the last two Boolean-result call sources into the statement identity.
  public const long STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_BASE = 327680;
  /// Bounds one packed source by the canonical local window.
  public const long LOCAL_VALUE_CALL_SOURCE_COUNT = 256;
  /// Names the exclusive end of packed signed-result calls.
  private const long STATEMENT_LOCAL_CALL_FOUR_LOCALS_LIMIT = STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE
    + LOCAL_VALUE_CALL_SOURCE_COUNT * LOCAL_VALUE_CALL_SOURCE_COUNT;
  /// Names the exclusive end of packed Boolean-result calls.
  private const long STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_LIMIT
    = STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_BASE + LOCAL_VALUE_CALL_SOURCE_COUNT
    * LOCAL_VALUE_CALL_SOURCE_COUNT;

  /// Checks for an unresolved or resolved four-local call identity.
  public boolean fourArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_FOUR_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE) {
      return false;
    }

    if (opcode < STATEMENT_LOCAL_CALL_FOUR_LOCALS_LIMIT) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_LIMIT;
  }

  /// Checks whether one four-local call returns Boolean.
  public boolean fourArgumentBooleanCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_LIMIT;
  }

  /// Returns the fourth argument token of one four-local call.
  public long fourArgumentCallFourthToken(long statementStart) {
    return statementStart + 11;
  }

  private long fourArgumentPackedSources(long opcode) {
    if (fourArgumentBooleanCall(opcode)) {
      return opcode - STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_BASE;
    }

    return opcode - STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE;
  }

  /// Decodes the packed third source from one validated four-local identity.
  public long fourArgumentCallThirdSource(long opcode) {
    return fourArgumentPackedSources(opcode) / LOCAL_VALUE_CALL_SOURCE_COUNT;
  }

  /// Decodes the packed fourth source from one validated four-local identity.
  public long fourArgumentCallFourthSource(long opcode) {
    return fourArgumentPackedSources(opcode) % LOCAL_VALUE_CALL_SOURCE_COUNT;
  }
}
