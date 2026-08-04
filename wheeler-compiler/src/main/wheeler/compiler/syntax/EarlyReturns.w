//! Validates bounded scalar guards that return one Boolean literal.

module wheeler.compiler.early_return_forms;

import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class EarlyReturnForms {
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

    long comparisonWidth = signedNumberWidth(
      source,
      tokenKinds,
      tokenStarts,
      statementStart + 5
    );
    if (comparisonWidth < 1) {
      return -1;
    }

    if (
      signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5) == false
    ) {
      return -1;
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
