//! Classifies and decodes bounded source token ranges.

module wheeler.compiler.tokens;

import wheeler.lexer.scanner;

classical class Tokens {
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
  /// Names the stable token hash for `long`.
  public const long TOKEN_LONG = 3327612;
  /// Names the stable token hash for `boolean`.
  public const long TOKEN_BOOLEAN = 90259024936;
  /// Names the stable token hash for `true`.
  public const long TOKEN_TRUE = 3569038;
  /// Names the stable token hash for `false`.
  public const long TOKEN_FALSE = 97196323;

  /// Names the parser IR code for direct assignment.
  public const long STATEMENT_ASSIGN = 0;
  /// Names the parser IR code for a signed equality assertion.
  public const long STATEMENT_ASSERT_EQ = 768;
  /// Names the parser IR code for a signed local declaration.
  public const long STATEMENT_LOCAL_LONG = 769;
  /// Names the parser IR code for a Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN = 770;
  /// Names the parser IR code for a negated Boolean literal declaration.
  public const long STATEMENT_LOCAL_BOOLEAN_NOT = 771;
  /// Names the parser IR code for a Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN = 772;
  /// Names the parser IR code for a negated Boolean literal assertion.
  public const long STATEMENT_ASSERT_BOOLEAN_NOT = 773;
  /// Names the parser IR code for an assertion over a prior Boolean local.
  public const long STATEMENT_ASSERT_LOCAL_BOOLEAN = 774;
  /// Names the parser IR code for checked global addition.
  public const long STATEMENT_UPDATE_ADD = 1040;
  /// Names the parser IR code for checked global subtraction.
  public const long STATEMENT_UPDATE_SUB = 1041;
  /// Names the parser IR code for global XOR.
  public const long STATEMENT_UPDATE_XOR = 1042;

  /// Names the ASCII `!` punctuation scalar.
  public const long PUNCTUATION_BANG = 33;
  /// Names the ASCII `(` punctuation scalar.
  public const long PUNCTUATION_OPEN_PAREN = 40;
  /// Names the ASCII `)` punctuation scalar.
  public const long PUNCTUATION_CLOSE_PAREN = 41;
  /// Names the ASCII `+` punctuation scalar.
  public const long PUNCTUATION_PLUS = 43;
  /// Names the ASCII `-` punctuation scalar.
  public const long PUNCTUATION_MINUS = 45;
  /// Names the ASCII `;` punctuation scalar.
  public const long PUNCTUATION_SEMICOLON = 59;
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
    while (cursor < end) limit 16 {
      hash = hash * 31 + utf8Scalar(source, cursor);
      cursor += utf8Width(source, cursor);
    }

    return hash;
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

  /// Maps one statement token to its bounded parser opcode.
  public long statementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long keyword = tokenHash(source, tokenStarts, tokenLengths, statementStart);
    if (keyword == TOKEN_ASSERT) {
      long assertExpression = statementStart + 2;
      long assertHash = tokenHash(source, tokenStarts, tokenLengths, assertExpression);
      if (assertHash == TOKEN_TRUE) {
        return STATEMENT_ASSERT_BOOLEAN;
      }

      if (assertHash == TOKEN_FALSE) {
        return STATEMENT_ASSERT_BOOLEAN;
      }

      if (utf8Scalar(source, tokenStarts[assertExpression]) == PUNCTUATION_BANG) {
        return STATEMENT_ASSERT_BOOLEAN_NOT;
      }

      if (
        utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_CLOSE_PAREN
      ) {
        return STATEMENT_ASSERT_LOCAL_BOOLEAN;
      }

      return STATEMENT_ASSERT_EQ;
    }

    if (keyword == TOKEN_LONG) {
      return STATEMENT_LOCAL_LONG;
    }

    if (keyword == TOKEN_BOOLEAN) {
      if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_BANG) {
        return STATEMENT_LOCAL_BOOLEAN_NOT;
      }

      return STATEMENT_LOCAL_BOOLEAN;
    }

    long operator = utf8Scalar(source, tokenStarts[statementStart + 1]);
    if (operator == PUNCTUATION_ASSIGN) {
      return STATEMENT_ASSIGN;
    }

    if (operator == PUNCTUATION_PLUS) {
      return STATEMENT_UPDATE_ADD;
    }

    if (operator == PUNCTUATION_MINUS) {
      return STATEMENT_UPDATE_SUB;
    }

    if (operator == PUNCTUATION_CARET) {
      return STATEMENT_UPDATE_XOR;
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
