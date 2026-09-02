//! Projects package-manifest dependency coordinates.

module wheeler.compiler.packages.manifest_dependency_coordinates;

classical class PackageManifestDependencyCoordinates {
  /// Returns the dependency-name token for one row cursor.
  public long manifestDependencyNameToken(long cursor) {
    return cursor + 6;
  }

  /// Returns the dependency-version token for one row cursor.
  public long manifestDependencyVersionToken(long cursor) {
    return cursor + 9;
  }

  /// Returns the first token after one dependency row.
  public long manifestDependencyNextToken(long cursor) {
    return cursor + 10;
  }

  /// Returns the first byte inside one quoted dependency value.
  public long manifestDependencyValueStart(borrow mut words starts, long token) {
    long tokenStart = starts[token];
    long valueStart = tokenStart + 1;
    return valueStart;
  }

  /// Returns the byte count inside one quoted dependency value.
  public long manifestDependencyValueLength(borrow mut words lengths, long token) {
    long tokenLength = lengths[token];
    long valueLength = tokenLength - 2;
    return valueLength;
  }
}
