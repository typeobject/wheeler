//! Classifies the bounded three-local scalar helper call.

module wheeler.compiler.three_argument_calls;

import wheeler.compiler.statement_kinds;

classical class ThreeArgumentCalls {
  /// Packs the third resolved source into the statement identity.
  public const long STATEMENT_LOCAL_CALL_THREE_LOCALS_BASE = 32768;
  /// Bounds the packed third source by the canonical local window.
  private const long THREE_ARGUMENT_LOCAL_SOURCE_COUNT = 256;
  /// Names the exclusive end of packed three-local calls.
  private const long STATEMENT_LOCAL_CALL_THREE_LOCALS_LIMIT
    = STATEMENT_LOCAL_CALL_THREE_LOCALS_BASE + THREE_ARGUMENT_LOCAL_SOURCE_COUNT;

  /// Checks for the unresolved or resolved three-local call identity.
  public boolean threeArgumentCallStatement(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_THREE_LOCALS_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_CALL_THREE_LOCALS_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_CALL_THREE_LOCALS_LIMIT;
  }

  /// Returns the first argument token of one three-local call.
  public long threeArgumentFirstToken(long statementStart) {
    return statementStart + 5;
  }

  /// Returns the second argument token of one three-local call.
  public long threeArgumentSecondToken(long statementStart) {
    return statementStart + 7;
  }

  /// Returns the third argument token of one three-local call.
  public long threeArgumentThirdToken(long statementStart) {
    return statementStart + 9;
  }

  /// Decodes the packed third prior-local source, or minus one.
  public long threeArgumentThirdSource(long opcode) {
    if (opcode < STATEMENT_LOCAL_CALL_THREE_LOCALS_BASE) {
      return -1;
    }

    if (opcode < STATEMENT_LOCAL_CALL_THREE_LOCALS_LIMIT) {
      return opcode - STATEMENT_LOCAL_CALL_THREE_LOCALS_BASE;
    }

    return -1;
  }
}
