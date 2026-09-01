//! Validates the root field of one package-manifest target row.

module wheeler.compiler.packages.manifest_target_root;

import wheeler.compiler.packages.manifest_keys;
import wheeler.compiler.packages.manifest_tokens;
import wheeler.compiler.packages.paths;

classical class PackageManifestTargetRoot {
  /// Checks the relative root key and quoted logical path.
  public boolean manifestTargetRootValid(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long cursor
  ) {
    long keyToken = cursor + 7;
    long keyHash = 3506402;
    boolean rootKey = manifestKeyAt(source, kinds, starts, lengths, count, keyToken, keyHash);
    if (rootKey == false) {
      return false;
    }

    long rootToken = cursor + 9;
    boolean rootQuoted = quoted(kinds, lengths, rootToken);
    if (rootQuoted == false) {
      return false;
    }

    long tokenStart = starts[rootToken];
    long tokenLength = lengths[rootToken];
    long rootStart = tokenStart + 1;
    long rootLength = tokenLength - 2;
    boolean rootValid = validLogicalPath(source, rootStart, rootLength);
    return rootValid;
  }
}
