//! Checks the byte layout of parsed canonical package manifests.

module wheeler.compiler.packages.canonical;

import wheeler.compiler.packages.canonical_coordinates;
import wheeler.compiler.packages.canonical_indent;
import wheeler.compiler.packages.canonical_lines;
import wheeler.compiler.packages.canonical_profile;
import wheeler.compiler.packages.canonical_token_window;
import wheeler.compiler.packages.manifest_tokens;

classical class PackageCanonical {
  private const long MAX_PACKAGE_MANIFEST_BYTES = 262144;

  /// Accepts only the exact spaces, indentation, line breaks, and final newline.
  ///
  /// `parseManifest` owns field order and values. This pass owns their physical layout.
  public boolean canonicalPackageManifest(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long count
  ) {
    boolean bounded = canonicalManifestBounds(source);
    if (bounded == false) {
      return false;
    }

    long sourceLength = bufferLength(source);

    long cursor = 0;
    long token = 0;
    long line = 0;
    long section = 0;
    while (cursor < sourceLength) limit MAX_PACKAGE_MANIFEST_BYTES {
      long end = canonicalLineEnd(source, cursor);
      if (cursor < end) {} else {
        return false;
      }

      long first = token;
      long nextToken = canonicalLineTokenEnd(starts, token, count, end);
      if (first < nextToken) {} else {
        return false;
      }

      token = nextToken;
      long lineTokens = token - first;
      long word = manifestTokenWord(source, starts, lengths, first);
      long firstKind = kinds[first];
      long nextSection = canonicalManifestSection(line, word, section);
      long indent = canonicalManifestIndent(line, word, firstKind, lineTokens);
      section = nextSection;

      boolean indentValid = canonicalExactIndent(source, cursor, starts[first], indent);
      if (indentValid == false) {
        return false;
      }

      boolean shapeValid = canonicalLineShape(
        source,
        kinds,
        starts,
        lengths,
        first,
        lineTokens
      );
      if (shapeValid == false) {
        return false;
      }

      boolean endValid = canonicalLineEndMatches(starts, lengths, first, lineTokens, end);
      if (endValid == false) {
        return false;
      }

      cursor = end + 1;
      line += 1;
    }

    return canonicalManifestComplete(token, count, section);
  }
}
