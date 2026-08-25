//! Owns fail-closed assertions over bootstrap metadata transports.

module wheeler.compiler.closure.manifest_assertions;

classical class BootstrapManifestAssertions {
  /// Traps before publication when one metadata condition fails.
  public void requireMetadata(boolean condition) {
    assert(condition);
  }
}
