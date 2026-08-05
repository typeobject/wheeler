//! Locates bounded scalar constant declarations without evaluating them.

module wheeler.compiler.constant_declarations;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ConstantDeclarations {
  /// Caps scalar constants before the first executable class member.
  public const long MAX_CLASS_CONSTANTS = 256;
  /// Caps expression parentheses in the recovery compiler profile.
  public const long MAX_CONSTANT_EXPRESSION_DEPTH = 32;
  private const long TOKEN_CONST = 94844771;

  private boolean scalarAt(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token,
    long scalar
  ) {
    if (tokenLengths[token] == 1) {
      return utf8Scalar(source, tokenStarts[token]) == scalar;
    }

    return false;
  }

  /// Returns the `const` token for one optionally visible declaration.
  public long constantToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    long token = declarationStart;
    long visibility = tokenHash(source, tokenStarts, tokenLengths, token);
    if (visibility == TOKEN_PUBLIC) {
      token += 1;
    } else {
      if (visibility == TOKEN_PRIVATE) {
        token += 1;
      }
    }

    if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_CONST) {
      return token;
    }

    return -1;
  }

  /// Returns the name token of one scalar constant declaration.
  public long constantNameToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    return constantToken(source, tokenStarts, tokenLengths, declarationStart) + 2;
  }

  /// Returns the first initializer token of one scalar constant declaration.
  public long constantExpressionStart(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    return constantToken(source, tokenStarts, tokenLengths, declarationStart) + 4;
  }

  /// Reports whether one declaration names the signed scalar type.
  public boolean constantTypeSigned(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    long constant = constantToken(source, tokenStarts, tokenLengths, declarationStart);
    return tokenHash(source, tokenStarts, tokenLengths, constant + 1) == TOKEN_LONG;
  }

  /// Finds the semicolon after one nonempty, balanced initializer.
  public long constantDeclarationEnd(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart,
    long tokenCount
  ) {
    long constant = constantToken(source, tokenStarts, tokenLengths, declarationStart);
    if (constant < 0) {
      return declarationStart;
    }

    if (constant + 5 < tokenCount) {} else {
      return -1;
    }

    long type = tokenHash(source, tokenStarts, tokenLengths, constant + 1);
    boolean scalar = type == TOKEN_LONG;
    if (type == TOKEN_BOOLEAN) {
      scalar = true;
    }

    if (scalar == false) {
      return -1;
    }

    if (
      scalarAt(source, tokenStarts, tokenLengths, constant + 3, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long expression = constant + 4;
    long cursor = expression;
    long depth = 0;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        depth += 1;
        if (MAX_CONSTANT_EXPRESSION_DEPTH < depth) {
          return -1;
        }
      } else {
        if (
          scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_CLOSE_PAREN)
        ) {
          if (depth < 1) {
            return -1;
          }

          depth -= 1;
        } else {
          if (
            scalarAt(source, tokenStarts, tokenLengths, cursor, PUNCTUATION_SEMICOLON)
          ) {
            if (depth == 0) {
              if (expression < cursor) {
                return cursor + 1;
              }

              return -1;
            }
          }
        }
      }

      cursor += 1;
    }

    return -1;
  }

  /// Returns the first declaration after optional signed state.
  public long firstConstantDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, 4) == TOKEN_STATE) {
      long value = 8;
      long width = 1;
      if (utf8Scalar(source, tokenStarts[value]) == PUNCTUATION_MINUS) {
        width = 2;
      }

      return value + width + 1;
    }

    return 4;
  }
}
