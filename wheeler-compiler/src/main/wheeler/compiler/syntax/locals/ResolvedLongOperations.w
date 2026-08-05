//! Classifies and decodes resolved signed-local arithmetic sources.

module wheeler.compiler.resolved_long_operations;

import wheeler.compiler.resolved_statements;

classical class ResolvedLongOperations {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LONG_XOR_END = STATEMENT_LOCAL_LONG_XOR_BASE + RESOLVED_SOURCE_COUNT;
  private const long LONG_MOD_END = STATEMENT_LOCAL_LONG_MOD_BASE + RESOLVED_SOURCE_COUNT;
  private const long LONG_AND_END = STATEMENT_LOCAL_LONG_AND_BASE + RESOLVED_SOURCE_COUNT;
  private const long LONG_XOR_LOCALS_END = STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long LONG_MOD_LOCALS_END = STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long LONG_AND_LOCALS_END = STATEMENT_LOCAL_LONG_AND_LOCALS_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved signed-local binary source.
  public boolean resolvedLocalLongBinary(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_ADD_BASE) {
      return false;
    }

    if (opcode < LONG_XOR_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MUL_BASE) {
      return false;
    }

    if (opcode < LONG_MOD_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_LONG_AND_BASE) {
      return false;
    }

    return opcode < LONG_AND_END;
  }

  /// Returns the source local carried by a resolved signed binary opcode.
  public long resolvedLocalLongBinarySource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_BASE;
    }

    if (opcode < LONG_XOR_END) {
      return opcode - STATEMENT_LOCAL_LONG_XOR_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_DIV_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_MUL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MOD_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_DIV_BASE;
    }

    if (opcode < LONG_MOD_END) {
      return opcode - STATEMENT_LOCAL_LONG_MOD_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_AND_BASE;
  }

  /// Checks whether an opcode carries the left source of a signed-local pair.
  public boolean resolvedLocalLongPair(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE) {
      return false;
    }

    if (opcode < LONG_XOR_LOCALS_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE) {
      return false;
    }

    if (opcode < LONG_MOD_LOCALS_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_LONG_AND_LOCALS_BASE) {
      return false;
    }

    return opcode < LONG_AND_LOCALS_END;
  }

  /// Returns the left source local carried by a resolved signed-local pair opcode.
  public long resolvedLocalLongPairSource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_LOCALS_BASE;
    }

    if (opcode < LONG_XOR_LOCALS_END) {
      return opcode - STATEMENT_LOCAL_LONG_XOR_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_MUL_LOCALS_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_DIV_LOCALS_BASE;
    }

    if (opcode < LONG_MOD_LOCALS_END) {
      return opcode - STATEMENT_LOCAL_LONG_MOD_LOCALS_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_AND_LOCALS_BASE;
  }
}
