//! Classifies and decodes resolved scalar local returns.

module wheeler.compiler.resolved_local_returns;

import wheeler.compiler.resolved_local_return_statements;

classical class ResolvedLocalReturns {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long STATEMENT_RETURN_BOOLEAN_LOCAL_END = STATEMENT_RETURN_BOOLEAN_LOCAL_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode returns one resolved local.
  public boolean resolvedLocalReturn(long opcode) {
    if (opcode < STATEMENT_RETURN_SIGNED_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_RETURN_BOOLEAN_LOCAL_END;
  }

  /// Returns the source local carried by a resolved return opcode.
  public long resolvedLocalReturnSource(long opcode) {
    if (opcode < STATEMENT_RETURN_SIGNED_LOCAL_BASE) {
      return opcode - STATEMENT_RETURN_BOOLEAN_LOCAL_BASE;
    }

    if (opcode < STATEMENT_RETURN_BOOLEAN_LOCAL_BASE) {
      return opcode - STATEMENT_RETURN_SIGNED_LOCAL_BASE;
    }

    return opcode - STATEMENT_RETURN_BOOLEAN_LOCAL_BASE;
  }
}
