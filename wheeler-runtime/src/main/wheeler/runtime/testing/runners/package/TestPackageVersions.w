//! Checks stable semantic-version constraints against locked package versions.

module wheeler.runtime.testing.runners.test_package_versions;

classical class TestPackageVersions {
  private const long MAX_METADATA_BYTES = 4096;

  private record StableVersion(boolean valid, long major, long minor, long patch) {}

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

  private StableVersion stableVersion(borrow byteview input, long start, long length) {
    StableVersion invalid = new StableVersion(false, 0, 0, 0);
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

    long cursor = patchStart;
    while (cursor < end) limit 18 {
      if (input[cursor] < 48) {
        return invalid;
      }

      if (57 < input[cursor]) {
        return invalid;
      }

      cursor += 1;
    }

    long major = decimalValue(input, start, first);
    long minor = decimalValue(input, first + 1, second);
    long patch = decimalValue(input, patchStart, end);
    if (major < 0) {
      return invalid;
    }

    if (minor < 0) {
      return invalid;
    }

    if (patch < 0) {
      return invalid;
    }

    return new StableVersion(true, major, minor, patch);
  }

  private long compareStableVersions(StableVersion left, StableVersion right) {
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

  /// Checks exact, caret, or tilde stable constraints for one locked package.
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

    StableVersion minimum = stableVersion(input, constraintStart + 1, constraintLength - 1);
    StableVersion candidate = stableVersion(input, locked.start, locked.length);
    if (minimum.valid == false) {
      return false;
    }

    if (candidate.valid == false) {
      return false;
    }

    long comparison = compareStableVersions(candidate, minimum);
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
