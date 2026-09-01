//! Validates the name field of one package-manifest dependency row.

module wheeler.compiler.packages.manifest_dependency_name;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.names;

classical class PackageManifestDependencyName {
  /// Checks the relative name key and canonical quoted package name.
  public boolean manifestDependencyNameValid(
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
    boolean nameValid = validPackageName(source, nameStart, nameLength);
    return nameValid;
  }
}
