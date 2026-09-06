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

  /// Checks one signed integer token for canonical syntax.
  public boolean signedNumberValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long magnitudeToken = token;
    if (utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS) {
      magnitudeToken += 1;
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    long magnitude = parseNumber(source, tokenStarts[magnitudeToken], end);
    if (magnitude < 0) {
      return false;
    }

    return true;
  }

  /// Decodes one signed integer token after canonical syntax validation.
  public long parsedSignedNumber(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long magnitudeToken = token;
    long sign = 1;
    if (utf8Scalar(source, tokenStarts[token]) == PUNCTUATION_MINUS) {
      magnitudeToken += 1;
      sign = -1;
    }

    long end = tokenStarts[magnitudeToken] + tokenLengths[magnitudeToken];
    long magnitude = parseNumber(source, tokenStarts[magnitudeToken], end);
    return sign * magnitude;
  }
}
