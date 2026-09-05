//! Selects canonical package-manifest sections and indentation.

module wheeler.compiler.packages.canonical_indent;

import wheeler.compiler.packages.manifest_words;

classical class PackageCanonicalIndent {
  /// Advances the canonical section at its three exact headers.
  public long canonicalManifestSection(long line, long word, long current) {
    if (line < 5) {
      return current;
    }

    if (line == 5) {
      return 1;
    }

    if (word == WORD_DEPENDENCIES) {
      return 2;
    }

    if (word == WORD_CAPABILITIES) {
      return 3;
    }

    return current;
  }

  /// Returns the exact indent for one canonical line kind.
  public long canonicalManifestIndent(long line, long word, long firstKind, long lineTokens) {
    if (line < 2) {
      return 0;
    }

    if (line < 5) {
      return 2;
    }

    if (line == 5) {
      return 0;
    }

    if (word == WORD_DEPENDENCIES) {
      return 0;
    }

    if (word == WORD_CAPABILITIES) {
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
