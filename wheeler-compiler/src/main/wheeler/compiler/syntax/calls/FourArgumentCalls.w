//! Classifies the bounded four-local signed helper call.

module wheeler.compiler.four_argument_calls;

import wheeler.compiler.statement_kinds;

classical class FourArgumentCalls {
  /// Packs the last two resolved sources into the statement identity.
  public const long STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE = 262144;
  /// Bounds one packed source by the canonical local window.
  public const long LOCAL_VALUE_CALL_SOURCE_COUNT = 256;
  /// Names the exclusive end of packed four-local calls.
  private const long STATEMENT_LOCAL_CALL_FOUR_LOCALS_LIMIT = STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE
    + LOCAL_VALUE_CALL_SOURCE_COUNT * LOCAL_VALUE_CALL_SOURCE_COUNT;

  /// Checks for an unresolved or resolved four-local call identity.
  public boolean fourArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_FOUR_LOCALS_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_CALL_FOUR_LOCALS_LIMIT;
  }

  /// Returns the fourth argument token of one four-local call.
  public long fourArgumentCallFourthToken(long statementStart) {
    return statementStart + 11;
  }

  /// Decodes the packed third source from one validated four-local identity.
  public long fourArgumentCallThirdSource(long opcode) {
    long packed = opcode - STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE;
    return packed / LOCAL_VALUE_CALL_SOURCE_COUNT;
  }

  /// Decodes the packed fourth source from one validated four-local identity.
  public long fourArgumentCallFourthSource(long opcode) {
    long packed = opcode - STATEMENT_LOCAL_CALL_FOUR_LOCALS_BASE;
    return packed % LOCAL_VALUE_CALL_SOURCE_COUNT;
  }
}
