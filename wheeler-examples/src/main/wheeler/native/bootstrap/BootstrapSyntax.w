//! Shares strict bounded bootstrap metadata checks without inventing a JSON framework.

module examples.bootstrap.syntax;

classical class BootstrapSyntax {
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
    while (index < length) limit 64 {
      requireMetadata(source[cursor + index] == expected[index], source);
      index += 1;
    }

    return cursor + length;
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
