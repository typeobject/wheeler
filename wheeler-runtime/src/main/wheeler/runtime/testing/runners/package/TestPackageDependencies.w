//! Binds direct manifest dependencies to canonical lock package names.

module wheeler.runtime.testing.runners.test_package_dependencies;

import wheeler.runtime.testing.runners.test_package_versions;

classical class TestPackageDependencies {
  private const long MAX_MANIFEST_BYTES = 12288;
  private const long MAX_DEPENDENCIES = 64;

  private long rangeHash(borrow byteview input, long start, long length) {
    long hash = 0;
    long offset = 0;
    while (offset < length) limit MAX_MANIFEST_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash;
  }

  private long lineEnd(borrow byteview input, long cursor, long end) {
    long scan = cursor;
    while (scan < end) limit MAX_MANIFEST_BYTES {
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

  private boolean exactLine(
    borrow byteview input,
    long start,
    long end,
    long length,
    long hash
  ) {
    if (end - start != length) {
      return false;
    }

    return rangeHash(input, start, length) == hash;
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

  private long compareRanges(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
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

  private boolean quotedField(
    borrow byteview input,
    long start,
    long end,
    long prefixLength,
    long prefixHash
  ) {
    if (end - start < prefixLength + 2) {
      return false;
    }

    if (rangeHash(input, start, prefixLength) != prefixHash) {
      return false;
    }

    if (input[end - 1] != 34) {
      return false;
    }

    long cursor = start + prefixLength;
    while (cursor < end - 1) limit 255 {
      if (input[cursor] < 33) {
        return false;
      }

      if (126 < input[cursor]) {
        return false;
      }

      if (input[cursor] == 34) {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private boolean lockContainsPackageName(
    borrow byteview input,
    long lockStart,
    long lockLength,
    long nameStart,
    long nameLength
  ) {
    long end = lockStart + lockLength;
    long cursor = lockStart;
    while (cursor < end) limit MAX_MANIFEST_BYTES {
      long found = lineEnd(input, cursor, end);
      if (found < 0) {
        return false;
      }

      if (found - cursor == nameLength + 12) {
        if (rangeHash(input, cursor, /* length= */ 11) == 586558766) {
          if (input[found - 1] != 34) {
            return false;
          }

          if (sameRange(input, cursor + 11, nameLength, nameStart, nameLength)) {
            return true;
          }
        }
      }

      cursor = found + 1;
    }

    return false;
  }

  /// Checks direct dependency grammar, ordering, and lock-name inclusion.
  public boolean validManifestLockDependencies(
    borrow byteview input,
    long manifestStart,
    long manifestLength,
    long lockStart,
    long lockLength
  ) {
    long manifestEnd = manifestStart + manifestLength;
    long cursor = manifestStart;
    long found = -1;
    boolean foundDependencies = false;
    while (cursor < manifestEnd) limit MAX_MANIFEST_BYTES {
      found = lineEnd(input, cursor, manifestEnd);
      if (found < 0) {
        return false;
      }

      if (exactLine(input, cursor, found, 16, 1399774265)) {
        return lockLength == 96;
      }

      if (exactLine(input, cursor, found, 13, 344468657)) {
        foundDependencies = true;
        cursor = found + 1;
        break;
      }

      cursor = found + 1;
    }

    if (foundDependencies == false) {
      return false;
    }

    long count = 0;
    long previousNameStart = 0;
    long previousNameLength = 0;
    boolean scanning = true;
    while (scanning) limit MAX_DEPENDENCIES {
      if (cursor < manifestEnd) {} else {
        return false;
      }

      found = lineEnd(input, cursor, manifestEnd);
      if (found < 0) {
        return false;
      }

      if (exactLine(input, cursor, found, 13, 1665807620)) {
        scanning = false;
      } else {
        if (exactLine(input, cursor, found, 16, 2054217082)) {
          scanning = false;
        } else {
          boolean validKind = exactLine(input, cursor, found, 18, 3944386646);
          if (validKind == false) {
            validKind = exactLine(input, cursor, found, 23, 3674147532);
          }

          if (validKind == false) {
            validKind = exactLine(input, cursor, found, 17, 2515521793);
          }

          if (validKind == false) {
            return false;
          }

          cursor = found + 1;
          found = lineEnd(input, cursor, manifestEnd);
          if (found < 0) {
            return false;
          }

          if (quotedField(input, cursor, found, 11, 3709182977) == false) {
            return false;
          }

          long nameStart = cursor + 11;
          long nameLength = found - cursor - 12;
          if (0 < count) {
            if (
              compareRanges(
                input,
                previousNameStart,
                previousNameLength,
                nameStart,
                nameLength
              ) != - 1
            ) {
              return false;
            }
          }

          if (
            lockContainsPackageName(input, lockStart, lockLength, nameStart, nameLength) == false
          ) {
            return false;
          }

          previousNameStart = nameStart;
          previousNameLength = nameLength;
          cursor = found + 1;
          found = lineEnd(input, cursor, manifestEnd);
          if (found < 0) {
            return false;
          }

          if (quotedField(input, cursor, found, 14, 42952952) == false) {
            return false;
          }

          if (
            lockedVersionAcceptsConstraint(
              input,
              lockStart,
              lockLength,
              nameStart,
              nameLength,
              cursor + 14,
              found - cursor - 15
            ) == false
          ) {
            return false;
          }

          count += 1;
          cursor = found + 1;
        }
      }
    }

    if (count == 0) {
      return false;
    }

    return lockLength != 96;
  }
}
