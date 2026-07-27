//! Parses bounded local conditions in the bootstrap source profile.

module wheeler.compiler.conditionals;

import wheeler.compiler.local_opcodes;
import wheeler.compiler.tokens;

classical class Conditionals {
  /// Returns the token width of one supported local condition.
  public long conditionalStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (namedLocalConditional(statementKind) == false) {
      return -1;
    }

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

    long conditionToken = statementStart + 2;
    long bodyShift = 0;
    if (namedLocalConditionalNegated(statementKind)) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, conditionToken, PUNCTUATION_BANG) == false
      ) {
        return -1;
      }

      conditionToken += 1;
      bodyShift = 1;
    }

    if (tokenKinds[conditionToken] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 3 + bodyShift,
        PUNCTUATION_CLOSE_PAREN
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 4 + bodyShift,
        PUNCTUATION_OPEN_BRACE
      ) == false
    ) {
      return -1;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, 6, statementStart + 5 + bodyShift) == false
    ) {
      return -1;
    }

    long operatorToken = statementStart + 7 + bodyShift;
    long operandToken = statementStart + 8 + bodyShift;
    if (namedLocalConditionalAssignment(statementKind)) {
      operatorToken -= 1;
      operandToken -= 1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, operatorToken, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long operandWidth = signedNumberWidth(source, tokenKinds, tokenStarts, operandToken);
    if (namedLocalConditionalAssignmentValue(statementKind)) {
      if (tokenKinds[operandToken] == 1) {
        operandWidth = 1;
      }
    }

    if (operandWidth < 1) {
      return -1;
    }

    if (namedLocalConditionalAssignmentValue(statementKind) == false) {
      if (signedNumberValid(source, tokenStarts, tokenLengths, operandToken) == false) {
        return -1;
      }
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        operandToken + operandWidth,
        PUNCTUATION_SEMICOLON
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        operandToken + operandWidth + 1,
        PUNCTUATION_CLOSE_BRACE
      ) == false
    ) {
      return -1;
    }

    return operandToken - statementStart + operandWidth + 2;
  }
}
