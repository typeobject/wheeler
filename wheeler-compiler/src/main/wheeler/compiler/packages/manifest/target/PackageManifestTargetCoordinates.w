//! Projects package-manifest target token coordinates.

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

  /// Returns the optional module-key token coordinate.
  public long manifestTargetModuleKeyToken(long cursor) {
    return cursor + 10;
  }

  /// Returns the optional quoted module-name token coordinate.
  public long manifestTargetModuleToken(long cursor) {
    return cursor + 12;
  }

  /// Returns the source-selector key token coordinate of a modular target.
  public long manifestTargetSourcesKeyToken(long cursor) {
    return cursor + 13;
  }

  /// Returns the first source-selector row coordinate of a modular target.
  public long manifestTargetFirstSourceRowToken(long cursor) {
    return cursor + 15;
  }

  /// Returns the quoted selector coordinate for one source row.
  public long manifestTargetSelectorToken(long rowToken) {
    return rowToken + 1;
  }

  /// Returns the row coordinate after one source selector.
  public long manifestTargetNextSourceRowToken(long rowToken) {
    return rowToken + 2;
  }

  /// Returns the Boolean value coordinate for the test field.
  public long manifestTargetTestToken(long testKeyToken) {
    return testKeyToken + 2;
  }

  /// Returns the coordinate after a complete target row.
  public long manifestTargetNextToken(long testKeyToken) {
    return testKeyToken + 3;
  }
}
