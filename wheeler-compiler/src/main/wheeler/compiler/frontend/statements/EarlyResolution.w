//! Resolves bounded early-return guards against prior signed locals.

module wheeler.compiler.early_statement_resolution;

import wheeler.compiler.class_constants;
import wheeler.compiler.local_resolution;
import wheeler.compiler.loop_forms;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
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

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_ADD_NAMED) {
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

  private long comparisonReturnToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long comparisonToken = statementStart + 5;
    if (lessThanGuard(opcode)) {
      comparisonToken = statementStart + 4;
    }

    long comparisonWidth = 1;
    if (utf8Scalar(source, tokenStarts[comparisonToken]) == PUNCTUATION_MINUS) {
      comparisonWidth = 2;
    }

    return comparisonToken + comparisonWidth + 3;
  }

  private long comparisonGuardBase(long opcode) {
    if (lessThanGuard(opcode)) {
      if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_LONG_NAMED) {
        return STATEMENT_IF_SIGNED_LT_RETURN_LONG_BASE;
      }

      if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_ADD_NAMED) {
        return STATEMENT_IF_SIGNED_LT_RETURN_ADD_BASE;
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

    if (opcode == STATEMENT_IF_SIGNED_EQ_RETURN_LONG_NAMED) {
      long equalityReturnedToken = comparisonReturnToken(
        source,
        tokenStarts,
        statementStart,
        opcode
      );
      long equalityReturnedLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        equalityReturnedToken,
        true
      );
      if (-1 < equalityReturnedLocal) {
        return STATEMENT_IF_SIGNED_EQ_RETURN_LOCAL_BASE + sourceLocal;
      }

      long equalityReturnedBoolean = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        equalityReturnedToken,
        false
      );
      if (-1 < equalityReturnedBoolean) {
        return STATEMENT_IF_SIGNED_EQ_RETURN_BOOLEAN_LOCAL_BASE + sourceLocal;
      }

      if (loopOperandNamed(source, tokenStarts, equalityReturnedToken)) {
        if (
          classConstantHasType(source, tokenStarts, tokenLengths, equalityReturnedToken, true)
        ) {} else {
          return -1;
        }
      }
    }

    if (opcode == STATEMENT_IF_SIGNED_LT_RETURN_LONG_NAMED) {
      long orderingReturnedToken = comparisonReturnToken(
        source,
        tokenStarts,
        statementStart,
        opcode
      );
      long orderingReturnedLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        orderingReturnedToken,
        true
      );
      if (-1 < orderingReturnedLocal) {
        return STATEMENT_IF_SIGNED_LT_RETURN_LOCAL_BASE + sourceLocal;
      }

      if (loopOperandNamed(source, tokenStarts, orderingReturnedToken)) {
        if (
          classConstantHasType(source, tokenStarts, tokenLengths, orderingReturnedToken, true)
        ) {} else {
          return -1;
        }
      }
    }

    return comparisonGuardBase(opcode) + sourceLocal;
  }
}
