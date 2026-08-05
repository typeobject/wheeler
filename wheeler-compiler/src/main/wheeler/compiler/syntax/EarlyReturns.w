//! Validates bounded scalar guards with one literal return.

module wheeler.compiler.early_return_forms;

import wheeler.compiler.class_constants;
import wheeler.compiler.early_return_result_kinds;
import wheeler.compiler.loop_forms;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class EarlyReturnForms {
  private long scalarReturnWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long returnToken,
    boolean signedResult
  ) {
    if (signedResult) {
      if (loopOperandNamed(source, tokenStarts, returnToken)) {
        if (
          classConstantHasType(source, tokenStarts, tokenLengths, returnToken, true)
        ) {
          return 1;
        }

        return -1;
      }

      long width = signedNumberWidth(source, tokenKinds, tokenStarts, returnToken);
      if (width < 1) {
        return -1;
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, returnToken)) {
        return width;
      }

      return -1;
    }

    long returned = tokenHash(source, tokenStarts, tokenLengths, returnToken);
    if (booleanTokenHash(returned)) {
      return 1;
    }

    return -1;
  }

  /// Returns the exact width of one helper-call guard and scalar return.
  public long earlyHelperReturnWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 4] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 3,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 5,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 6,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 7,
        PUNCTUATION_OPEN_BRACE
      )
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 8) == TOKEN_RETURN
    ) {} else {
      return -1;
    }

    long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    boolean knownForm = sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED;
    if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
      knownForm = true;
    }

    if (helperGuardResultSigned(sourceOpcode)) {
      knownForm = true;
    }

    if (knownForm) {} else {
      return -1;
    }

    long returnWidth = scalarReturnWidth(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStart + 9,
      helperGuardResultSigned(sourceOpcode)
    );
    if (returnWidth < 1) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 9 + returnWidth,
        PUNCTUATION_SEMICOLON
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 10 + returnWidth,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return 11 + returnWidth;
    }

    return -1;
  }

  /// Returns the exact width of one scalar comparison guard and scalar return.
  public long earlyComparisonReturnWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    long comparisonOperator = utf8Scalar(source, tokenStarts[statementStart + 3]);
    long comparisonOperatorWidth = 0;
    if (comparisonOperator == PUNCTUATION_LESS_THAN) {
      comparisonOperatorWidth = 1;
    }

    if (comparisonOperator == PUNCTUATION_ASSIGN) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, PUNCTUATION_ASSIGN)
      ) {
        comparisonOperatorWidth = 2;
      }
    }

    if (0 < comparisonOperatorWidth) {} else {
      return -1;
    }

    long comparisonToken = statementStart + 3 + comparisonOperatorWidth;
    long comparisonWidth = signedNumberWidth(source, tokenKinds, tokenStarts, comparisonToken);
    if (loopOperandNamed(source, tokenStarts, comparisonToken)) {
      comparisonWidth = 1;
      if (
        classConstantHasType(source, tokenStarts, tokenLengths, comparisonToken, true)
      ) {} else {
        return -1;
      }
    } else {
      if (comparisonWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, comparisonToken) == false
      ) {
        return -1;
      }
    }

    long closeCondition = comparisonToken + comparisonWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeCondition, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        closeCondition + 1,
        PUNCTUATION_OPEN_BRACE
      )
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, closeCondition + 2) == TOKEN_RETURN
    ) {} else {
      return -1;
    }

    long sourceOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    boolean knownForm = sourceOpcode == STATEMENT_IF_SIGNED_EQ_RETURN_TRUE_NAMED;
    if (sourceOpcode == STATEMENT_IF_SIGNED_EQ_RETURN_FALSE_NAMED) {
      knownForm = true;
    }

    if (sourceOpcode == STATEMENT_IF_SIGNED_LT_RETURN_TRUE_NAMED) {
      knownForm = true;
    }

    if (sourceOpcode == STATEMENT_IF_SIGNED_LT_RETURN_FALSE_NAMED) {
      knownForm = true;
    }

    if (comparisonGuardResultSigned(sourceOpcode)) {
      knownForm = true;
    }

    if (knownForm) {} else {
      return -1;
    }

    long returnedToken = closeCondition + 3;
    long returnWidth = -1;
    if (comparisonGuardResultComputed(sourceOpcode)) {
      if (
        sameTokenText(source, tokenStarts, tokenLengths, statementStart + 2, returnedToken)
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, returnedToken + 1, PUNCTUATION_MINUS)
      ) {} else {
        return -1;
      }

      long rightWidth = scalarReturnWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        returnedToken + 2,
        true
      );
      if (0 < rightWidth) {
        returnWidth = rightWidth + 2;
      }
    } else {
      returnWidth = scalarReturnWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        returnedToken,
        comparisonGuardResultSigned(sourceOpcode)
      );
    }

    if (returnWidth < 1) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        returnedToken + returnWidth,
        PUNCTUATION_SEMICOLON
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        returnedToken + returnWidth + 1,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return returnedToken + returnWidth + 2 - statementStart;
    }

    return -1;
  }
}
