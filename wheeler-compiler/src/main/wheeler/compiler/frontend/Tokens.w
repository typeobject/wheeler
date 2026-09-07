//! Classifies and decodes bounded source token ranges.

module wheeler.compiler.tokens;

import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.source_words;
import wheeler.lexer.scanner;

classical class Tokens {
  /// Returns an exact source-word code, or zero for unknown words and invalid windows.
  public long sourceTokenCode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    if (token < 0) {
      return 0;
    }

    long lastStartToken = bufferLength(tokenStarts) - 1;
    if (lastStartToken < token) {
      return 0;
    }

    long lastLengthToken = bufferLength(tokenLengths) - 1;
    if (lastLengthToken < token) {
      return 0;
    }

    long start = tokenStarts[token];
    long length = tokenLengths[token];
    long code = sourceWordCode(source, start, length);
    return code;
  }

  /// Checks one token against the exact `rotateRight32` intrinsic name.
  public boolean rotateRight32Token(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long code = sourceTokenCode(source, tokenStarts, tokenLengths, token);
    return code == TOKEN_ROTATE_RIGHT_32;
  }

  /// Checks one token against an exact punctuation scalar.
  public boolean punctuationAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long scalar
  ) {
    if (tokenKinds[token] == 3) {
      return utf8Scalar(source, tokenStarts[token]) == scalar;
    }

    return false;
  }

  /// Checks whether `tokenText` denotes the same canonical value.
  public boolean sameTokenText(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long left,
    long right
  ) {
    if (tokenLengths[left] == tokenLengths[right]) {
      long cursor = 0;
      while (cursor < tokenLengths[left]) limit 256 {
        long leftScalar = utf8Scalar(source, tokenStarts[left] + cursor);
        long rightScalar = utf8Scalar(source, tokenStarts[right] + cursor);
        if (leftScalar < rightScalar) {
          return false;
        }

        if (rightScalar < leftScalar) {
          return false;
        }

        cursor += 1;
      }

      return true;
    }

    return false;
  }

  /// Returns the token width consumed by one signed integer literal.
  public long signedNumberWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token
  ) {
    if (tokenKinds[token] == 2) {
      return 1;
    }

    if (punctuationAt(source, tokenKinds, tokenStarts, token, PUNCTUATION_MINUS)) {
      if (tokenKinds[token + 1] == 2) {
        return 2;
      }
    }

    return -1;
  }

  private boolean numberTokenWindowValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    if (token < 0) {
      return false;
    }

    if (token < bufferLength(tokenStarts)) {} else {
      return false;
    }

    if (token < bufferLength(tokenLengths)) {} else {
      return false;
    }

    long start = tokenStarts[token];
    long length = tokenLengths[token];
    if (start < 0) {
      return false;
    }

    if (length < 1) {
      return false;
    }

    return start < bufferLength(source) - length + 1;
  }

  private NumberValue signedTokenNumber(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    if (numberTokenWindowValid(source, tokenStarts, tokenLengths, token) == false) {
      return new NumberValue(0, false);
    }

    long magnitudeToken = token;
    boolean negative = utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS;
    if (negative) {
      if (tokenLengths[token] == 1) {} else {
        return new NumberValue(0, false);
      }

      magnitudeToken += 1;
      if (
        numberTokenWindowValid(source, tokenStarts, tokenLengths, magnitudeToken) == false
      ) {
        return new NumberValue(0, false);
      }
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    return parseSignedNumber(source, tokenStarts[magnitudeToken], end, negative);
  }

  /// Checks a signed integer in scanner-owned columns without evaluating other tokens.
  public boolean signedNumberValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    NumberValue number = signedTokenNumber(source, tokenStarts, tokenLengths, token);
    return number.valid;
  }

  /// Decodes one signed integer token after canonical syntax validation.
  public long parsedSignedNumber(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    NumberValue number = signedTokenNumber(source, tokenStarts, tokenLengths, token);
    assert(number.valid);
    return number.value;
  }
}
