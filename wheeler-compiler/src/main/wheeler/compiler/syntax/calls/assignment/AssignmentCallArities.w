//! Classifies bounded source and resolved call-assignment arities.

module wheeler.compiler.assignment_call_arities;

import wheeler.compiler.assignment_call_identities;

classical class AssignmentCallArities {
  /// Returns the exact call-assignment argument count, or minus one.
  public long assignmentCallArity(long opcode) {
    if (opcode == STATEMENT_ASSIGN_CALL_ZERO_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_ONE_NAMED) {
      return 1;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_TWO_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_THREE_NAMED) {
      return 3;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_FOUR_NAMED) {
      return 4;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_FIVE_NAMED) {
      return 5;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_SIX_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_ASSIGN_CALL_SEVEN_NAMED) {
      return MAX_ASSIGNMENT_CALL_ARGUMENTS;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_ZERO_BASE) {
      return -1;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_ONE_BASE) {
      return 0;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_TWO_BASE) {
      return 1;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_THREE_BASE) {
      return 2;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_FOUR_BASE) {
      return 3;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_FIVE_BASE) {
      return 4;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_SIX_BASE) {
      return 5;
    }

    if (opcode < STATEMENT_ASSIGN_CALL_SEVEN_BASE) {
      return 6;
    }

    if (opcode < ASSIGNMENT_CALL_END) {
      return MAX_ASSIGNMENT_CALL_ARGUMENTS;
    }

    return -1;
  }
}
