//! Projects fixed package-manifest target token coordinates.

module wheeler.compiler.packages.manifest_target_coordinates;

classical class PackageManifestTargetCoordinates {
  /// Returns the quoted target-name token coordinate.
  public long manifestTargetNameToken(long cursor) {
    return cursor + 6;
  }

  /// Returns the quoted target-root token coordinate.
  public long manifestTargetRootToken(long cursor) {
    return cursor + 9;
  }
}
