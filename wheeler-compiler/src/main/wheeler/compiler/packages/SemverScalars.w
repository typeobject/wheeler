//! Classifies ASCII scalars used by canonical semantic versions.

module wheeler.compiler.packages.semver_scalars;

classical class SemverScalars {
  /// Checks one decimal digit.
  public boolean semverDigit(long scalar) {
    if (scalar < 48) {
      return false;
    }

    return scalar < 58;
  }

  /// Checks one uppercase ASCII letter.
  public boolean semverUpper(long scalar) {
    if (scalar < 65) {
      return false;
    }

    return scalar < 91;
  }

  /// Checks one lowercase ASCII letter.
  public boolean semverLower(long scalar) {
    if (scalar < 97) {
      return false;
    }

    return scalar < 123;
  }

  /// Checks one semantic-version identifier scalar.
  public boolean semverIdentifierScalar(long scalar) {
    boolean numeric = semverDigit(scalar);
    if (numeric == true) {
      return true;
    }

    boolean uppercase = semverUpper(scalar);
    if (uppercase == true) {
      return true;
    }

    boolean lowercase = semverLower(scalar);
    if (lowercase == true) {
      return true;
    }

    return scalar == 45;
  }
}
