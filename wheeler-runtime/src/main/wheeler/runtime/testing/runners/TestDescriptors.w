//! Validates canonical discovered case names and descriptor order.

module wheeler.runtime.testing.runners.test_descriptors;

classical class TestDescriptors {
  private const long MAX_CASE_NAME_BYTES = 255;

  private boolean nameScalar(long scalar) {
    if (47 < scalar) {
      if (scalar < 58) {
        return true;
      }
    }

    if (64 < scalar) {
      if (scalar < 91) {
        return true;
      }
    }

    if (96 < scalar) {
      if (scalar < 123) {
        return true;
      }
    }

    if (scalar == 45) {
      return true;
    }

    if (scalar == 46) {
      return true;
    }

    if (scalar == 58) {
      return true;
    }

    if (scalar == 91) {
      return true;
    }

    if (scalar == 93) {
      return true;
    }

    return scalar == 95;
  }

  /// Checks one bounded canonical package-scoped case display name.
  public boolean validCaseName(borrow byteview input, long start, long length) {
    if (length == 0) {
      return false;
    }

    if (MAX_CASE_NAME_BYTES < length) {
      return false;
    }

    if (input[start] == 58) {
      return false;
    }

    if (input[start + length - 1] == 58) {
      return false;
    }

    long offset = 0;
    while (offset < length) limit MAX_CASE_NAME_BYTES {
      if (nameScalar(input[start + offset]) == false) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  /// Compares two names by unsigned canonical UTF-8 bytes.
  public long compareCaseName(
    borrow byteview input,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long offset = 0;
    while (offset < shared) limit MAX_CASE_NAME_BYTES {
      long left = input[leftStart + offset];
      long right = input[rightStart + offset];
      if (left < right) {
        return -1;
      }

      if (right < left) {
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
}
