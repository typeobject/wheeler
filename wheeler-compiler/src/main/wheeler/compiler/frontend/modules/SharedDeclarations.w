//! Matches identical private declarations for shared module dependencies.

module wheeler.compiler.shared_declarations;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_qualifications;
import wheeler.compiler.tokens;

classical class SharedDeclarations {
  private boolean declarationTokensEqual(
    borrow utf8 leftSource,
    borrow mut words leftKinds,
    borrow mut words leftStarts,
    borrow mut words leftLengths,
    long leftStart,
    long leftEnd,
    borrow utf8 rightSource,
    borrow mut words rightKinds,
    borrow mut words rightStarts,
    borrow mut words rightLengths,
    long rightStart,
    long rightEnd
  ) {
    long leftConstant = constantToken(leftSource, leftStarts, leftLengths, leftStart);
    long rightConstant = constantToken(rightSource, rightStarts, rightLengths, rightStart);
    if (leftConstant < leftEnd) {} else {
      return false;
    }

    if (rightConstant < rightEnd) {} else {
      return false;
    }

    if (leftEnd - leftConstant == rightEnd - rightConstant) {} else {
      return false;
    }

    long offset = 0;
    while (leftConstant + offset < leftEnd) limit MAX_COMPILER_TOKENS {
      long leftToken = leftConstant + offset;
      long rightToken = rightConstant + offset;
      if (leftKinds[leftToken] == rightKinds[rightToken]) {} else {
        return false;
      }

      if (
        rangesEqual(
          leftSource,
          leftStarts[leftToken],
          leftLengths[leftToken],
          rightSource,
          rightStarts[rightToken],
          rightLengths[rightToken]
        )
      ) {} else {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Matches one admitted private constant against complete root constant tokens.
  public boolean sharedPrivateDeclaration(
    borrow utf8 importedSource,
    borrow mut words importedKinds,
    borrow mut words importedStarts,
    borrow mut words importedLengths,
    long importedStart,
    long importedEnd,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootFirst,
    long rootMember
  ) {
    if (
      sourceTokenCode(importedSource, importedStarts, importedLengths, importedStart)
        == TOKEN_PRIVATE
    ) {} else {
      return false;
    }

    long rootDeclaration = rootFirst;
    while (rootDeclaration < rootMember) limit MAX_CLASS_CONSTANTS {
      long rootNext = constantDeclarationEnd(
        rootSource,
        rootStarts,
        rootLengths,
        rootDeclaration,
        rootMember
      );
      if (rootDeclaration < rootNext) {} else {
        return false;
      }

      long visibility = sourceTokenCode(rootSource, rootStarts, rootLengths, rootDeclaration);
      boolean shareable = visibility == TOKEN_PRIVATE;
      if (visibility == TOKEN_PUBLIC) {
        shareable = true;
      }

      if (shareable) {
        if (
          declarationTokensEqual(
            importedSource,
            importedKinds,
            importedStarts,
            importedLengths,
            importedStart,
            importedEnd,
            rootSource,
            rootKinds,
            rootStarts,
            rootLengths,
            rootDeclaration,
            rootNext
          )
        ) {
          return true;
        }
      }

      rootDeclaration = rootNext;
    }

    return false;
  }

  /// Returns the first nonshared declaration or `-1` for absent or private-qualified sharing.
  public long sharedPrivatePrefixEnd(
    borrow utf8 importedSource,
    borrow mut words importedKinds,
    borrow mut words importedStarts,
    borrow mut words importedLengths,
    long importedFirst,
    long importedMember,
    borrow utf8 rootSource,
    borrow mut words rootKinds,
    borrow mut words rootStarts,
    borrow mut words rootLengths,
    long rootFirst,
    long rootMember,
    long rootCount,
    ImportedQualification moduleName
  ) {
    long importedDeclaration = importedFirst;
    long shared = 0;
    while (importedDeclaration < importedMember) limit MAX_CLASS_CONSTANTS {
      if (
        sourceTokenCode(importedSource, importedStarts, importedLengths, importedDeclaration)
          == TOKEN_PRIVATE
      ) {} else {
        break;
      }

      long importedNext = constantDeclarationEnd(
        importedSource,
        importedStarts,
        importedLengths,
        importedDeclaration,
        importedMember
      );
      if (importedDeclaration < importedNext) {} else {
        return -1;
      }

      if (
        sharedPrivateDeclaration(
          importedSource,
          importedKinds,
          importedStarts,
          importedLengths,
          importedDeclaration,
          importedNext,
          rootSource,
          rootKinds,
          rootStarts,
          rootLengths,
          rootFirst,
          rootMember
        )
      ) {} else {
        break;
      }

      long name = constantNameToken(
        importedSource,
        importedStarts,
        importedLengths,
        importedDeclaration
      );
      QualifiedNameSpan nameSpan = new QualifiedNameSpan(
        importedStarts[name],
        importedLengths[name]
      );
      if (
        qualifiedPrivateNameUsed(
          importedSource,
          moduleName,
          nameSpan,
          rootSource,
          rootKinds,
          rootStarts,
          rootLengths,
          rootCount
        )
      ) {
        return -1;
      }

      importedDeclaration = importedNext;
      shared += 1;
    }

    if (0 < shared) {
      return importedDeclaration;
    }

    return -1;
  }
}
