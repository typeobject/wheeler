//! Locates direct signed ordering assertions without binding operand values.

module wheeler.compiler.signed_ordering_syntax;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SignedOrderingSyntax {
  /// Retains both operand starts and the complete assertion tail.
  public record SignedOrderingFront(
    long leftToken,
    long rightToken,
    long nextToken,
    boolean valid
  ) {}

  private boolean scalarAt(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long token,
    long scalar
  ) {
    if (lengths[token] == 1) {
      return utf8Scalar(source, starts[token]) == scalar;
    }

    return false;
  }

  private long operatorAfterLeft(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long first
  ) {
    long operator = first + 1;
    if (scalarAt(source, starts, lengths, first, PUNCTUATION_MINUS)) {
      operator += 1;
    }

    return operator;
  }

  /// Selects the ordering parser before global equality or literal equality fallback.
  /// The statement scanner owns the complete canonical token columns.
  public boolean signedOrderingCandidate(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long statementStart
  ) {
    if (statementStart < 0) {
      return false;
    }

    if (MAX_COMPILER_TOKENS - 5 < statementStart) {
      return false;
    }

    if (bufferLength(starts) < MAX_COMPILER_TOKENS) {
      return false;
    }

    if (bufferLength(lengths) < MAX_COMPILER_TOKENS) {
      return false;
    }

    long operator = operatorAfterLeft(source, starts, lengths, statementStart + 2);
    return scalarAt(source, starts, lengths, operator, PUNCTUATION_LESS_THAN);
  }

  /// Projects the right operand only after the complete front has been admitted.
  public long signedOrderingRightToken(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long statementStart
  ) {
    return operatorAfterLeft(source, starts, lengths, statementStart + 2) + 1;
  }

  private long operandEnd(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long first,
    long count
  ) {
    if (first < count) {} else {
      return -1;
    }

    if (kinds[first] == 1) {
      return first + 1;
    }

    if (kinds[first] == 2) {
      return first + 1;
    }

    if (first + 1 < count) {
      if (punctuationAt(source, kinds, starts, first, PUNCTUATION_MINUS)) {
        if (kinds[first + 1] == 2) {
          return first + 2;
        }
      }
    }

    return -1;
  }

  /// Locates two scalar operand fronts and exact closing punctuation in a counted window.
  /// Literal range checks and name resolution remain separate from this syntax product.
  public SignedOrderingFront signedOrderingFront(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long statementStart,
    long count
  ) {
    SignedOrderingFront invalid = new SignedOrderingFront(-1, -1, -1, false);
    if (count < 0) {
      return invalid;
    }

    if (MAX_COMPILER_TOKENS < count) {
      return invalid;
    }

    if (statementStart < 0) {
      return invalid;
    }

    if (count - 2 < statementStart) {
      return invalid;
    }

    if (bufferLength(kinds) < count) {
      return invalid;
    }

    if (bufferLength(starts) < count) {
      return invalid;
    }

    if (bufferLength(lengths) < count) {
      return invalid;
    }

    if (sourceTokenCode(source, starts, lengths, statementStart) == TOKEN_ASSERT) {} else {
      return invalid;
    }

    if (
      punctuationAt(source, kinds, starts, statementStart + 1, PUNCTUATION_OPEN_PAREN)
    ) {} else {
      return invalid;
    }

    long left = statementStart + 2;
    long operator = operandEnd(source, kinds, starts, left, count);
    if (operator < 0) {
      return invalid;
    }

    if (operator < count) {} else {
      return invalid;
    }

    if (punctuationAt(source, kinds, starts, operator, PUNCTUATION_LESS_THAN)) {} else {
      return invalid;
    }

    long right = operator + 1;
    long close = operandEnd(source, kinds, starts, right, count);
    if (close < 0) {
      return invalid;
    }

    if (close < count - 1) {} else {
      return invalid;
    }

    if (punctuationAt(source, kinds, starts, close, PUNCTUATION_CLOSE_PAREN)) {} else {
      return invalid;
    }

    if (punctuationAt(source, kinds, starts, close + 1, PUNCTUATION_SEMICOLON)) {} else {
      return invalid;
    }

    return new SignedOrderingFront(left, right, close + 2, true);
  }
}
