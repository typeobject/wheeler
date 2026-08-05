//! Classifies unresolved checked scalar local updates.

module wheeler.compiler.named_local_update_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedLocalUpdateKinds {
  /// Checks for one unresolved checked scalar update statement.
  public boolean localUpdateSourceStatement(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_XOR) {
      return true;
    }

    return opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED;
  }
}
