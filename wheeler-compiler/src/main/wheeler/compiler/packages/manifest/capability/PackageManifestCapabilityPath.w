//! Validates the path field of one package-manifest capability row.

module wheeler.compiler.packages.manifest_capability_path;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.paths;

classical class PackageManifestCapabilityPath {
  /// Checks the relative path key and quoted logical path.
  public boolean manifestCapabilityPathValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long keyToken = cursor + 4;
    long keyHash = 3433509;
    boolean pathKey = manifestKeyAt(source, kinds, starts, lengths, count, keyToken, keyHash);
    if (pathKey == false) {
      return false;
    }

    long pathToken = cursor + 6;
    boolean pathQuoted = quoted(kinds, lengths, pathToken);
    if (pathQuoted == false) {
      return false;
    }

    long tokenStart = starts[pathToken];
    long tokenLength = lengths[pathToken];
    long pathStart = tokenStart + 1;
    long pathLength = tokenLength - 2;
    boolean pathValid = validLogicalPath(source, pathStart, pathLength);
    return pathValid;
  }

  /// Returns lexical order between adjacent capability names.
  public long manifestCapabilityNameOrder(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long previousNameToken,
    long currentNameToken
  ) {
    long order = compareTokenText(
      source,
      starts,
      lengths,
      previousNameToken,
      currentNameToken
    );
    return order;
  }

  /// Checks strict lexical order between paths for equal capability names.
  public boolean manifestCapabilityPathsOrdered(
    borrow utf8 source,
    borrow mut words starts,
    borrow mut words lengths,
    long previousPathToken,
    long currentPathToken
  ) {
    long order = compareTokenText(
      source,
      starts,
      lengths,
      previousPathToken,
      currentPathToken
    );
    return order < 0;
  }
}
