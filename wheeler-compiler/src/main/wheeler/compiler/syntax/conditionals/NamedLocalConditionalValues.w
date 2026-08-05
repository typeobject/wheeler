//! Classifies unresolved Boolean-local conditions with signed value operands.

module wheeler.compiler.named_local_conditional_values;

import wheeler.compiler.statement_kinds;

classical class NamedLocalConditionalValues {
  /// Checks whether a named local condition reads a prior signed value.
  public boolean namedLocalConditionalValue(long opcode) {
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
}
