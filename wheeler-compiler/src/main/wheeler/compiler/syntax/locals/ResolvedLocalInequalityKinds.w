//! Classifies and decodes resolved scalar local inequality.

module wheeler.compiler.resolved_local_inequality_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalInequalityKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long INEQUALITY_END = STATEMENT_LOCAL_LONG_NE_BASE + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved local-inequality left source.
  public boolean resolvedLocalInequality(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_NE_BASE) {
      return false;
    }

    return opcode < INEQUALITY_END;
  }

  /// Reports whether a resolved local inequality compares signed values.
  public boolean resolvedLocalInequalitySigned(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_NE_BASE) {
      return false;
    }

    return opcode < INEQUALITY_END;
  }

  /// Returns the left source local carried by a resolved inequality opcode.
  public long resolvedLocalInequalitySource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_NE_BASE) {
      return opcode - STATEMENT_LOCAL_BOOLEAN_NE_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_NE_BASE;
  }
}
