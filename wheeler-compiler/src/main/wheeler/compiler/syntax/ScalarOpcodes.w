//! Classifies resolved scalar copy and comparison opcodes.

module wheeler.compiler.scalar_opcodes;

import wheeler.compiler.loop_kinds;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;

classical class ScalarOpcodes {
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

  /// Checks whether an opcode carries one resolved local-update target.
  public boolean resolvedLocalUpdate(long opcode) {
    if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + 256;
  }

  /// Checks whether a resolved local update reads a prior local.
  public boolean resolvedLocalUpdateNamed(long opcode) {
    if (STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LOCAL_BASE + 256) {
        return true;
      }
    }

    if (STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_UPDATE_SUB_LOCAL_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_UPDATE_XOR_LOCAL_BASE + 256;
  }

  /// Checks whether one statement is an unresolved scalar assignment.
  public boolean localAssignmentSourceStatement(long opcode) {
    if (opcode == STATEMENT_ASSIGN) {
      return true;
    }

    return opcode == STATEMENT_ASSIGN_LOCAL_NAMED;
  }

  /// Checks whether an opcode carries one resolved local-assignment target.
  public boolean resolvedLocalAssignment(long opcode) {
    if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE + 256;
  }

  /// Checks whether a resolved local assignment reads a prior local.
  public boolean resolvedLocalAssignmentNamed(long opcode) {
    if (STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE - 1 < opcode) {
      if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + 256) {
        return true;
      }
    }

    if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE + 256;
  }

  /// Checks whether a resolved local assignment carries Boolean values.
  public boolean resolvedLocalAssignmentBoolean(long opcode) {
    if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE + 256;
  }

  /// Checks whether an opcode carries one resolved bounded while loop.
  public boolean resolvedLocalWhile(long opcode) {
    if (opcode < STATEMENT_LOCAL_WHILE_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_WHILE_BASE + 256 * STATEMENT_LOCAL_WHILE_FORM_COUNT;
  }

  /// Returns the target local carried by one resolved while opcode.
  public long resolvedLocalWhileTarget(long opcode) {
    return(opcode - STATEMENT_LOCAL_WHILE_BASE) / STATEMENT_LOCAL_WHILE_FORM_COUNT;
  }

  /// Returns the form bits carried by one resolved while opcode.
  public long resolvedLocalWhileForm(long opcode) {
    return(opcode - STATEMENT_LOCAL_WHILE_BASE) % STATEMENT_LOCAL_WHILE_FORM_COUNT;
  }

  /// Checks whether a resolved while condition reads a prior local.
  public boolean resolvedLocalWhileConditionNamed(long opcode) {
    return resolvedLocalWhileForm(opcode) % 2 == STATEMENT_LOCAL_WHILE_CONDITION_NAMED;
  }

  /// Checks whether a resolved while limit reads a prior local.
  public boolean resolvedLocalWhileLimitNamed(long opcode) {
    return resolvedLocalWhileForm(opcode) / 2 % 2 == 1;
  }

  /// Checks whether a resolved while compares zero with its target.
  public boolean resolvedLocalWhileReversed(long opcode) {
    return STATEMENT_LOCAL_WHILE_REVERSED_FORM - 1 < resolvedLocalWhileForm(opcode);
  }

  /// Returns the update form carried by one resolved while opcode.
  public long resolvedLocalWhileUpdateForm(long opcode) {
    return resolvedLocalWhileForm(opcode) % STATEMENT_LOCAL_WHILE_REVERSED_FORM / 4 * 4;
  }

  /// Returns the target local carried by one resolved assignment opcode.
  public long resolvedLocalAssignmentTarget(long opcode) {
    if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE) {
      return opcode - STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE;
    }

    if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE) {
      return opcode - STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE;
    }

    return opcode - STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE;
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
