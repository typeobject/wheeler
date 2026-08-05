//! Classifies and decodes resolved scalar local assignments.

module wheeler.compiler.resolved_local_assignments;

import wheeler.compiler.resolved_statements;

classical class ResolvedLocalAssignments {
  private const long RESOLVED_TARGET_COUNT = 256;
  private const long SIGNED_LOCAL_END = STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE
    + RESOLVED_TARGET_COUNT;
  private const long ASSIGNMENT_END = STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE
    + RESOLVED_TARGET_COUNT;

  /// Checks whether an opcode carries one resolved local-assignment target.
  public boolean resolvedLocalAssignment(long opcode) {
    if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE) {
      return false;
    }

    return opcode < ASSIGNMENT_END;
  }

  /// Checks whether a resolved local assignment reads a prior local.
  public boolean resolvedLocalAssignmentNamed(long opcode) {
    if (opcode < STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE) {
      return false;
    }

    if (opcode < SIGNED_LOCAL_END) {
      return true;
    }

    if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LOCAL_BASE) {
      return false;
    }

    return opcode < ASSIGNMENT_END;
  }

  /// Checks whether a resolved local assignment carries Boolean values.
  public boolean resolvedLocalAssignmentBoolean(long opcode) {
    if (opcode < STATEMENT_LOCAL_ASSIGN_BOOLEAN_LITERAL_BASE) {
      return false;
    }

    return opcode < ASSIGNMENT_END;
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
}
