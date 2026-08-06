//! Resolves bounded early-return guards against prior signed locals.

module wheeler.compiler.early_statement_resolution;

import wheeler.compiler.local_resolution;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.statement_kinds;

classical class EarlyStatementResolution {
  private boolean helperGuard(long opcode) {
    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
      return true;
    }

    return opcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED;
  }

  private boolean lessThanGuard(long opcode) {
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

  private long helperGuardBase(long opcode) {
    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
      return STATEMENT_IF_HELPER_CALL_RETURN_LONG_BASE;
    }

    if (opcode == STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_NAMED) {
      return STATEMENT_IF_HELPER_CALL_RETURN_HELPER_CALL_BASE;
    }

    return STATEMENT_IF_HELPER_CALL_RETURN_BASE;
  }

  private long comparisonGuardBase(long opcode) {
    if (lessThanGuard(opcode)) {
      if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_LONG_NAMED) {
        return STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE;
      }

      if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_SUB_NAMED) {
        return STATEMENT_IF_SIGNED_LT_RETURN_SUB_BASE;
      }

      if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_NAMED) {
        return STATEMENT_IF_SIGNED_LT_RETURN_REMAINDER_BASE;
      }

      if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_DIV_NAMED) {
        return STATEMENT_IF_SIGNED_LT_RETURN_DIV_BASE;
      }

      return STATEMENT_IF_SIGNED_LT_RETURN_BASE;
    }

    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED) {
      return STATEMENT_IF_SIGNED_EQ_RETURN_LONG_BASE;
    }

    return STATEMENT_IF_SIGNED_EQ_RETURN_BASE;
  }

  /// Resolves one known early-return source statement into its local-index column.
  public long resolveEarlyStatementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount,
    long opcode
  ) {
    long sourceToken = statementStart + 2;
    if (helperGuard(opcode)) {
      sourceToken = statementStart + 4;
    }

    long sourceLocal = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      sourceToken,
      true
    );
    if (-1 < sourceLocal) {} else {
      return -1;
    }

    if (helperGuard(opcode)) {
      return helperGuardBase(opcode) + sourceLocal;
    }

    return comparisonGuardBase(opcode) + sourceLocal;
  }
}
