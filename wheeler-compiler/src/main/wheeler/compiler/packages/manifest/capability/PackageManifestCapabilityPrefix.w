//! Validates the prefix of one package-manifest capability row.

module wheeler.compiler.packages.manifest_capability_prefix;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;

classical class PackageManifestCapabilityPrefix {
  /// Checks row bounds, sequence syntax, and the quoted capability name.
  public boolean manifestCapabilityPrefixValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long finalToken = cursor + 6;
    boolean bounded = finalToken < count;
    if (bounded == false) {
      return false;
    }

    boolean sequenceRow = dashAt(source, kinds, starts, cursor);
    if (sequenceRow == false) {
      return false;
    }

    long nameKeyToken = cursor + 1;
    long nameWord = WORD_NAME;
    boolean nameKey = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      nameKeyToken,
      nameWord
    );
    if (nameKey == false) {
      return false;
    }

    long nameToken = cursor + 3;
    boolean nameQuoted = quoted(kinds, lengths, nameToken);
    return nameQuoted;
  }
}
