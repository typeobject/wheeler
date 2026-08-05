//! Classifies signed literal-comparison update operations after resolution.

module wheeler.compiler.literal_comparison_operations;

import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;

classical class LiteralComparisonOperations {
  private const long RESOLVED_SOURCE_COUNT = 256;
  private const long RESOLVED_LITERAL_COMPARISON_END = STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE
    + RESOLVED_SOURCE_COUNT;

  /// Checks whether a condition compares with signed less-than.
  public boolean literalComparisonConditionalLessThan(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return false;
    }

    return opcode < RESOLVED_LITERAL_COMPARISON_END;
  }

  /// Checks whether a comparison condition guards subtraction.
  public boolean literalComparisonConditionalSubtract(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

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

  /// Checks whether a comparison condition guards XOR.
  public boolean literalComparisonConditionalXor(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

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

  /// Checks whether a comparison condition guards assignment.
  public boolean literalComparisonConditionalAssignment(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE) {
      return false;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE) {
      return true;
    }

    if (opcode < STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE) {
      return false;
    }

    return opcode < RESOLVED_LITERAL_COMPARISON_END;
  }
}
