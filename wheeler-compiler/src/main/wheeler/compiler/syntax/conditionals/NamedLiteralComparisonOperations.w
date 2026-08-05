//! Classifies unresolved signed literal-comparison update operations.

module wheeler.compiler.named_literal_comparison_operations;

import wheeler.compiler.statement_kinds;

classical class NamedLiteralComparisonOperations {
  /// Checks whether a named comparison condition guards subtraction.
  public boolean namedLiteralComparisonConditionalSubtract(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED;
  }

  /// Checks whether a named comparison condition guards XOR.
  public boolean namedLiteralComparisonConditionalXor(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED;
  }

  /// Checks whether a named comparison condition guards assignment.
  public boolean namedLiteralComparisonConditionalAssignment(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
  }
}
