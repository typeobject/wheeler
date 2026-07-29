//! Validates and resolves bounded scalar class constants.

module wheeler.compiler.class_constants;

import wheeler.compiler.constant_declarations;
import wheeler.compiler.constant_expressions;
import wheeler.compiler.tokens;

classical class ClassConstants {
  /// Caps scalar constants before the first executable class member.
  public const long MAX_CLASS_CONSTANTS = 64;

  /// Describes one typed lookup without reserving a scalar sentinel.
  public record ConstantResolution(long value, boolean found, boolean valid) {}

  private boolean declarationHeaderValid(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long declarationStart
  ) {
    long constant = constantToken(source, tokenStarts, tokenLengths, declarationStart);
    if (constant < 0) {
      return false;
    }

    long name = constant + 2;
    if (tokenKinds[name] == 1) {
      return tokenLengths[name] < 257;
    }

    return false;
  }

  private boolean duplicateName(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long declarationStart,
    long tokenCount
  ) {
    long assertedName = constantNameToken(source, tokenStarts, tokenLengths, declarationStart);
    long prior = firstDeclaration;
    while (prior < declarationStart) limit MAX_CLASS_CONSTANTS {
      if (
        sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          constantNameToken(source, tokenStarts, tokenLengths, prior),
          assertedName
        )
      ) {
        return true;
      }

      long next = constantDeclarationEnd(source, tokenStarts, tokenLengths, prior, tokenCount);
      if (prior < next) {} else {
        return false;
      }

      prior = next;
    }

    return false;
  }

  private long constantPrefixEnd(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long tokenCount
  ) {
    long cursor = firstDeclaration;
    long count = 0;
    while (count < MAX_CLASS_CONSTANTS) limit MAX_CLASS_CONSTANTS {
      if (constantToken(source, tokenStarts, tokenLengths, cursor) < 0) {
        return cursor;
      }

      long next = constantDeclarationEnd(source, tokenStarts, tokenLengths, cursor, tokenCount);
      if (cursor < next) {} else {
        return -1;
      }

      cursor = next;
      count += 1;
    }

    if (constantToken(source, tokenStarts, tokenLengths, cursor) < 0) {
      return cursor;
    }

    return -1;
  }

  private boolean expressionsValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart
  ) {
    long cursor = firstDeclaration;
    long count = 0;
    while (cursor < memberStart) limit MAX_CLASS_CONSTANTS {
      ExpressionResolution resolution = evaluateConstantExpression(
        source,
        tokenStarts,
        tokenLengths,
        firstDeclaration,
        memberStart,
        constantNameToken(source, tokenStarts, tokenLengths, cursor)
      );
      if (resolution.found) {
        if (resolution.valid == false) {
          return false;
        }
      } else {
        return false;
      }

      long next = constantDeclarationEnd(
        source,
        tokenStarts,
        tokenLengths,
        cursor,
        memberStart
      );
      if (cursor < next) {} else {
        return false;
      }

      cursor = next;
      count += 1;
    }

    return cursor == memberStart;
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
      if (constantToken(source, tokenStarts, tokenLengths, cursor) < 0) {
        if (
          expressionsValid(source, tokenStarts, tokenLengths, firstDeclaration, cursor)
        ) {
          return cursor;
        }

        return -1;
      }

      if (
        declarationHeaderValid(source, tokenKinds, tokenStarts, tokenLengths, cursor) == false
      ) {
        return -1;
      }

      long next = constantDeclarationEnd(source, tokenStarts, tokenLengths, cursor, tokenCount);
      if (cursor < next) {} else {
        return -1;
      }

      if (
        duplicateName(source, tokenStarts, tokenLengths, firstDeclaration, cursor, tokenCount)
      ) {
        return -1;
      }

      cursor = next;
      count += 1;
    }

    if (constantToken(source, tokenStarts, tokenLengths, cursor) < 0) {
      if (
        expressionsValid(source, tokenStarts, tokenLengths, firstDeclaration, cursor)
      ) {
        return cursor;
      }
    }

    return -1;
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
    long firstDeclaration = firstConstantDeclaration(source, tokenStarts, tokenLengths);
    long memberStart = constantPrefixEnd(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      MAX_COMPILER_TOKENS
    );
    if (memberStart < firstDeclaration) {
      return new ConstantResolution(0, false, false);
    }

    ExpressionResolution resolution = evaluateConstantExpression(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      assertedName
    );
    boolean valid = resolution.found;
    if (resolution.valid == false) {
      valid = false;
    }

    if (resolution.signed == expectedSigned) {} else {
      valid = false;
    }

    return new ConstantResolution(resolution.value, resolution.found, valid);
  }
}
