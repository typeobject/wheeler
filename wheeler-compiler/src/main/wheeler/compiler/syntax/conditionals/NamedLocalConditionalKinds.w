//! Classifies unresolved Boolean-local conditional forms.

module wheeler.compiler.named_local_conditional_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedLocalConditionalKinds {
  /// Checks for a named one-arm Boolean condition guarding a global update.
  public boolean namedLocalConditional(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
  }

  /// Checks whether a named local condition negates its Boolean source.
  public boolean namedLocalConditionalNegated(long opcode) {
    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_XOR_VALUE_NAMED;
  }

  /// Checks whether a named local condition guards assignment.
  public boolean namedLocalConditionalAssignment(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }

  /// Checks whether a named local condition assigns another local.
  public boolean namedLocalConditionalAssignmentValue(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED;
  }
}
