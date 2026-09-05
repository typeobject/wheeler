//! Validates the package-manifest format preamble.

module wheeler.compiler.packages.manifest_header_preamble;

import wheeler.compiler.packages.manifest_header_state;
import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;

classical class PackageManifestHeaderPreamble {
  /// Checks token capacity, format version, and the package mapping opener.
  public boolean manifestHeaderPreambleValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    boolean enoughTokens = manifestHeaderTokenCount(count);
    if (enoughTokens == false) {
      return false;
    }

    long formatToken = 0;
    long formatWord = WORD_SCHEMA;
    boolean formatKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      formatToken,
      formatWord
    );
    if (formatKey == false) {
      return false;
    }

    long versionToken = 2;
    long versionWord = manifestTokenWord(source, starts, lengths, versionToken);
    boolean formatVersion = manifestFormatVersion(versionWord);
    if (formatVersion == false) {
      return false;
    }

    long packageToken = 3;
    long packageWord = WORD_PACKAGE;
    boolean packageKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      packageToken,
      packageWord
    );
    return packageKey;
  }
}
