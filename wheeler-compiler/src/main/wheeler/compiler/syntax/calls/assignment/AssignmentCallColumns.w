//! Maps bounded call-assignment arities to source and resolved identities.

module wheeler.compiler.assignment_call_columns;

import wheeler.compiler.assignment_call_identities;

classical class AssignmentCallColumns {
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

  /// Returns one resolved target-column base for a bounded argument count.
  public long resolvedBase(long arity) {
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

}
