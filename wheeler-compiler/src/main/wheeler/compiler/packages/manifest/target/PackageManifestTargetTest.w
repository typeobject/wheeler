//! Applies package-manifest target test policy.

module wheeler.compiler.packages.manifest_target_test;

classical class PackageManifestTargetTest {
  /// Allows tests for deployables and tools but not libraries.
  public boolean manifestTargetTestAllowed(long kind, long test) {
    boolean disabled = test == 0;
    if (kind == 2) {
      return disabled;
    }

    return true;
  }
}
