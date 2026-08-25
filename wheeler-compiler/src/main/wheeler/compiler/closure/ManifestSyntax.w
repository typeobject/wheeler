//! Owns strict bounded syntax checks for bootstrap closure metadata.

module wheeler.compiler.closure.manifest_syntax;

classical class ClosureManifestSyntax {
  /// Traps before publication when one metadata condition fails.
  public void requireMetadata(boolean condition, borrow byteview source) {
    assert(condition);
  }

  /// Consumes one exact caller-prepared ASCII fragment.
  public long consumeMetadata(
    borrow byteview source,
    long cursor,
    borrow mut bytes expected,
    long length
  ) {
    long sourceCursor = cursor;
    long expectedCursor = 0;
    while (expectedCursor < length) limit 2048 {
      long actual = source[sourceCursor];
      long wanted = expected[expectedCursor];
      actual ^= wanted;
      assert(actual == 0);
      sourceCursor += 1;
      expectedCursor += 1;
    }

    return sourceCursor;
  }

  /// Consumes one quoted lowercase SHA-256 identity.
  public long consumeQuotedIdentity(borrow byteview source, long cursor) {
    long scalarCount = 0;
    while (scalarCount < 64) limit 64 {
      boolean firstScalar = scalarCount == 0;
      if (firstScalar) {
        long opening = source[cursor];
        assert(opening == 34);
        cursor += 1;
      }

      long scalar = source[cursor];
      boolean valid = false;
      boolean letter = true;
      assert(47 < scalar);
      if (scalar < 58) {
        valid = true;
        letter = false;
      }

      if (letter) {
        assert(96 < scalar);
        assert(scalar < 103);
        valid = true;
      }

      assert(valid);
      cursor += 1;
      if (scalarCount == 63) {
        long closing = source[cursor];
        assert(closing == 34);
        cursor += 1;
      }

      scalarCount += 1;
    }

    return cursor;
  }

  /// Checks one canonical bootstrap profile byte.
  public boolean profileByte(long scalar, boolean allowPunctuation, boolean valid) {
    if (scalar == 45) {
      return allowPunctuation;
    }

    if (scalar == 46) {
      return allowPunctuation;
    }

    if (scalar == 95) {
      return allowPunctuation;
    }

    if (scalar < 48) {
      return false;
    }

    if (scalar < 58) {
      return true;
    }

    if (scalar < 65) {
      return false;
    }

    if (scalar < 91) {
      return true;
    }

    if (scalar < 97) {
      return false;
    }

    if (scalar < 123) {
      return true;
    }

    return valid;
  }
}
