//! Checks package-manifest source selectors against target roots.

module wheeler.compiler.packages.manifest_selectors;

import wheeler.compiler.packages.manifest_selector_completion;
import wheeler.compiler.packages.manifest_selector_prefix;
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

    boolean same = manifestSelectorPrefixSame(source, selectorStart, selectorLength, rootStart);
    if (same == false) {
      return false;
    }

    boolean complete = manifestSelectorRangeComplete(
      source,
      lengthKind,
      rootStart,
      selectorLength
    );
    return complete;
  }
}
