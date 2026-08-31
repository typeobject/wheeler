//! Checks package-manifest source selectors against target roots.

module wheeler.compiler.packages.manifest_selectors;

import wheeler.compiler.packages.manifest_selector_state;

classical class PackageManifestSelectors {
  /// Checks whether one selector range equals or contains a root range.
  public boolean manifestSelectorRangeCoversRoot(
    borrow utf8 source,
    long selectorStart,
    long selectorLength,
    long rootStart,
    long rootLength
  ) {
    long lengthKind = manifestSelectorLengthKind(selectorLength, rootLength);
    if (lengthKind < 0) {
      return false;
    }

    boolean same = true;
    long offset = 0;
    while (offset < selectorLength) limit 4096 {
      long selectorIndex = selectorStart + offset;
      long rootIndex = rootStart + offset;
      long selectorScalar = utf8Scalar(source, selectorIndex);
      long rootScalar = utf8Scalar(source, rootIndex);
      same = manifestSelectorSame(same, selectorScalar, rootScalar);
      offset += 1;
    }

    if (same == false) {
      return false;
    }

    if (lengthKind == 1) {
      return manifestSelectorComplete(lengthKind, 0);
    }

    long nextRootIndex = rootStart + selectorLength;
    long nextRootScalar = utf8Scalar(source, nextRootIndex);
    return manifestSelectorComplete(lengthKind, nextRootScalar);
  }
}
