//! Validates and resolves bounded scalar class constants.

module wheeler.compiler.class_constants;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.constant_expressions;
import wheeler.compiler.signed_return_statements;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class ClassConstants {
  /// Holds one token index for every admitted class constant.
  private const long CLASS_CONSTANT_NAME_BYTES = MAX_CLASS_CONSTANTS * 8;

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
    borrow mut words names,
    long count,
    long assertedName
  ) {
    long prior = 0;
    while (prior < count) limit MAX_CLASS_CONSTANTS {
      if (
        sameTokenText(source, tokenStarts, tokenLengths, names[prior], assertedName)
      ) {
        return true;
      }

      prior += 1;
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

  private ExpressionResolution evaluateLocalConstant(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart,
    long assertedName
  ) {
    region noImports = new region(/* bytes= */ 16, /* allocations= */ 2);
    bytes importedNames = allocateBytes(noImports, 1);
    words importedRows = allocate(noImports, 1);
    set(importedRows, 0, 0);
    ExpressionResolution result = evaluateConstantExpressionWithProducts(
      source,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      memberStart,
      assertedName,
      importedNames,
      importedRows
    );
    drop(importedRows);
    drop(importedNames);
    drop(noImports);
    return result;
  }

  private boolean expressionsValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long memberStart
  ) {
    long cursor = firstDeclaration;
    while (cursor < memberStart) limit MAX_CLASS_CONSTANTS {
      ExpressionResolution resolution = evaluateLocalConstant(
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
    }

    return cursor == memberStart;
  }

  private long constantHeadersEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long firstDeclaration,
    long tokenCount,
    borrow mut words names
  ) {
    long cursor = firstDeclaration;
    long count = 0;
    while (count < MAX_CLASS_CONSTANTS) limit MAX_CLASS_CONSTANTS {
      if (constantToken(source, tokenStarts, tokenLengths, cursor) < 0) {
        return cursor;
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

      long name = constantNameToken(source, tokenStarts, tokenLengths, cursor);
      if (duplicateName(source, tokenStarts, tokenLengths, names, count, name)) {
        return -1;
      }

      set(names, count, name);
      cursor = next;
      count += 1;
    }

    if (constantToken(source, tokenStarts, tokenLengths, cursor) < 0) {
      return cursor;
    }

    return -1;
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
    if (constantToken(source, tokenStarts, tokenLengths, firstDeclaration) < 0) {
      return firstDeclaration;
    }

    region scratch = new region(/* bytes= */ CLASS_CONSTANT_NAME_BYTES, /* allocations= */ 1);
    words names = allocate(scratch, MAX_CLASS_CONSTANTS);
    long result = constantHeadersEnd(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      firstDeclaration,
      tokenCount,
      names
    );
    drop(names);
    drop(scratch);
    if (result < 0) {
      return -1;
    }

    if (
      expressionsValid(source, tokenStarts, tokenLengths, firstDeclaration, result)
    ) {
      return result;
    }

    return -1;
  }

  /// Checks exact name presence after the complete bounded prefix scan.
  /// Initializer values and duplicate-name admission belong to their callers.
  public boolean classConstantNameExists(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long assertedName
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
      return false;
    }

    long cursor = firstDeclaration;
    while (cursor < memberStart) limit MAX_CLASS_CONSTANTS {
      long name = constantNameToken(source, tokenStarts, tokenLengths, cursor);
      if (sameTokenText(source, tokenStarts, tokenLengths, name, assertedName)) {
        return true;
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
    }

    return false;
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

    ExpressionResolution resolution = evaluateLocalConstant(
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
