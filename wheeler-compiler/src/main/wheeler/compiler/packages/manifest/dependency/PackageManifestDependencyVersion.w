//! Validates the version field of one package-manifest dependency row.

module wheeler.compiler.packages.manifest_dependency_version;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.manifest_words;
import wheeler.compiler.packages.semver;

classical class PackageManifestDependencyVersion {
  /// Checks the relative version key and quoted semantic-version constraint.
  public boolean manifestDependencyVersionValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long keyToken = cursor + 7;
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

    long versionToken = cursor + 9;
    boolean versionQuoted = quoted(kinds, lengths, versionToken);
    if (versionQuoted == false) {
      return false;
    }

    long tokenStart = starts[versionToken];
    long tokenLength = lengths[versionToken];
    long versionStart = tokenStart + 1;
    long versionLength = tokenLength - 2;
    boolean versionValid = validConstraint(source, versionStart, versionLength);
    return versionValid;
  }
}
