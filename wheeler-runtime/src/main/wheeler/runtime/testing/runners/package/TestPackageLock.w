//! Validates canonical package lock roots and dependency entries.

module wheeler.runtime.testing.runners.test_package_lock;

classical class TestPackageLock {
  private const long MAX_LOCK_BYTES = 4096;
  private const long MAX_PACKAGES = 64;

  private long rangeHash(borrow byteview input, long start, long length) {
    long hash = 0;
    long offset = 0;
    while (offset < length) limit MAX_LOCK_BYTES {
      hash = (hash * 131 + input[start + offset]) % 4294967296;
      offset += 1;
    }

    return hash;
  }

  private long lineEnd(borrow byteview input, long cursor, long end) {
    long scan = cursor;
    while (scan < end) limit MAX_LOCK_BYTES {
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

  private boolean quotedLine(
    borrow byteview input,
    long start,
    long end,
    long prefixLength,
    long prefixHash,
    long valueLength,
    boolean hexadecimal
  ) {
    if (end - start != prefixLength + valueLength + 1) {
      return false;
    }

    if (rangeHash(input, start, prefixLength) != prefixHash) {
      return false;
    }

    if (input[end - 1] != 34) {
      return false;
    }

    long offset = 0;
    while (offset < valueLength) limit MAX_LOCK_BYTES {
      long value = input[start + prefixLength + offset];
      if (hexadecimal) {
        boolean digit = 47 < value;
        if (digit) {
          digit = value < 58;
        }

        boolean lower = 96 < value;
        if (lower) {
          lower = value < 103;
        }

        if (digit == false) {
          if (lower == false) {
            return false;
          }
        }
      } else {
        if (value < 33) {
          return false;
        }

        if (126 < value) {
          return false;
        }

        if (value == 34) {
          return false;
        }
      }

      offset += 1;
    }

    return true;
  }

  private boolean containsPackageName(
    borrow byteview input,
    long start,
    long length,
    long nameStart,
    long nameLength
  ) {
    long end = start + length;
    long cursor = start;
    while (cursor < end) limit MAX_LOCK_BYTES {
      long found = lineEnd(input, cursor, end);
      if (found < 0) {
        return false;
      }

      if (found - cursor == nameLength + 12) {
        if (rangeHash(input, cursor, /* length= */ 11) == 586558766) {
          if (input[found - 1] != 34) {
            return false;
          }

          if (
            compareRanges(input, cursor + 11, nameLength, nameStart, nameLength) == 0
          ) {
            return true;
          }
        }
      }

      cursor = found + 1;
    }

    return false;
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

  /// Checks canonical schema-3 bytes and binds the root to the manifest identity.
  public boolean validPackageLock(
    borrow byteview input,
    long start,
    long length,
    borrow byteview manifestIdentity
  ) {
    if (length < 96) {
      return false;
    }

    if (MAX_LOCK_BYTES < length) {
      return false;
    }

    if (bufferLength(input) < start + length) {
      return false;
    }

    if (bufferLength(manifestIdentity) != 64) {
      return false;
    }

    if (rangeHash(input, start, /* length= */ 17) != 3927459012) {
      return false;
    }

    long offset = 0;
    while (offset < 64) limit 64 {
      if (input[start + 17 + offset] != manifestIdentity[offset]) {
        return false;
      }

      offset += 1;
    }

    if (input[start + 81] != 34) {
      return false;
    }

    if (input[start + 82] != 10) {
      return false;
    }

    if (length == 96) {
      return rangeHash(input, start + 81, /* length= */ 15) == 1456121433;
    }

    long end = start + length;
    long cursor = start + 83;
    long found = lineEnd(input, cursor, end);
    if (found < 0) {
      return false;
    }

    if (
      exactLine(input, cursor, found, /* length= */ 9, /* hash= */ 3943957573) == false
    ) {
      return false;
    }

    cursor = found + 1;
    long packageCount = 0;
    long previousNameStart = 0;
    long previousNameLength = 0;
    while (cursor < end) limit MAX_PACKAGES {
      found = lineEnd(input, cursor, end);
      if (found < 0) {
        return false;
      }

      long nameLength = found - cursor - 12;
      if (nameLength < 1) {
        return false;
      }

      if (
        quotedLine(input, cursor, found, 11, 586558766, nameLength, false) == false
      ) {
        return false;
      }

      long nameStart = cursor + 11;
      if (0 < packageCount) {
        if (
          compareRanges(input, previousNameStart, previousNameLength, nameStart, nameLength) != - 1
        ) {
          return false;
        }
      }

      previousNameStart = nameStart;
      previousNameLength = nameLength;
      cursor = found + 1;
      found = lineEnd(input, cursor, end);
      long versionLength = found - cursor - 15;
      if (versionLength < 1) {
        return false;
      }

      if (
        quotedLine(input, cursor, found, 14, 42952952, versionLength, false) == false
      ) {
        return false;
      }

      cursor = found + 1;
      found = lineEnd(input, cursor, end);
      if (quotedLine(input, cursor, found, 17, 2830827934, 64, true) == false) {
        return false;
      }

      cursor = found + 1;
      found = lineEnd(input, cursor, end);
      if (quotedLine(input, cursor, found, 15, 3301958240, 64, true) == false) {
        return false;
      }

      cursor = found + 1;
      found = lineEnd(input, cursor, end);
      if (quotedLine(input, cursor, found, 14, 2665284562, 64, true) == false) {
        return false;
      }

      cursor = found + 1;
      found = lineEnd(input, cursor, end);
      if (quotedLine(input, cursor, found, 15, 3265168425, 64, true) == false) {
        return false;
      }

      cursor = found + 1;
      found = lineEnd(input, cursor, end);
      if (exactLine(input, cursor, found, 20, 1528119609)) {
        cursor = found + 1;
      } else {
        if (exactLine(input, cursor, found, 17, 1805921201) == false) {
          return false;
        }

        cursor = found + 1;
        long dependencyCount = 0;
        long previousDependencyStart = 0;
        long previousDependencyLength = 0;
        boolean scanningDependencies = true;
        while (scanningDependencies) limit MAX_PACKAGES {
          if (cursor < end) {} else {
            scanningDependencies = false;
          }

          if (scanningDependencies) {
            found = lineEnd(input, cursor, end);
            if (found < 0) {
              return false;
            }

            long dependencyLength = found - cursor - 10;
            if (dependencyLength < 1) {
              scanningDependencies = false;
            } else {
              if (
                quotedLine(input, cursor, found, 9, 1271526807, dependencyLength, false) == false
              ) {
                scanningDependencies = false;
              } else {
                long dependencyStart = cursor + 9;
                if (0 < dependencyCount) {
                  if (
                    compareRanges(
                      input,
                      previousDependencyStart,
                      previousDependencyLength,
                      dependencyStart,
                      dependencyLength
                    ) != - 1
                  ) {
                    return false;
                  }
                }

                if (
                  containsPackageName(input, start, length, dependencyStart, dependencyLength)
                    == false
                ) {
                  return false;
                }

                previousDependencyStart = dependencyStart;
                previousDependencyLength = dependencyLength;
                dependencyCount += 1;
                cursor = found + 1;
              }
            }
          }
        }

        if (dependencyCount == 0) {
          return false;
        }
      }

      packageCount += 1;
    }

    if (packageCount == 0) {
      return false;
    }

    return cursor == end;
  }
}
