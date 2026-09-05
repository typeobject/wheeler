//! Validates the package-manifest profile and target header tail.

module wheeler.compiler.packages.manifest_header_tail;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;

classical class PackageManifestHeaderTail {
  /// Checks the quoted profile field and target sequence opener.
  public boolean manifestHeaderTailValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    long profileKeyToken = 11;
    long profileWord = WORD_PROFILE;
    boolean profileKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      profileKeyToken,
      profileWord
    );
    if (profileKey == false) {
      return false;
    }

    long profileToken = 13;
    boolean profileQuoted = quoted(kinds, lengths, profileToken);
    if (profileQuoted == false) {
      return false;
    }

    long targetsKeyToken = 14;
    long targetsWord = WORD_TARGETS;
    boolean targetsKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      targetsKeyToken,
      targetsWord
    );
    return targetsKey;
  }
}
