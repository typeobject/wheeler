//! Validates bounded signed-local loop statement forms.

module wheeler.compiler.loop_forms;

import wheeler.compiler.tokens;

classical class LoopForms {
  private const long ASCII_BEFORE_UPPER = 64;
  private const long ASCII_AFTER_UPPER = 91;
  private const long ASCII_UNDERSCORE = 95;
  private const long ASCII_BEFORE_LOWER = 96;
  private const long ASCII_AFTER_LOWER = 123;

  /// Checks whether one loop operand token starts an identifier.
  public boolean loopOperandNamed(borrow utf8 source, borrow mut words tokenStarts, long token) {
    long scalar = utf8Scalar(source, tokenStarts[token]);
    boolean named = scalar == ASCII_UNDERSCORE;
    if (ASCII_BEFORE_UPPER < scalar) {
      if (scalar < ASCII_AFTER_UPPER) {
        named = true;
      }
    }

    if (ASCII_BEFORE_LOWER < scalar) {
      if (scalar < ASCII_AFTER_LOWER) {
        named = true;
      }
    }

    return named;
  }

  /// Checks whether one loop compares zero with its target local.
  public boolean whileReversed(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    return utf8Scalar(source, tokenStarts[statementStart + 2]) == SCALAR_DIGIT_ZERO;
  }

  /// Returns the token carrying one loop target local.
  public long whileTargetToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (whileReversed(source, tokenStarts, statementStart)) {
      return statementStart + 4;
    }

    return statementStart + 2;
  }

  /// Returns the token carrying the condition value beside one loop target.
  public long whileConditionValueToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (whileReversed(source, tokenStarts, statementStart)) {
      return statementStart + 2;
    }

    return statementStart + 4;
  }

  /// Returns the token carrying one loop limit.
  public long whileLimitToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    long conditionWidth = 1;
    if (utf8Scalar(source, tokenStarts[statementStart + 4]) == PUNCTUATION_MINUS) {
      conditionWidth = 2;
    }

    return statementStart + 6 + conditionWidth;
  }

  /// Returns the token carrying one loop update target.
  public long whileUpdateTargetToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    long limitToken = whileLimitToken(source, tokenStarts, statementStart);
    long limitWidth = 1;
    if (utf8Scalar(source, tokenStarts[limitToken]) == PUNCTUATION_MINUS) {
      limitWidth = 2;
    }

    return limitToken + limitWidth + 1;
  }

  /// Returns the resolved update form selected by one loop.
  public long whileUpdateForm(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long updateTarget
  ) {
    long operator = utf8Scalar(source, tokenStarts[updateTarget + 1]);
    if (operator == PUNCTUATION_MINUS) {
      return STATEMENT_LOCAL_WHILE_SUB_FORM;
    }

    if (operator == PUNCTUATION_CARET) {
      return STATEMENT_LOCAL_WHILE_XOR_FORM;
    }

    return 0;
  }

  /// Returns the token width of one bounded signed-local while loop.
  public long whileStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      ) == false
    ) {
      return -1;
    }

    boolean reversed = whileReversed(source, tokenStarts, statementStart);
    long targetToken = whileTargetToken(source, tokenStarts, statementStart);
    if (tokenKinds[targetToken] == 1) {} else {
      return -1;
    }

    if (reversed) {
      if (tokenLengths[statementStart + 2] == 1) {} else {
        return -1;
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_LESS_THAN)
        == false
    ) {
      return -1;
    }

    long conditionRight = statementStart + 4;
    long conditionWidth = 1;
    if (reversed) {} else {
      if (tokenKinds[conditionRight] == 1) {} else {
        conditionWidth = signedNumberWidth(source, tokenKinds, tokenStarts, conditionRight);
        if (conditionWidth < 1) {
          return -1;
        }

        if (
          signedNumberValid(source, tokenStarts, tokenLengths, conditionRight) == false
        ) {
          return -1;
        }
      }
    }

    long closeCondition = conditionRight + conditionWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeCondition, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, closeCondition + 1) == TOKEN_LIMIT
    ) {} else {
      return -1;
    }

    long limitToken = closeCondition + 2;
    long limitWidth = 1;
    if (tokenKinds[limitToken] == 1) {} else {
      limitWidth = signedNumberWidth(source, tokenKinds, tokenStarts, limitToken);
      if (limitWidth < 1) {
        return -1;
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, limitToken) == false) {
        return -1;
      }
    }

    long openBody = limitToken + limitWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, openBody, PUNCTUATION_OPEN_BRACE) == false
    ) {
      return -1;
    }

    long updateTarget = openBody + 1;
    if (tokenKinds[updateTarget] == 1) {} else {
      return -1;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, targetToken, updateTarget) == false
    ) {
      return -1;
    }

    long updateOperator = utf8Scalar(source, tokenStarts[updateTarget + 1]);
    boolean acceptedOperator = updateOperator == PUNCTUATION_PLUS;
    if (updateOperator == PUNCTUATION_MINUS) {
      acceptedOperator = true;
    }

    if (updateOperator == PUNCTUATION_CARET) {
      acceptedOperator = true;
    }

    if (acceptedOperator == false) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, updateTarget + 2, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[updateTarget + 3]) == SCALAR_DIGIT_ONE) {} else {
      return -1;
    }

    if (tokenLengths[updateTarget + 3] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, updateTarget + 4, PUNCTUATION_SEMICOLON)
        == false
    ) {
      return -1;
    }

    long closeBody = updateTarget + 5;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeBody, PUNCTUATION_CLOSE_BRACE)
    ) {
      return closeBody - statementStart + 1;
    }

    return -1;
  }
}
