//! Classifies resolved signed literal-comparison update operations.

module wheeler.compiler.resolved_literal_comparison_operations;

import wheeler.compiler.resolved_statements;

classical class ResolvedLiteralComparisonOperations {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RESOLVED_LITERAL_ASSIGNMENT_END = STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether a resolved comparison condition guards subtraction.
  public boolean resolvedLiteralComparisonConditionalSubtract(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE;
  }

  /// Checks whether a resolved comparison condition guards XOR.
  public boolean resolvedLiteralComparisonConditionalXor(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE;
  }

  /// Checks whether a resolved comparison condition guards assignment.
  public boolean resolvedLiteralComparisonConditionalAssignment(long opcode) {
    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE) {
      return false;
    }

    return opcode < RESOLVED_LITERAL_ASSIGNMENT_END;
  }
}
