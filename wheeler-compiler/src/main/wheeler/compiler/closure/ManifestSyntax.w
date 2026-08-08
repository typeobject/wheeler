//! Owns strict bounded syntax checks for bootstrap closure metadata.

module wheeler.compiler.closure.manifest_syntax;

classical class ClosureManifestSyntax {
  /// Traps before publication when one metadata condition fails.
  public void requireMetadata(boolean condition, borrow byteview source) {
    if (condition == false) {
      long invalid = source[-1];
    }
  }

  /// Consumes one exact caller-prepared ASCII fragment.
  public long consumeMetadata(
    borrow byteview source,
    long cursor,
    borrow mut bytes expected,
    long length
  ) {
    requireMetadata(cursor + length < bufferLength(source) + 1, source);
    long index = 0;
    while (index < length) limit 2048 {
      requireMetadata(source[cursor + index] == expected[index], source);
      index += 1;
    }

    return cursor + length;
  }

  /// Consumes one quoted lowercase SHA-256 identity.
  public long consumeQuotedIdentity(
    borrow byteview source,
    long cursor,
    borrow mut bytes expected
  ) {
    requireMetadata(cursor + 66 < bufferLength(source) + 1, source);
    setByte(expected, 0, 34);
    boolean accepted = source[cursor] == expected[0];
    long index = 0;
    while (index < 64) limit 64 {
      long scalar = source[cursor + index + 1];
      boolean valid = 47 < scalar;
      if (57 < scalar) {
        valid = false;
      }

      if (96 < scalar) {
        valid = scalar < 103;
      }

      if (valid == false) {
        accepted = false;
      }

      index += 1;
    }

    if ((source[cursor + 65] == expected[0]) == false) {
      accepted = false;
    }

    requireMetadata(accepted, source);
    return cursor + 66;
  }

  /// Checks one canonical bootstrap profile byte.
  public boolean profileByte(long scalar, boolean first) {
    boolean valid = 47 < scalar;
    if (57 < scalar) {
      valid = false;
    }

    if (64 < scalar) {
      valid = scalar < 91;
    }

    if (96 < scalar) {
      valid = scalar < 123;
    }

    if (first == false) {
      if (scalar == 45) {
        valid = true;
      }

      if (scalar == 46) {
        valid = true;
      }

      if (scalar == 95) {
        valid = true;
      }
    }

    return valid;
  }
}
