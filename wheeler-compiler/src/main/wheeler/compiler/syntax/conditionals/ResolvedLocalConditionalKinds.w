//! Classifies resolved Boolean-local conditional forms.

module wheeler.compiler.resolved_local_conditional_kinds;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalConditionalKinds {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long LOCAL_XOR_END = STATEMENT_IF_LOCAL_XOR_BASE + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_XOR_END = STATEMENT_IF_NOT_LOCAL_XOR_BASE + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_ASSIGN_END = STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_ASSIGN_VALUE_END = STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;
  private const long NOT_LOCAL_XOR_VALUE_END = STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether an opcode carries a resolved local conditional source.
  public boolean resolvedLocalConditional(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ADD_BASE) {
      return false;
    }

    if (opcode < LOCAL_XOR_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_XOR_VALUE_END;
  }

  /// Checks whether a resolved local condition negates its Boolean source.
  public boolean resolvedLocalConditionalNegated(long opcode) {
    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_BASE) {
      return false;
    }

    if (opcode < NOT_LOCAL_XOR_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE) {
      return false;
    }

    if (opcode < NOT_LOCAL_ASSIGN_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    if (opcode < NOT_LOCAL_ASSIGN_VALUE_END) {
      return true;
    }

    if (opcode < STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_XOR_VALUE_END;
  }

  /// Checks whether a resolved local condition guards assignment.
  public boolean resolvedLocalConditionalAssignment(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_ASSIGN_VALUE_END;
  }

  /// Checks whether a resolved condition assigns a prior signed local.
  public boolean resolvedLocalConditionalAssignmentValue(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE) {
      return false;
    }

    return opcode < NOT_LOCAL_ASSIGN_VALUE_END;
  }
}
