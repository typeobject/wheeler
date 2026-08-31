//! Classifies scalar package-manifest header state.

module wheeler.compiler.packages.manifest_header_state;

classical class PackageManifestHeaderState {
  /// Checks whether the fixed header and one collection row can fit.
  public boolean manifestHeaderTokenCount(long count) {
    if (count < 35) {
      return false;
    }

    return true;
  }

  /// Checks the canonical package-format version hash.
  public boolean manifestFormatVersion(long hash) {
    return hash == 49;
  }
}
