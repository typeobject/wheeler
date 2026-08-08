//! Checks the byte layout of parsed canonical package manifests.

module wheeler.compiler.packages.canonical;

import wheeler.compiler.packages.manifest_tokens;

classical class PackageCanonical {
  private const long MAX_PACKAGE_MANIFEST_BYTES = 262144;

  private long lineEnd(borrow utf8 source, long start) {
    long cursor = start;
    while (cursor < bufferLength(source)) limit MAX_PACKAGE_MANIFEST_BYTES {
      if (utf8Scalar(source, cursor) == 10) {
        return cursor;
      }

      cursor += utf8Width(source, cursor);
    }

    return cursor;
  }

  private boolean exactIndent(
    borrow utf8 source,
    long lineStart,
    long tokenStart,
    long expected
  ) {
    if (tokenStart == lineStart + expected) {} else {
      return false;
    }

    long cursor = lineStart;
    while (cursor < tokenStart) limit 6 {
      if (utf8Scalar(source, cursor) == 32) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean plainLine(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens,
    long lineStart,
    long lineEnd,
    long indent
  ) {
    if (lineTokens == 2) {} else {
      if (lineTokens == 3) {} else {
        if (lineTokens == 4) {} else {
          return false;
        }
      }
    }

    if (exactIndent(source, lineStart, starts[first], indent)) {} else {
      return false;
    }

    long keyEnd = starts[first] + lengths[first];
    if (starts[first + 1] == keyEnd) {} else {
      return false;
    }

    if (kinds[first + 1] == 3) {} else {
      return false;
    }

    if (utf8Scalar(source, starts[first + 1]) == 58) {} else {
      return false;
    }

    long finalToken = first + 1;
    if (2 < lineTokens) {
      long colonEnd = starts[first + 1] + lengths[first + 1];
      if (starts[first + 2] == colonEnd + 1) {} else {
        return false;
      }

      if (utf8Scalar(source, colonEnd) == 32) {} else {
        return false;
      }

      finalToken = first + 2;
      if (lineTokens == 4) {
        if (starts[first + 3] == starts[first + 2] + lengths[first + 2]) {} else {
          return false;
        }

        finalToken = first + 3;
      }
    }

    return starts[finalToken] + lengths[finalToken] == lineEnd;
  }

  private boolean dashedLine(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens,
    long lineStart,
    long lineEnd,
    long indent
  ) {
    if (lineTokens == 2) {} else {
      if (lineTokens == 4) {} else {
        return false;
      }
    }

    if (exactIndent(source, lineStart, starts[first], indent)) {} else {
      return false;
    }

    if (kinds[first] == 3) {} else {
      return false;
    }

    if (utf8Scalar(source, starts[first]) == 45) {} else {
      return false;
    }

    long dashEnd = starts[first] + lengths[first];
    if (starts[first + 1] == dashEnd + 1) {} else {
      return false;
    }

    if (utf8Scalar(source, dashEnd) == 32) {} else {
      return false;
    }

    long finalToken = first + 1;
    if (lineTokens == 4) {
      long keyEnd = starts[first + 1] + lengths[first + 1];
      if (starts[first + 2] == keyEnd) {} else {
        return false;
      }

      if (utf8Scalar(source, starts[first + 2]) == 58) {} else {
        return false;
      }

      long colonEnd = starts[first + 2] + lengths[first + 2];
      if (starts[first + 3] == colonEnd + 1) {} else {
        return false;
      }

      if (utf8Scalar(source, colonEnd) == 32) {} else {
        return false;
      }

      finalToken = first + 3;
    }

    return starts[finalToken] + lengths[finalToken] == lineEnd;
  }

  private boolean canonicalLine(
    borrow utf8 source,
    borrow mut words kinds,
    borrow mut words starts,
    borrow mut words lengths,
    long first,
    long lineTokens,
    long lineStart,
    long lineEnd,
    long indent
  ) {
    if (kinds[first] == 3) {
      if (utf8Scalar(source, starts[first]) == 45) {
        return dashedLine(
          source,
          kinds,
          starts,
          lengths,
          first,
          lineTokens,
          lineStart,
          lineEnd,
          indent
        );
      }
    }

    return plainLine(
      source,
      kinds,
      starts,
      lengths,
      first,
      lineTokens,
      lineStart,
      lineEnd,
      indent
    );
  }

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
      long end = lineEnd(source, cursor);
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

      if (
        canonicalLine(
          source,
          kinds,
          starts,
          lengths,
          first,
          lineTokens,
          cursor,
          end,
          indent
        )
      ) {} else {
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
