//! Classifies and decodes bounded call-assignment identity forms.

module wheeler.compiler.assignment_call_kinds;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_columns;
import wheeler.compiler.assignment_call_identities;

classical class AssignmentCallKinds {
  /// Checks whether one identity is an unresolved call assignment.
  public boolean assignmentCallSourceStatement(long opcode) {
    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_NAMED) {
      return false;
    }

    return opcode < STATEMENT_ASSIGN_CALL_SEVEN_NAMED + 1;
  }

  /// Checks whether one identity is a resolved call assignment.
  public boolean assignmentCallStatement(long opcode) {
    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_BASE) {
      return false;
    }

    return opcode < ASSIGNMENT_CALL_END;
  }

  /// Returns one resolved call-assignment identity.
  public long resolvedAssignmentCall(long arity, long target) {
    if (target < 0) {
      return -1;
    }

    if (target < RESOLVED_ASSIGNMENT_CALL_TARGET_COUNT) {
      long base = resolvedBase(arity);
      return base + target;
    }

    return -1;
  }

  /// Returns the existing signed-local target of one resolved call assignment.
  public long assignmentCallTarget(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long base = resolvedBase(arity);
    return opcode - base;
  }

}
