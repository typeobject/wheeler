//! Maps unresolved conditional forms to their resolved opcode columns.

module wheeler.compiler.named_conditional_bases;

import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;

classical class NamedConditionalBases {
  /// Returns the resolved base for one signed comparison condition.
  public long namedLiteralComparisonConditionalBase(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_XOR_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_NAMED) {
      return STATEMENT_IF_LOCAL_EQ_LITERAL_ASSIGN_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_ADD_NAMED) {
      return STATEMENT_IF_LOCAL_LT_LITERAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_SUB_NAMED) {
      return STATEMENT_IF_LOCAL_LT_LITERAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_LT_LITERAL_XOR_NAMED) {
      return STATEMENT_IF_LOCAL_LT_LITERAL_XOR_BASE;
    }

    return STATEMENT_IF_LOCAL_LT_LITERAL_ASSIGN_BASE;
  }

  /// Returns the resolved opcode base for one named local condition.
  public long namedLocalConditionalBase(long opcode) {
    if (opcode == STATEMENT_IF_LOCAL_ADD_NAMED) {
      return STATEMENT_IF_LOCAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_NAMED) {
      return STATEMENT_IF_LOCAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_NAMED) {
      return STATEMENT_IF_LOCAL_XOR_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ADD_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_SUB_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_XOR_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_XOR_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_NAMED) {
      return STATEMENT_IF_LOCAL_ASSIGN_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ASSIGN_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_ASSIGN_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_ASSIGN_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ASSIGN_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_ADD_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_ADD_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_SUB_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_SUB_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_LOCAL_XOR_VALUE_NAMED) {
      return STATEMENT_IF_LOCAL_XOR_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_ADD_VALUE_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_ADD_VALUE_BASE;
    }

    if (opcode == STATEMENT_IF_NOT_LOCAL_SUB_VALUE_NAMED) {
      return STATEMENT_IF_NOT_LOCAL_SUB_VALUE_BASE;
    }

    return STATEMENT_IF_NOT_LOCAL_XOR_VALUE_BASE;
  }
}
