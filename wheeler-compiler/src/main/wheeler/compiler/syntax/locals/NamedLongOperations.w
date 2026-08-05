//! Classifies unresolved signed-local arithmetic and update forms.

module wheeler.compiler.named_long_operations;

import wheeler.compiler.statement_kinds;

classical class NamedLongOperations {
  /// Checks for a named signed-local and literal binary declaration.
  public boolean namedLongBinary(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MUL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_DIV_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MOD_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_AND_NAMED;
  }

  /// Checks for a named binary declaration over two signed locals.
  public boolean namedLongPair(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_XOR_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MUL_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_DIV_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_MOD_LOCALS_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_AND_LOCALS_NAMED;
  }

  /// Checks whether a global update reads a prior signed local.
  public boolean namedGlobalUpdate(long opcode) {
    if (opcode == STATEMENT_UPDATE_ADD_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_UPDATE_XOR_LOCAL_NAMED;
  }
}
