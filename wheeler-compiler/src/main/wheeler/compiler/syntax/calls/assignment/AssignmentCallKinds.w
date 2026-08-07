//! Owns bounded call-assignment identities, arities, and register widths.

module wheeler.compiler.assignment_call_kinds;

import wheeler.compiler.assignment_call_identities;

classical class AssignmentCallKinds {
  private const long ASSIGNMENT_CALL_ARGUMENT_CODE_LENGTH = 48;
  private const long ASSIGNMENT_CALL_RESULT_CODE_LENGTH = 64;

  /// Returns one unresolved identity for a bounded argument count.
  public long sourceKind(long arity) {
    if (arity == 0) {
      return STATEMENT_ASSIGN_CALL_ZERO_NAMED;
    }

    if (arity == 1) {
      return STATEMENT_ASSIGN_CALL_ONE_NAMED;
    }

    if (arity == 2) {
      return STATEMENT_ASSIGN_CALL_TWO_NAMED;
    }

    if (arity == 3) {
      return STATEMENT_ASSIGN_CALL_THREE_NAMED;
    }

    if (arity == 4) {
      return STATEMENT_ASSIGN_CALL_FOUR_NAMED;
    }

    if (arity == 5) {
      return STATEMENT_ASSIGN_CALL_FIVE_NAMED;
    }

    if (arity == 6) {
      return STATEMENT_ASSIGN_CALL_SIX_NAMED;
    }

    if (arity == MAX_ASSIGNMENT_CALL_ARGUMENTS) {
      return STATEMENT_ASSIGN_CALL_SEVEN_NAMED;
    }

    return -1;
  }

  private long resolvedBase(long arity) {
    if (arity == 0) {
      return STATEMENT_ASSIGN_CALL_ZERO_BASE;
    }

    if (arity == 1) {
      return STATEMENT_ASSIGN_CALL_ONE_BASE;
    }

    if (arity == 2) {
      return STATEMENT_ASSIGN_CALL_TWO_BASE;
    }

    if (arity == 3) {
      return STATEMENT_ASSIGN_CALL_THREE_BASE;
    }

    if (arity == 4) {
      return STATEMENT_ASSIGN_CALL_FOUR_BASE;
    }

    if (arity == 5) {
      return STATEMENT_ASSIGN_CALL_FIVE_BASE;
    }

    if (arity == 6) {
      return STATEMENT_ASSIGN_CALL_SIX_BASE;
    }

    if (arity == MAX_ASSIGNMENT_CALL_ARGUMENTS) {
      return STATEMENT_ASSIGN_CALL_SEVEN_BASE;
    }

    return -1;
  }

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

  /// Returns the exact call-assignment argument count, or minus one.
  public long assignmentCallArity(long opcode) {
    long arity = 0;
    while (arity < MAX_ASSIGNMENT_CALL_ARGUMENTS + 1) limit 8 {
      if (opcode == sourceKind(arity)) {
        return arity;
      }

      long base = resolvedBase(arity);
      if (base - 1 < opcode) {
        if (opcode < base + RESOLVED_ASSIGNMENT_CALL_TARGET_COUNT) {
          return arity;
        }
      }

      arity += 1;
    }

    return -1;
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

  /// Returns the temporary local width for one call assignment.
  public long assignmentCallLocalCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    return arity * 2 + 1;
  }

  /// Returns the instruction count for one call assignment.
  public long assignmentCallInstructionCount(long opcode) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    return arity * 2 + 2;
  }

  /// Returns the encoded instruction width for one call assignment.
  public long assignmentCallCodeLength(long opcode) {
    long instructions = assignmentCallInstructionCount(opcode);
    if (instructions < 0) {
      return -1;
    }

    long arity = assignmentCallArity(opcode);
    return arity * ASSIGNMENT_CALL_ARGUMENT_CODE_LENGTH + ASSIGNMENT_CALL_RESULT_CODE_LENGTH;
  }
}
