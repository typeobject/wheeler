//! Checks canonical package-manifest sequence brackets.

module wheeler.compiler.packages.manifest_brackets;

classical class PackageManifestBrackets {
  /// Checks one opening sequence bracket at a validated token coordinate.
  public boolean manifestOpenBracketAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long token
  ) {
    long kind = kinds[token];
    long start = starts[token];
    long scalar = utf8Scalar(source, start);
    long punctuationKind = 3;
    long openBracket = 91;
    if (kind < punctuationKind) {
      return false;
    }

    if (punctuationKind < kind) {
      return false;
    }

    if (scalar < openBracket) {
      return false;
    }

    if (openBracket < scalar) {
      return false;
    }

    return true;
  }

  /// Checks one closing sequence bracket at a validated token coordinate.
  public boolean manifestCloseBracketAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long token
  ) {
    long kind = kinds[token];
    long start = starts[token];
    long scalar = utf8Scalar(source, start);
    long punctuationKind = 3;
    long closeBracket = 93;
    if (kind < punctuationKind) {
      return false;
    }

    if (punctuationKind < kind) {
      return false;
    }

    if (scalar < closeBracket) {
      return false;
    }

    if (closeBracket < scalar) {
      return false;
    }

    return true;
  }
}
