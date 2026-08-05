//! Decodes source locals carried by resolved scalar guard returns.

module wheeler.compiler.early_return_sources;

import wheeler.compiler.resolved_statements;

classical class EarlyReturnSources {
  /// Returns the argument source for one resolved helper-call guard.
  public long earlyHelperReturnSource(long opcode) {
    if (opcode < STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE) {
      return opcode - STATEMENT_IF_HELPER_CALL_RETURN_BASE;
    }

    return opcode - STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE;
  }

  /// Returns the signed source local for one resolved comparison guard.
  public long earlyComparisonReturnSource(long opcode) {
    if (opcode < STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE) {
      return opcode - STATEMENT_IF_SIGNED_EQ_RETURN_BASE;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_BASE) {
      return opcode - STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE) {
      return opcode - STATEMENT_IF_SIGNED_LT_RETURN_BASE;
    }

    if (opcode < STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE) {
      return opcode - STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE;
    }

    return opcode - STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE;
  }
}
