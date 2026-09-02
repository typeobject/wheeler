//! Applies package-manifest target test policy.

module wheeler.compiler.packages.manifest_target_test;

import wheeler.compiler.packages.manifest_keys;

classical class PackageManifestTargetTest {
  /// Checks whether the required test field starts at one token.
  public boolean manifestTargetTestPresent(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count,
    long keyToken
  ) {
    long keyHash = 3556498;
    boolean present = manifestKeyAt(
      source,
      kinds,
      starts,
      lengths,
      count,
      keyToken,
      keyHash
    );
    return present;
  }

  /// Allows tests for deployables and tools but not libraries.
  public boolean manifestTargetTestAllowed(long kind, long test) {
    boolean disabled = test == 0;
    if (kind == 2) {
      return disabled;
    }

    return true;
  }
}
