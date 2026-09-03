//! Projects package-manifest target source-selector coordinates.

module wheeler.compiler.packages.manifest_target_source_coordinates;

classical class PackageManifestTargetSourceCoordinates {
  /// Returns the first byte inside a quoted source-selector token.
  public long manifestTargetSourceStart(borrow mut words starts, long selectorToken) {
    long tokenStart = starts[selectorToken];
    long sourceStart = tokenStart + 1;
    return sourceStart;
  }

  /// Returns the byte count inside a quoted source-selector token.
  public long manifestTargetSourceLength(borrow mut words lengths, long selectorToken) {
    long tokenLength = lengths[selectorToken];
    long sourceLength = tokenLength - 2;
    return sourceLength;
  }
}
