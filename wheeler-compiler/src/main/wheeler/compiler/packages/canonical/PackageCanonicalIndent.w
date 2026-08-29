//! Selects canonical package-manifest sections and indentation.

module wheeler.compiler.packages.canonical_indent;

classical class PackageCanonicalIndent {
  private const long DEPENDENCIES_HASH = 2626680644436426025;
  private const long DEVELOPMENT_DEPENDENCIES_HASH = 2597989917310390198;

  /// Advances the canonical section at its three exact headers.
  public long canonicalManifestSection(long line, long hash, long current) {
    if (line < 5) {
      return current;
    }

    if (line == 5) {
      return 1;
    }

    if (hash == DEPENDENCIES_HASH) {
      return 2;
    }

    if (hash == DEVELOPMENT_DEPENDENCIES_HASH) {
      return 3;
    }

    return current;
  }

  /// Returns the exact indent for one canonical line kind.
  public long canonicalManifestIndent(long line, long hash, long firstKind, long lineTokens) {
    if (line < 2) {
      return 0;
    }

    if (line < 5) {
      return 2;
    }

    if (line == 5) {
      return 0;
    }

    if (hash == DEPENDENCIES_HASH) {
      return 0;
    }

    if (hash == DEVELOPMENT_DEPENDENCIES_HASH) {
      return 0;
    }

    boolean punctuation = firstKind == 3;
    if (punctuation == false) {
      return 4;
    }

    if (lineTokens == 2) {
      return 6;
    }

    return 2;
  }
}
