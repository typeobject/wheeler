//! Checks canonical package-manifest mapping keys.

module wheeler.compiler.packages.manifest_keys;

import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestKeys {
  /// Checks one keyword followed by its canonical colon token.
  public boolean manifestKeyAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long token,
    long hash
  ) {
    long colonToken = token + 1;
    boolean bounded = colonToken < count;
    if (bounded == false) {
      return false;
    }

    boolean keyword = keywordAt(source, starts, lengths, token, hash);
    if (keyword == false) {
      return false;
    }

    boolean colon = colonAt(source, kinds, starts, colonToken);
    return colon;
  }
}
