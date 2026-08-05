//! Classifies resolved signed-local less-than opcodes.

module wheeler.compiler.resolved_local_less_than_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalLessThanKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LESS_THAN_END = STATEMENT_LOCAL_LONG_LT_BASE + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved signed less-than left source.
  public boolean resolvedLocalLongLessThan(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_LT_BASE) {
      return false;
    }

    return opcode < LESS_THAN_END;
  }
}
