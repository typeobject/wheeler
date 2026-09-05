//! Checks canonical package-manifest mapping keys.

module wheeler.compiler.packages.manifest_keys;

import wheeler.compiler.packages.manifest_tokens;

classical class PackageManifestKeys {
  /// Checks an exact word code followed by its canonical colon token.
  /// Token contents come from the scanner. Unknown word zero never matches.
  public boolean manifestKeyAt(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long token,
    long expectedWord
  ) {
    if (token < 0) {
      return false;
    }
    if (count < 2) {
      return false;
    }
    long lastKey = count - 2;
    if (lastKey < token) {
      return false;
    }
    long kindCapacity = bufferLength(kinds);
    if (kindCapacity < count) {
      return false;
    }
    long startCapacity = bufferLength(starts);
    if (startCapacity < count) {
      return false;
    }
    long lengthCapacity = bufferLength(lengths);
    if (lengthCapacity < count) {
      return false;
    }
    if (expectedWord == 0) {
      return false;
    }
    long kind = kinds[token];
    boolean identifier = kind == 1;
    if (identifier == false) {
      return false;
    }
    long word = manifestTokenWord(source, starts, lengths, token);
    boolean sameWord = word == expectedWord;
    if (sameWord == false) {
      return false;
    }
    long colonToken = token + 1;
    boolean colon = colonAt(source, kinds, starts, colonToken);
    return colon;
  }
}
