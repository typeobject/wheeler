//! Projects package-manifest capability coordinates.

module wheeler.compiler.packages.manifest_capability_coordinates;

classical class PackageManifestCapabilityCoordinates {
  /// Returns the capability-name token for one row cursor.
  public long manifestCapabilityNameToken(long cursor) {
    return cursor + 3;
  }

  /// Returns the capability-path token for one row cursor.
  public long manifestCapabilityPathToken(long cursor) {
    return cursor + 6;
  }

  /// Returns the first token after one capability row.
  public long manifestCapabilityNextToken(long cursor) {
    return cursor + 7;
  }

  /// Returns the first byte inside one quoted capability value.
  public long manifestCapabilityValueStart(borrow mut words starts, long token) {
    long tokenStart = starts[token];
    long valueStart = tokenStart + 1;
    return valueStart;
  }

  /// Returns the byte count inside one quoted capability value.
  public long manifestCapabilityValueLength(borrow mut words lengths, long token) {
    long tokenLength = lengths[token];
    long valueLength = tokenLength - 2;
    return valueLength;
  }
}
