//! Classifies and decodes resolved scalar local equality.

module wheeler.compiler.resolved_local_equality_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalEqualityKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long EQUALITY_END = STATEMENT_LOCAL_LONG_EQ_BASE + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved local-equality left source.
  public boolean resolvedLocalEquality(long opcode) {
    if (opcode < STATEMENT_LOCAL_BOOLEAN_EQ_BASE) {
      return false;
    }

    return opcode < EQUALITY_END;
  }

  /// Reports whether a resolved local equality compares signed values.
  public boolean resolvedLocalEqualitySigned(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_EQ_BASE) {
      return false;
    }

    return opcode < EQUALITY_END;
  }

  /// Returns the left source local carried by a resolved equality opcode.
  public long resolvedLocalEqualitySource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_EQ_BASE) {
      return opcode - STATEMENT_LOCAL_BOOLEAN_EQ_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_EQ_BASE;
  }
}
