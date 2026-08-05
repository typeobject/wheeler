//! Classifies resolved scalar guard returns and their encoded source locals.

module wheeler.compiler.early_return_opcodes;

import wheeler.compiler.resolved_statements;

classical class EarlyReturnOpcodes {
  /// Bounds one resolved opcode column over source-local indices.
  private const long RESOLVED_SOURCE_COUNT = 256;

  /// Checks whether an opcode guards one resolved helper call.
  public boolean resolvedEarlyHelperReturn(long opcode) {
    if (STATEMENT_IF_HELPER_CALL_RETURN_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_BASE + RESOLVED_SOURCE_COUNT) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE + RESOLVED_SOURCE_COUNT;
  }

  /// Returns the argument source for one resolved helper-call guard.
  public long earlyHelperReturnSource(long opcode) {
    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE) {
      return opcode - STATEMENT_IF_HELPER_CALL_RETURN_BASE;
    }

    return opcode - STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE;
  }

  /// Checks whether an opcode guards one resolved parameter equality.
  public boolean resolvedEarlyEqualityReturn(long opcode) {
    if (STATEMENT_IF_SIGNED_EQ_RETURN_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_BASE + RESOLVED_SOURCE_COUNT) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE + RESOLVED_SOURCE_COUNT;
  }

  /// Returns the signed source local for one resolved equality guard.
  public long earlyEqualityReturnSource(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE) {
      return opcode - STATEMENT_IF_SIGNED_EQ_RETURN_BASE;
    }

    return opcode - STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE;
  }

  /// Checks whether one resolved guard returns a signed value.
  public boolean resolvedEarlySignedReturn(long opcode) {
    if (STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE - 1 < opcode) {
      if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE + RESOLVED_SOURCE_COUNT) {
        return true;
      }
    }

    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE + RESOLVED_SOURCE_COUNT;
  }
}
