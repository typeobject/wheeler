//! Projects interior ranges from quoted package-manifest tokens.

module wheeler.compiler.packages.manifest_ranges;

classical class PackageManifestRanges {
  /// Returns the first scalar coordinate inside one quoted token.
  public long manifestQuotedStart(borrow mut words starts, long token) {
    long tokenStart = starts[token];
    return tokenStart + 1;
  }

  /// Returns the scalar length inside one quoted token.
  public long manifestQuotedLength(borrow mut words lengths, long token) {
    long tokenLength = lengths[token];
    return tokenLength - 2;
  }
}
