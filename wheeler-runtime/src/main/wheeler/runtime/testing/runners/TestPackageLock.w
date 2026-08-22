//! Validates a canonical dependency-free package lock root.

module wheeler.runtime.testing.runners.test_package_lock;

classical class TestPackageLock {
  private boolean validPrefix(borrow byteview input, long start) {
    if (input[start] != 115) {
      return false;
    }

    if (input[start + 1] != 99) {
      return false;
    }

    if (input[start + 2] != 104) {
      return false;
    }

    if (input[start + 3] != 101) {
      return false;
    }

    if (input[start + 4] != 109) {
      return false;
    }

    if (input[start + 5] != 97) {
      return false;
    }

    if (input[start + 6] != 58) {
      return false;
    }

    if (input[start + 7] != 32) {
      return false;
    }

    if (input[start + 8] != 51) {
      return false;
    }

    if (input[start + 9] != 10) {
      return false;
    }

    if (input[start + 10] != 114) {
      return false;
    }

    if (input[start + 11] != 111) {
      return false;
    }

    if (input[start + 12] != 111) {
      return false;
    }

    if (input[start + 13] != 116) {
      return false;
    }

    if (input[start + 14] != 58) {
      return false;
    }

    if (input[start + 15] != 32) {
      return false;
    }

    return input[start + 16] == 34;
  }

  private boolean validSuffix(borrow byteview input, long start) {
    if (input[start] != 34) {
      return false;
    }

    if (input[start + 1] != 10) {
      return false;
    }

    if (input[start + 2] != 112) {
      return false;
    }

    if (input[start + 3] != 97) {
      return false;
    }

    if (input[start + 4] != 99) {
      return false;
    }

    if (input[start + 5] != 107) {
      return false;
    }

    if (input[start + 6] != 97) {
      return false;
    }

    if (input[start + 7] != 103) {
      return false;
    }

    if (input[start + 8] != 101) {
      return false;
    }

    if (input[start + 9] != 115) {
      return false;
    }

    if (input[start + 10] != 58) {
      return false;
    }

    if (input[start + 11] != 32) {
      return false;
    }

    if (input[start + 12] != 91) {
      return false;
    }

    if (input[start + 13] != 93) {
      return false;
    }

    return input[start + 14] == 10;
  }

  /// Checks canonical schema-3 bytes and binds the root to the manifest identity.
  public boolean validEmptyPackageLock(
    borrow byteview input,
    long start,
    long length,
    borrow byteview manifestIdentity
  ) {
    if (length != 96) {
      return false;
    }

    if (bufferLength(input) < start + length) {
      return false;
    }

    if (bufferLength(manifestIdentity) != 64) {
      return false;
    }

    if (validPrefix(input, start) == false) {
      return false;
    }

    long offset = 0;
    while (offset < 64) limit 64 {
      if (input[start + 17 + offset] != manifestIdentity[offset]) {
        return false;
      }

      offset += 1;
    }

    return validSuffix(input, start + 81);
  }
}
