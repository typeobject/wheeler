//! Classifies unresolved bounded scalar guard returns.

module wheeler.compiler.early_return_kinds;

import wheeler.compiler.statement_kinds;

classical class EarlyReturnKinds {
  private const long EARLY_RETURN_LOCAL_COUNT = 4;
  private const long EARLY_COMPUTED_RETURN_LOCAL_COUNT = 6;
  /// Checks whether one unresolved statement is a supported scalar guard return.
  public boolean earlyReturnStatement(long opcode) {
    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_FALSE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_TRUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_FALSE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_LONG_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_SUB_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_SIGNED_LT_RETURN_DIV_NAMED;
  }

  /// Returns the physical local width of one unresolved early return.
  public long sourceEarlyReturnLocalCount(long opcode) {
    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_SUB_NAMED) {
      return EARLY_COMPUTED_RETURN_LOCAL_COUNT;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_NAMED) {
      return EARLY_COMPUTED_RETURN_LOCAL_COUNT;
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_DIV_NAMED) {
      return EARLY_COMPUTED_RETURN_LOCAL_COUNT;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED) {
      return EARLY_COMPUTED_RETURN_LOCAL_COUNT;
    }

    if (earlyReturnStatement(opcode)) {
      return EARLY_RETURN_LOCAL_COUNT;
    }

    return -1;
  }
}
