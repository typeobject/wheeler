//! Validates the package-manifest release header field.

module wheeler.compiler.packages.manifest_header_release;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;
import wheeler.compiler.packages.semver;

classical class PackageManifestHeaderRelease {
  /// Checks the fixed version key and its quoted semantic release.
  public boolean manifestHeaderReleaseValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    long keyToken = 8;
    long versionWord = WORD_VERSION;
    boolean versionKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      keyToken,
      versionWord
    );
    if (versionKey == false) {
      return false;
    }

    long releaseToken = 10;
    boolean releaseQuoted = quoted(kinds, lengths, releaseToken);
    if (releaseQuoted == false) {
      return false;
    }

    long tokenStart = starts[releaseToken];
    long tokenLength = lengths[releaseToken];
    long releaseStart = tokenStart + 1;
    long releaseLength = tokenLength - 2;
    boolean releaseValid = validRelease(source, releaseStart, releaseLength);
    return releaseValid;
  }
}
