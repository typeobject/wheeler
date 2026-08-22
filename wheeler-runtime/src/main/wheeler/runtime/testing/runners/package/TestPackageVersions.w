//! Checks semantic-version constraints against locked package versions.

module wheeler.runtime.testing.runners.test_package_versions;

classical class TestPackageVersions {
  private const long MAX_METADATA_BYTES = 4096;

  private record SemanticVersion(
    boolean valid,
    long major,
    long minor,
    long patch,
    long prereleaseStart,
    long prereleaseLength
  ) {}

  private record LockedVersion(boolean found, long start, long length) {}

  private long rangeHash(borrow byteview input, long start, long length) {
    long hash = 0;
    long offset = 0;
    while (offset < length) limit MAX_METADATA_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash;
  }

  private long lineEnd(borrow byteview input, long cursor, long end) {
    long scan = cursor;
    while (scan < end) limit MAX_METADATA_BYTES {
      if (input[scan] == 10) {
        return scan;
      }

      if (input[scan] == 13) {
        return -1;
      }

      scan += 1;
    }

    return -1;
  }

  private boolean sameRange(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 255 {
      if (input[leftStart + offset] != input[rightStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private LockedVersion lockedVersion(
    borrow byteview input,
    long lockStart,
    long lockLength,
    long nameStart,
    long nameLength
  ) {
    LockedVersion missing = new LockedVersion(false, 0, 0);
    long end = lockStart + lockLength;
    long cursor = lockStart;
    while (cursor < end) limit MAX_METADATA_BYTES {
      long found = lineEnd(input, cursor, end);
      if (found < 0) {
        return missing;
      }

      if (found - cursor == nameLength + 12) {
        if (rangeHash(input, cursor, /* length= */ 11) == 586558766) {
          if (sameRange(input, cursor + 11, nameLength, nameStart, nameLength)) {
            cursor = found + 1;
            found = lineEnd(input, cursor, end);
            if (found < 0) {
              return missing;
            }

            long versionLength = found - cursor - 15;
            if (versionLength < 1) {
              return missing;
            }

            if (rangeHash(input, cursor, /* length= */ 14) != 42952952) {
              return missing;
            }

            if (input[found - 1] != 34) {
              return missing;
            }

            return new LockedVersion(true, cursor + 14, versionLength);
          }
        }
      }

      cursor = found + 1;
    }

    return missing;
  }

  private long decimalEnd(borrow byteview input, long start, long end, long separator) {
    long cursor = start;
    while (cursor < end) limit 20 {
      if (input[cursor] == separator) {
        return cursor;
      }

      if (input[cursor] < 48) {
        return -1;
      }

      if (57 < input[cursor]) {
        return -1;
      }

      cursor += 1;
    }

    return -1;
  }

  private long decimalValue(borrow byteview input, long start, long end) {
    if (start < end) {} else {
      return -1;
    }

    if (input[start] == 48) {
      if (start + 1 < end) {
        return -1;
      }
    }

    if (18 < end - start) {
      return -1;
    }

    long value = 0;
    long cursor = start;
    while (cursor < end) limit 18 {
      value = value * 10 + input[cursor] - 48;
      cursor += 1;
    }

    return value;
  }

  private boolean validPrereleaseIdentifier(borrow byteview input, long start, long end) {
    if (start < end) {} else {
      return false;
    }

    boolean numeric = true;
    long cursor = start;
    while (cursor < end) limit 255 {
      long value = input[cursor];
      boolean digit = 47 < value;
      if (digit) {
        digit = value < 58;
      }

      boolean upper = 64 < value;
      if (upper) {
        upper = value < 91;
      }

      boolean lower = 96 < value;
      if (lower) {
        lower = value < 123;
      }

      if (digit == false) {
        numeric = false;
        if (upper == false) {
          if (lower == false) {
            if (value != 45) {
              return false;
            }
          }
        }
      }

      cursor += 1;
    }

    if (numeric) {
      if (input[start] == 48) {
        return end - start == 1;
      }
    }

    return true;
  }

  private boolean validPrerelease(borrow byteview input, long start, long length) {
    if (length < 1) {
      return false;
    }

    long end = start + length;
    long identifierStart = start;
    long cursor = start;
    while (cursor < end) limit 255 {
      if (input[cursor] == 46) {
        if (validPrereleaseIdentifier(input, identifierStart, cursor) == false) {
          return false;
        }

        identifierStart = cursor + 1;
      }

      cursor += 1;
    }

    return validPrereleaseIdentifier(input, identifierStart, end);
  }

  private SemanticVersion semanticVersion(borrow byteview input, long start, long length) {
    SemanticVersion invalid = new SemanticVersion(false, 0, 0, 0, 0, 0);
    if (length < 5) {
      return invalid;
    }

    long end = start + length;
    long first = decimalEnd(input, start, end, /* separator= */ 46);
    if (first < 0) {
      return invalid;
    }

    long second = decimalEnd(input, first + 1, end, /* separator= */ 46);
    if (second < 0) {
      return invalid;
    }

    long patchStart = second + 1;
    if (patchStart < end) {} else {
      return invalid;
    }

    long releaseEnd = end;
    long cursor = patchStart;
    boolean foundPrerelease = false;
    while (cursor < end) limit 255 {
      if (foundPrerelease == false) {
        if (input[cursor] == 45) {
          releaseEnd = cursor;
          foundPrerelease = true;
        } else {
          if (input[cursor] < 48) {
            return invalid;
          }

          if (57 < input[cursor]) {
            return invalid;
          }
        }
      }

      cursor += 1;
    }

    long major = decimalValue(input, start, first);
    long minor = decimalValue(input, first + 1, second);
    long patch = decimalValue(input, patchStart, releaseEnd);
    if (major < 0) {
      return invalid;
    }

    if (minor < 0) {
      return invalid;
    }

    if (patch < 0) {
      return invalid;
    }

    long prereleaseStart = end;
    long prereleaseLength = 0;
    if (foundPrerelease) {
      prereleaseStart = releaseEnd + 1;
      prereleaseLength = end - prereleaseStart;
      if (validPrerelease(input, prereleaseStart, prereleaseLength) == false) {
        return invalid;
      }
    }

    return new SemanticVersion(true, major, minor, patch, prereleaseStart, prereleaseLength);
  }

  private long compareRelease(SemanticVersion left, SemanticVersion right) {
    if (left.major < right.major) {
      return -1;
    }

    if (right.major < left.major) {
      return 1;
    }

    if (left.minor < right.minor) {
      return -1;
    }

    if (right.minor < left.minor) {
      return 1;
    }

    if (left.patch < right.patch) {
      return -1;
    }

    if (right.patch < left.patch) {
      return 1;
    }

    return 0;
  }

  private long identifierEnd(borrow byteview input, long start, long end) {
    long cursor = start;
    while (cursor < end) limit 255 {
      if (input[cursor] == 46) {
        return cursor;
      }

      cursor += 1;
    }

    return end;
  }

  private boolean numericIdentifier(borrow byteview input, long start, long end) {
    long cursor = start;
    while (cursor < end) limit 255 {
      if (input[cursor] < 48) {
        return false;
      }

      if (57 < input[cursor]) {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private long compareIdentifier(
    borrow byteview input,
    long leftStart,
    long leftEnd,
    long rightStart,
    long rightEnd
  ) {
    boolean leftNumeric = numericIdentifier(input, leftStart, leftEnd);
    boolean rightNumeric = numericIdentifier(input, rightStart, rightEnd);
    if (leftNumeric) {
      if (rightNumeric == false) {
        return -1;
      }

      if (leftEnd - leftStart < rightEnd - rightStart) {
        return -1;
      }

      if (rightEnd - rightStart < leftEnd - leftStart) {
        return 1;
      }
    } else {
      if (rightNumeric) {
        return 1;
      }
    }

    long leftLength = leftEnd - leftStart;
    long rightLength = rightEnd - rightStart;
    long length = leftLength;
    if (rightLength < length) {
      length = rightLength;
    }

    long offset = 0;
    while (offset < length) limit 255 {
      if (input[leftStart + offset] < input[rightStart + offset]) {
        return -1;
      }

      if (input[rightStart + offset] < input[leftStart + offset]) {
        return 1;
      }

      offset += 1;
    }

    if (leftLength < rightLength) {
      return -1;
    }

    if (rightLength < leftLength) {
      return 1;
    }

    return 0;
  }

  private long comparePrerelease(
    borrow byteview input,
    SemanticVersion left,
    SemanticVersion right
  ) {
    if (left.prereleaseLength == 0) {
      if (right.prereleaseLength == 0) {
        return 0;
      }

      return 1;
    }

    if (right.prereleaseLength == 0) {
      return -1;
    }

    long leftEnd = left.prereleaseStart + left.prereleaseLength;
    long rightEnd = right.prereleaseStart + right.prereleaseLength;
    long leftCursor = left.prereleaseStart;
    long rightCursor = right.prereleaseStart;
    while (leftCursor < leftEnd) limit 64 {
      if (rightCursor < rightEnd) {} else {
        return 1;
      }

      long leftIdentifierEnd = identifierEnd(input, leftCursor, leftEnd);
      long rightIdentifierEnd = identifierEnd(input, rightCursor, rightEnd);
      long comparison = compareIdentifier(
        input,
        leftCursor,
        leftIdentifierEnd,
        rightCursor,
        rightIdentifierEnd
      );
      if (comparison != 0) {
        return comparison;
      }

      leftCursor = leftIdentifierEnd + 1;
      rightCursor = rightIdentifierEnd + 1;
    }

    if (rightCursor < rightEnd) {
      return -1;
    }

    return 0;
  }

  private long compareSemanticVersions(
    borrow byteview input,
    SemanticVersion left,
    SemanticVersion right
  ) {
    long release = compareRelease(left, right);
    if (release != 0) {
      return release;
    }

    return comparePrerelease(input, left, right);
  }

  /// Checks exact, caret, or tilde constraints for one locked package.
  public boolean lockedVersionAcceptsConstraint(
    borrow byteview input,
    long lockStart,
    long lockLength,
    long nameStart,
    long nameLength,
    long constraintStart,
    long constraintLength
  ) {
    LockedVersion locked = lockedVersion(input, lockStart, lockLength, nameStart, nameLength);
    if (locked.found == false) {
      return false;
    }

    if (constraintLength < 2) {
      return false;
    }

    long kind = input[constraintStart];
    if (kind != 61) {
      if (kind != 94) {
        if (kind != 126) {
          return false;
        }
      }
    }

    SemanticVersion minimum = semanticVersion(input, constraintStart + 1, constraintLength - 1);
    SemanticVersion candidate = semanticVersion(input, locked.start, locked.length);
    if (minimum.valid == false) {
      return false;
    }

    if (candidate.valid == false) {
      return false;
    }

    if (candidate.prereleaseLength != 0) {
      if (minimum.prereleaseLength == 0) {
        return false;
      }
    }

    long comparison = compareSemanticVersions(input, candidate, minimum);
    if (comparison < 0) {
      return false;
    }

    if (kind == 61) {
      return comparison == 0;
    }

    if (kind == 126) {
      if (candidate.major != minimum.major) {
        return false;
      }

      return candidate.minor == minimum.minor;
    }

    if (0 < minimum.major) {
      return candidate.major == minimum.major;
    }

    if (0 < minimum.minor) {
      if (candidate.major != 0) {
        return false;
      }

      return candidate.minor == minimum.minor;
    }

    if (candidate.major != 0) {
      return false;
    }

    if (candidate.minor != 0) {
      return false;
    }

    return candidate.patch == minimum.patch;
  }
}
