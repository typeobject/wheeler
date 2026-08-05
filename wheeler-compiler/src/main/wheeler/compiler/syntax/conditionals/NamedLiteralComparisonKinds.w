//! Classifies unresolved signed literal-comparison condition forms.

module wheeler.compiler.named_literal_comparison_kinds;

import wheeler.compiler.statement_kinds;

classical class NamedLiteralComparisonKinds {
  /// Checks for a named signed literal-comparison condition.
  public boolean namedLiteralComparisonConditional(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
  }

  /// Checks whether a named condition compares with signed less-than.
  public boolean namedLiteralComparisonConditionalLessThan(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_NAMED;
  }
}
