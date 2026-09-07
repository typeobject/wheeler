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

    return opcode < ASSIGNMENT_CALL_SOURCE_END;
  }

  /// Checks whether one identity is a resolved call assignment.
  public boolean assignmentCallStatement(long opcode) {
    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_BASE) {
      return false;
    }

    return opcode < GLOBAL_ASSIGNMENT_CALL_END;
  }

  /// Checks whether one resolved call stores into the retained signed class state.
  public boolean globalAssignmentCallStatement(long opcode) {
    if (opcode < STATEMENT_GLOBAL_ASSIGN_CALL_BASE) {
      return false;
    }

    return opcode < GLOBAL_ASSIGNMENT_CALL_END;
  }

  /// Returns one resolved global call-assignment identity.
  public long resolvedGlobalAssignmentCall(long arity) {
    long base = resolvedBase(arity);
    if (base < 0) {
      return -1;
    }

    return arity + STATEMENT_GLOBAL_ASSIGN_CALL_BASE;
  }

  /// Returns one resolved call-assignment identity.
  public long resolvedAssignmentCall(long arity, long target) {
    if (target < 0) {
      return -1;
    }

    long base = resolvedBase(arity);
    if (base < 0) {
      return -1;
    }

    if (target < RESOLVED_ASSIGNMENT_CALL_TARGET_COUNT) {
      return target + base;
    }

    return -1;
  }

  /// Returns the local column or bound class-state ordinal of one resolved assignment.
  public long assignmentCallTarget(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_BASE) {
      return -1;
    }

    long globalBase = opcode - arity;
    if (globalBase == STATEMENT_GLOBAL_ASSIGN_CALL_BASE) {
      return 0;
    }

    long base = resolvedBase(arity);
    return opcode - base;
  }

}
