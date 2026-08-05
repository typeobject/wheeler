//! Classifies and decodes resolved checked scalar local updates.

module wheeler.compiler.resolved_local_updates;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalUpdates {
  private const long RESOLVED_TARGET_COUNT = 256;
  private const long ADD_LOCAL_END = STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE + RESOLVED_TARGET_COUNT;
  private const long SUB_LOCAL_END = STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE + RESOLVED_TARGET_COUNT;
  private const long UPDATE_END = STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + RESOLVED_TARGET_COUNT;

  /// Checks whether an opcode carries one resolved local-update target.
  public boolean resolvedLocalUpdate(long opcode) {
    if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
      return false;
    }

    return opcode < UPDATE_END;
  }

  /// Checks whether a resolved local update reads a prior local.
  public boolean resolvedLocalUpdateNamed(long opcode) {
    if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE) {
      return false;
    }

    if (opcode < ADD_LOCAL_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE) {
      return false;
    }

    if (opcode < SUB_LOCAL_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE) {
      return false;
    }

    return opcode < UPDATE_END;
  }

  /// Returns the target local carried by one resolved update opcode.
  public long resolvedLocalUpdateTarget(long opcode) {
    if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
    }

    return opcode - STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE;
  }
}
