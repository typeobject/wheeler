//! Validates the package-manifest name header field.

module wheeler.compiler.packages.manifest_header_name;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;
import wheeler.compiler.packages.names;

classical class PackageManifestHeaderName {
  /// Checks the fixed name key and its quoted package name.
  public boolean manifestHeaderNameValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    long keyToken = 5;
    long nameWord = WORD_NAME;
    boolean nameKey = manifestKeyAt(source, kinds, starts, lengths, count, keyToken, nameWord);
    if (nameKey == false) {
      return false;
    }

    long nameToken = 7;
    boolean nameQuoted = quoted(kinds, lengths, nameToken);
    if (nameQuoted == false) {
      return false;
    }

    long tokenStart = starts[nameToken];
    long tokenLength = lengths[nameToken];
    long nameStart = tokenStart + 1;
    long nameLength = tokenLength - 2;
    boolean nameValid = validPackageName(source, nameStart, nameLength);
    return nameValid;
  }
}
