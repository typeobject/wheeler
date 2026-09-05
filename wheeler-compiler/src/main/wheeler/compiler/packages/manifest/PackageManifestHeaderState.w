//! Classifies scalar package-manifest header state.

module wheeler.compiler.packages.manifest_header_state;

import wheeler.compiler.packages.manifest_words;

classical class PackageManifestHeaderState {
  /// Checks whether the fixed header and one collection row can fit.
  public boolean manifestHeaderTokenCount(long count) {
    if (count < 35) {
      return false;
    }

    return true;
  }

  /// Checks the exact schema-version word returned by manifest token policy.
  public boolean manifestFormatVersion(long word) {
    return word == WORD_SCHEMA_VERSION;
  }
}
