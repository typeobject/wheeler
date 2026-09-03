//! Classifies empty package-manifest collection sections.

module wheeler.compiler.packages.manifest_empty_section;

import wheeler.compiler.packages.manifest_brackets;

classical class PackageManifestEmptySection {
  /// Returns one for an empty bracket pair, zero for rows, or negative for malformed brackets.
  public long manifestEmptySectionKind(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    long count,
    long cursor
  ) {
    boolean open = manifestOpenBracketAt(source, kinds, starts, cursor);
    if (open == false) {
      return 0;
    }

    long closeToken = cursor + 1;
    boolean bounded = closeToken < count;
    if (bounded == false) {
      return -1;
    }

    boolean closed = manifestCloseBracketAt(source, kinds, starts, closeToken);
    if (closed == false) {
      return -1;
    }

    return 1;
  }
}
