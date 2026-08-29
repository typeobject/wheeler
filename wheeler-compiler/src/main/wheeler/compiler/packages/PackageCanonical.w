//! Checks the byte layout of parsed canonical package manifests.

module wheeler.compiler.packages.canonical;

import wheeler.compiler.packages.canonical_coordinates;
import wheeler.compiler.packages.canonical_lines;
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
    long sourceLength = bufferLength(source);
    if (0 < sourceLength) {} else {
      return false;
    }

    if (sourceLength < MAX_PACKAGE_MANIFEST_BYTES + 1) {} else {
      return false;
    }

    if (utf8Scalar(source, sourceLength - 1) == 10) {} else {
      return false;
    }

    long cursor = 0;
    long token = 0;
    long line = 0;
    long section = 0;
    while (cursor < sourceLength) limit MAX_PACKAGE_MANIFEST_BYTES {
      long end = canonicalLineEnd(source, cursor);
      if (cursor < end) {} else {
        return false;
      }

      if (token < count) {} else {
        return false;
      }

      if (starts[token] < end) {} else {
        return false;
      }

      long first = token;
      while (token < count) limit MAX_PACKAGE_MANIFEST_BYTES {
        if (starts[token] < end) {
          token += 1;
        } else {
          break;
        }
      }

      long lineTokens = token - first;
      long indent = 0;
      if (line < 2) {
        indent = 0;
      } else {
        if (line < 5) {
          indent = 2;
        } else {
          if (line == 5) {
            indent = 0;
            section = 1;
          } else {
            long hash = tokenHash(source, starts, lengths, first);
            if (hash == 2626680644436426025) {
              indent = 0;
              section = 2;
            } else {
              if (hash == 2597989917310390198) {
                indent = 0;
                section = 3;
              } else {
                if (kinds[first] == 3) {
                  if (lineTokens == 2) {
                    indent = 6;
                  } else {
                    indent = 2;
                  }
                } else {
                  indent = 4;
                }
              }
            }
          }
        }
      }

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

    if (token == count) {
      return section == 3;
    }

    return false;
  }
}
