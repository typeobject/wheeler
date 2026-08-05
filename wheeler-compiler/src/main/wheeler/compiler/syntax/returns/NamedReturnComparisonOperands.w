//! Classifies unresolved scalar comparisons whose right operand is a local.

module wheeler.compiler.named_return_comparison_operands;

import wheeler.compiler.statement_kinds;

classical class NamedReturnComparisonOperands {
  /// Checks whether one direct comparison reads a prior right local.
  public boolean returnComparisonLocalRight(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN_EQ_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NE_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_EQ_LOCAL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_SIGNED_NE_LOCAL_NAMED) {
      return true;
    }

    return opcode == STATEMENT_RETURN_SIGNED_LT_LOCAL_NAMED;
  }
}
