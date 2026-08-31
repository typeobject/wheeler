//! Carries scalar state for package-manifest source selectors.

module wheeler.compiler.packages.manifest_selector_state;

classical class PackageManifestSelectorState {
  /// Classifies an invalid, prefix, or equal selector length.
  public long manifestSelectorLengthKind(long selectorLength, long rootLength) {
    if (rootLength < selectorLength) {
      return -1;
    }

    if (selectorLength == rootLength) {
      return 1;
    }

    return 0;
  }

  /// Preserves prefix equality across one scalar pair.
  public boolean manifestSelectorSame(boolean same, long selectorScalar, long rootScalar) {
    if (same == false) {
      return false;
    }

    if (selectorScalar < rootScalar) {
      return false;
    }

    if (rootScalar < selectorScalar) {
      return false;
    }

    return true;
  }

}
