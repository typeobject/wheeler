//! Validates bounded scalar guards that return one Boolean literal.

module wheeler.compiler.early_return_forms;

import wheeler.compiler.class_constants;
import wheeler.compiler.loop_forms;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class EarlyReturnForms {
  /// Returns the exact width of one helper-call guard and Boolean return.
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

    long returned = tokenHash(source, tokenStarts, tokenLengths, statementStart + 9);
    if (booleanTokenHash(returned)) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 10,
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
        statementStart + 11,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return 12;
    }

    return -1;
  }

  /// Returns the exact width of one scalar equality guard and Boolean return.
  public long earlyBooleanReturnWidth(
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    long comparisonToken = statementStart + 5;
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

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 5 + comparisonWidth,
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
        statementStart + 6 + comparisonWidth,
        PUNCTUATION_OPEN_BRACE
      )
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 7 + comparisonWidth)
        == TOKEN_RETURN
    ) {} else {
      return -1;
    }

    long returned = tokenHash(
      source,
      tokenStarts,
      tokenLengths,
      statementStart + 8 + comparisonWidth
    );
    if (booleanTokenHash(returned)) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 9 + comparisonWidth,
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
        statementStart + 10 + comparisonWidth,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return 11 + comparisonWidth;
    }

    return -1;
  }
}
