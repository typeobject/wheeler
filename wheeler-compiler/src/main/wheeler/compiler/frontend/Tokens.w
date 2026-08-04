//! Classifies and decodes bounded source token ranges.

module wheeler.compiler.tokens;

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

  /// Names the stable token hash for `module`.
  public const long TOKEN_MODULE = 3226183276;
  /// Names the stable token hash for `import`.
  public const long TOKEN_IMPORT = 3110171557;
  /// Names the stable token hash for `public`.
  public const long TOKEN_PUBLIC = 3317543529;
  /// Names the stable token hash for `private`.
  public const long TOKEN_PRIVATE = 102764717443;
  /// Names the stable token hash for `classical`.
  public const long TOKEN_CLASSICAL = 87497064671293;
  /// Names the stable token hash for `class`.
  public const long TOKEN_CLASS = 94742904;
  /// Names the stable token hash for `state`.
  public const long TOKEN_STATE = 109757585;
  /// Names the stable token hash for `entry`.
  public const long TOKEN_ENTRY = 96667762;
  /// Names the stable token hash for `void`.
  public const long TOKEN_VOID = 3625364;
  /// Names the stable token hash for `main`.
  public const long TOKEN_MAIN = 3343801;
  /// Names the stable token hash for `rev`.
  public const long TOKEN_REV = 112803;
  /// Names the stable token hash for `reverse`.
  public const long TOKEN_REVERSE = 104179061474;
  /// Names the stable token hash for `theorem`.
  public const long TOKEN_THEOREM = 106024553916;
  /// Names the stable token hash for `proves`.
  public const long TOKEN_PROVES = 3315169751;
  /// Names the stable token hash for `inverse`.
  public const long TOKEN_INVERSE = 96449190704;
  /// Names the stable token hash for `assert`.
  public const long TOKEN_ASSERT = 2886759238;
  /// Names the stable token hash for `if`.
  public const long TOKEN_IF = 3357;
  /// Names the stable token hash for `while`.
  public const long TOKEN_WHILE = 113101617;
  /// Names the stable token hash for `limit`.
  public const long TOKEN_LIMIT = 102976443;
  /// Names the stable token hash for `long`.
  public const long TOKEN_LONG = 3327612;
  /// Names the stable token hash for `boolean`.
  public const long TOKEN_BOOLEAN = 90259024936;
  /// Names the stable token hash for `true`.
  public const long TOKEN_TRUE = 3569038;
  /// Names the stable token hash for `false`.
  public const long TOKEN_FALSE = 97196323;
  /// Names the byte width of `rotateRight32`.
  public const long ROTATE_RIGHT_32_NAME_BYTES = 13;
  /// Names the prefix width used for bounded `rotateRight32` hashing.
  public const long ROTATE_RIGHT_32_PREFIX_BYTES = 6;
  /// Names the stable prefix hash for `rotateRight32`.
  public const long TOKEN_ROTATE_RIGHT_32_PREFIX = 3369786715;
  /// Names the stable suffix hash for `rotateRight32`.
  public const long TOKEN_ROTATE_RIGHT_32_SUFFIX = 75879696731;
  /// Names the stable token hash for `return`.
  public const long TOKEN_RETURN = 3360570672;

  /// Names the ASCII scalar for the canonical digit `0`.
  public const long SCALAR_DIGIT_ZERO = 48;
  /// Names the ASCII scalar for the canonical digit `1`.
  public const long SCALAR_DIGIT_ONE = 49;
  /// Names the ASCII scalar for the canonical digit `9`.
  public const long SCALAR_DIGIT_NINE = 57;
  /// Names the ASCII `!` punctuation scalar.
  public const long PUNCTUATION_BANG = 33;
  /// Names the ASCII `%` punctuation scalar.
  public const long PUNCTUATION_PERCENT = 37;
  /// Names the ASCII `&` punctuation scalar.
  public const long PUNCTUATION_AMPERSAND = 38;
  /// Names the ASCII `(` punctuation scalar.
  public const long PUNCTUATION_OPEN_PAREN = 40;
  /// Names the ASCII `)` punctuation scalar.
  public const long PUNCTUATION_CLOSE_PAREN = 41;
  /// Names the ASCII `*` punctuation scalar.
  public const long PUNCTUATION_STAR = 42;
  /// Names the ASCII `+` punctuation scalar.
  public const long PUNCTUATION_PLUS = 43;
  /// Names the ASCII `,` punctuation scalar.
  public const long PUNCTUATION_COMMA = 44;
  /// Names the ASCII `.` punctuation scalar.
  public const long PUNCTUATION_DOT = 46;
  /// Names the ASCII `-` punctuation scalar.
  public const long PUNCTUATION_MINUS = 45;
  /// Names the ASCII `/` punctuation scalar.
  public const long PUNCTUATION_SLASH = 47;
  /// Names the ASCII `:` punctuation scalar.
  public const long PUNCTUATION_COLON = 58;
  /// Names the ASCII `;` punctuation scalar.
  public const long PUNCTUATION_SEMICOLON = 59;
  /// Names the ASCII `<` punctuation scalar.
  public const long PUNCTUATION_LESS_THAN = 60;
  /// Names the ASCII `=` punctuation scalar.
  public const long PUNCTUATION_ASSIGN = 61;
  /// Names the ASCII `^` punctuation scalar.
  public const long PUNCTUATION_CARET = 94;
  /// Names the ASCII `{` punctuation scalar.
  public const long PUNCTUATION_OPEN_BRACE = 123;
  /// Names the ASCII `}` punctuation scalar.
  public const long PUNCTUATION_CLOSE_BRACE = 125;

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
