//! Validates and resolves bounded scalar class constants.

module wheeler.compiler.class_constants;

import wheeler.compiler.tokens;

classical class ClassConstants {
  /// Caps scalar constants before the first executable class member.
  public const long MAX_CLASS_CONSTANTS = 64;
  private const long TOKEN_CONST = 94844771;

  /// Describes one typed lookup without reserving a scalar sentinel.
  public record ConstantResolution(long value, boolean found, boolean valid) {}

  private long constToken(
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

  private long declarationEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart,
    long tokenCount
  ) {
    long constant = constToken(source, tokenStarts, tokenLengths, declarationStart);
    if (constant < 0) {
      return declarationStart;
    }

    if (constant + 5 < tokenCount) {} else {
      return -1;
    }

    long type = tokenHash(source, tokenStarts, tokenLengths, constant + 1);
    boolean signed = type == TOKEN_LONG;
    boolean scalar = signed;
    if (type == TOKEN_BOOLEAN) {
      scalar = true;
    }

    if (scalar == false) {
      return -1;
    }

    long name = constant + 2;
    if (tokenKinds[name] == 1) {} else {
      return -1;
    }

    if (tokenLengths[name] < 257) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, constant + 3, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long value = constant + 4;
    long width = 1;
    if (signed) {
      width = signedNumberWidth(source, tokenKinds, tokenStarts, value);
      if (width < 1) {
        return -1;
      }

      if (signedNumberValid(source, tokenStarts, tokenLengths, value) == false) {
        return -1;
      }
    } else {
      long booleanValue = tokenHash(source, tokenStarts, tokenLengths, value);
      boolean validBoolean = booleanValue == TOKEN_TRUE;
      if (booleanValue == TOKEN_FALSE) {
        validBoolean = true;
      }

      if (validBoolean == false) {
        return -1;
      }
    }

    long semicolon = value + width;
    if (semicolon < tokenCount) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, semicolon, PUNCTUATION_SEMICOLON)
    ) {
      return semicolon + 1;
    }

    return -1;
  }

  private long declarationName(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    return constToken(source, tokenStarts, tokenLengths, declarationStart) + 2;
  }

  private boolean duplicateName(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long declarationStart,
    long tokenCount
  ) {
    long assertedName = declarationName(source, tokenStarts, tokenLengths, declarationStart);
    if (4 < firstDeclaration) {
      if (sameTokenText(source, tokenStarts, tokenLengths, 6, assertedName)) {
        return true;
      }
    }

    long prior = firstDeclaration;
    while (prior < declarationStart) limit MAX_COMPILER_TOKENS {
      long priorConstant = constToken(source, tokenStarts, tokenLengths, prior);
      if (priorConstant < 0) {
        return false;
      }

      if (
        sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          declarationName(source, tokenStarts, tokenLengths, prior),
          assertedName
        )
      ) {
        return true;
      }

      long next = declarationEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        prior,
        tokenCount
      );
      if (prior < next) {} else {
        return false;
      }

      prior = next;
    }

    return false;
  }

  /// Returns the first nonconstant member after complete declaration validation.
  public long classMemberStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long tokenCount
  ) {
    long cursor = firstDeclaration;
    long count = 0;
    while (count < MAX_CLASS_CONSTANTS) limit MAX_CLASS_CONSTANTS {
      if (constToken(source, tokenStarts, tokenLengths, cursor) < 0) {
        return cursor;
      }

      long next = declarationEnd(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        cursor,
        tokenCount
      );
      if (cursor < next) {} else {
        return -1;
      }

      if (
        duplicateName(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          firstDeclaration,
          cursor,
          tokenCount
        )
      ) {
        return -1;
      }

      cursor = next;
      count += 1;
    }

    if (constToken(source, tokenStarts, tokenLengths, cursor) < 0) {
      return cursor;
    }

    return -1;
  }

  private long firstDeclaration(
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

  private long declarationValueToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    return constToken(source, tokenStarts, tokenLengths, declarationStart) + 4;
  }

  private long nextResolvedDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart,
    boolean signed
  ) {
    long value = declarationValueToken(source, tokenStarts, tokenLengths, declarationStart);
    long width = 1;
    if (signed) {
      if (utf8Scalar(source, tokenStarts[value]) == PUNCTUATION_MINUS) {
        width = 2;
      }
    }

    return value + width + 1;
  }

  /// Checks whether the class-constant prefix already owns one member name.
  public boolean classConstantNameExists(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long assertedName
  ) {
    ConstantResolution signed = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      assertedName,
      true
    );
    if (signed.found) {
      return true;
    }

    ConstantResolution booleanValue = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      assertedName,
      false
    );
    return booleanValue.found;
  }

  /// Checks whether one exact class constant has the requested scalar type.
  public boolean classConstantHasType(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long assertedName,
    boolean expectedSigned
  ) {
    ConstantResolution resolution = resolveClassConstant(
      source,
      tokenStarts,
      tokenLengths,
      assertedName,
      expectedSigned
    );
    return resolution.valid;
  }

  /// Resolves one constant name to the matching literal-return statement form.
  public long classConstantReturnOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long assertedName
  ) {
    if (classConstantHasType(source, tokenStarts, tokenLengths, assertedName, true)) {
      return STATEMENT_RETURN_LONG;
    }

    if (classConstantHasType(source, tokenStarts, tokenLengths, assertedName, false)) {
      return STATEMENT_RETURN_BOOLEAN;
    }

    return -1;
  }

  /// Resolves one exact typed name from the validated class-constant prefix.
  public ConstantResolution resolveClassConstant(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long assertedName,
    boolean expectedSigned
  ) {
    long cursor = firstDeclaration(source, tokenStarts, tokenLengths);
    long matches = 0;
    long resolvedValue = 0;
    boolean typeMatches = false;
    long count = 0;
    while (count < MAX_CLASS_CONSTANTS) limit MAX_CLASS_CONSTANTS {
      long constant = constToken(source, tokenStarts, tokenLengths, cursor);
      if (constant < 0) {
        boolean found = matches == 1;
        boolean valid = found;
        if (typeMatches == false) {
          valid = false;
        }

        return new ConstantResolution(resolvedValue, found, valid);
      }

      long type = tokenHash(source, tokenStarts, tokenLengths, constant + 1);
      boolean signed = type == TOKEN_LONG;
      if (
        sameTokenText(source, tokenStarts, tokenLengths, constant + 2, assertedName)
      ) {
        matches += 1;
        typeMatches = signed == expectedSigned;
        long value = constant + 4;
        if (signed) {
          resolvedValue = parsedSignedNumber(source, tokenStarts, tokenLengths, value);
        } else {
          resolvedValue = 0;
          if (tokenHash(source, tokenStarts, tokenLengths, value) == TOKEN_TRUE) {
            resolvedValue = 1;
          }
        }
      }

      cursor = nextResolvedDeclaration(source, tokenStarts, tokenLengths, cursor, signed);
      count += 1;
    }

    return new ConstantResolution(0, false, false);
  }
}
