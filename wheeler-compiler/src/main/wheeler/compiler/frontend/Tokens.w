//! Classifies and decodes bounded source token ranges.

module wheeler.compiler.tokens;

import wheeler.compiler.source_scalars;
import wheeler.lexer.scanner;

classical class Tokens {
  /// Caps compiler token metadata before comment compaction.
  public const long MAX_COMPILER_TOKENS = 2048;
  /// Reserves the unused final token cell for the resolved global name.
  public const long COMPILER_GLOBAL_NAME_TOKEN = MAX_COMPILER_TOKENS - 1;
  /// Distinguishes Boolean parameter markers from signed parameter markers.
  public const long BOOLEAN_PARAMETER_TOKEN_BIAS = MAX_COMPILER_TOKENS;
  /// Caps direct imports in one bounded compiler source.
  public const long MAX_MODULE_IMPORTS = 64;
  /// Caps tokens consumed by one module or import name.
  public const long MAX_QUALIFIED_NAME_TOKENS = 64;
  /// Caps UTF-8 bytes compared in one module or import name.
  public const long MAX_QUALIFIED_NAME_BYTES = 256;
  /// Caps hashing at the accepted 256-byte identifier ceiling.
  public const long MAX_TOKEN_HASH_SCALARS = 256;
  /// Keeps one hash multiplication within the positive signed range.
  public const long TOKEN_HASH_INPUT_MASK = 288230376151711743;

  /// Names the byte width of `rotateRight32`.
  public const long ROTATE_RIGHT_32_NAME_BYTES = 13;
  /// Names the prefix width used for bounded `rotateRight32` hashing.
  public const long ROTATE_RIGHT_32_PREFIX_BYTES = 6;
  /// Names the stable prefix hash for `rotateRight32`.
  public const long TOKEN_ROTATE_RIGHT_32_PREFIX = 3369786715;
  /// Names the stable suffix hash for `rotateRight32`.
  public const long TOKEN_ROTATE_RIGHT_32_SUFFIX = 75879696731;
  /// Computes the stable hash of one bounded source token.
  public long tokenHash(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long cursor = tokenStarts[token];
    long end = cursor + tokenLengths[token];
    long hash = 0;
    while (cursor < end) limit MAX_TOKEN_HASH_SCALARS {
      hash = (hash & TOKEN_HASH_INPUT_MASK) * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
  }

  private long tokenRangeHash(borrow utf8 source, long start, long length) {
    long cursor = start;
    long end = start + length;
    long hash = 0;
    while (cursor < end) limit 8 {
      hash = (hash & TOKEN_HASH_INPUT_MASK) * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
  }

  /// Checks one token against the exact `rotateRight32` intrinsic name.
  public boolean rotateRight32Token(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    if (tokenLengths[token] == ROTATE_RIGHT_32_NAME_BYTES) {
      long start = tokenStarts[token];
      if (
        tokenRangeHash(source, start, ROTATE_RIGHT_32_PREFIX_BYTES) == TOKEN_ROTATE_RIGHT_32_PREFIX
      ) {
        return tokenRangeHash(
          source,
          start + ROTATE_RIGHT_32_PREFIX_BYTES,
          ROTATE_RIGHT_32_NAME_BYTES - ROTATE_RIGHT_32_PREFIX_BYTES
        ) == TOKEN_ROTATE_RIGHT_32_SUFFIX;
      }
    }

    return false;
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
