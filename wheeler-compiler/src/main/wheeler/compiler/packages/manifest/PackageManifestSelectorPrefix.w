//! Compares package-manifest selector and root prefixes.

module wheeler.compiler.packages.manifest_selector_prefix;

classical class PackageManifestSelectorPrefix {
  /// Checks whether one selector range equals the corresponding root prefix.
  public boolean manifestSelectorPrefixSame(
    borrow utf8 source,
    long selectorStart,
    long selectorLength,
    long rootStart
  ) {
    boolean same = true;
    long offset = 0;
    while (offset < selectorLength) limit 4096 {
      long selectorIndex = selectorStart + offset;
      long rootIndex = rootStart + offset;
      long selectorScalar = utf8Scalar(source, selectorIndex);
      long rootScalar = utf8Scalar(source, rootIndex);
      if (selectorScalar < rootScalar) {
        same = false;
      }

      if (rootScalar < selectorScalar) {
        same = false;
      }

      offset += 1;
    }

    return same;
  }
}
