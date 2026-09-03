//! Validates the name field of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_name;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.names;

classical class PackageManifestTargetName {
  /// Checks the relative name key and quoted workspace name.
  public boolean manifestTargetNameValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long keyToken = cursor + 4;
    long keyHash = 3373707;
    boolean nameKey = manifestKeyAt(source, kinds, starts, lengths, count, keyToken, keyHash);
    if (nameKey == false) {
      return false;
    }

    long nameToken = cursor + 6;
    boolean nameQuoted = quoted(kinds, lengths, nameToken);
    if (nameQuoted == false) {
      return false;
    }

    long tokenStart = starts[nameToken];
    long tokenLength = lengths[nameToken];
    long nameStart = tokenStart + 1;
    long nameLength = tokenLength - 2;
    boolean nameValid = validWorkspaceName(source, nameStart, nameLength);
    return nameValid;
  }

  /// Checks strict lexical order between adjacent target names.
  public boolean manifestTargetNamesOrdered(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long previousToken,
    long currentToken
  ) {
    long order = compareTokenText(source, starts, lengths, previousToken, currentToken);
    return order < 0;
  }
}
