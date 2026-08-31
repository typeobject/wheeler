//! Completes package-manifest selector range checks.

module wheeler.compiler.packages.manifest_selector_completion;

classical class PackageManifestSelectorCompletion {
  /// Checks an equal range or the slash after one proper root prefix.
  public boolean manifestSelectorRangeComplete(
    borrow utf8 source,
    long lengthKind,
    long rootStart,
    long selectorLength
  ) {
    if (lengthKind == 1) {
      return true;
    }

    long nextRootIndex = rootStart + selectorLength;
    long nextRootScalar = utf8Scalar(source, nextRootIndex);
    return nextRootScalar == 47;
  }
}
