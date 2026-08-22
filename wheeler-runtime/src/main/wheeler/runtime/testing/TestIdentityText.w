//! Encodes raw test identities as canonical lowercase hexadecimal text.

module wheeler.runtime.testing.test_identity_text;

classical class TestIdentityText {
  private long hexDigit(long value) {
    if (value < 10) {
      return value + 48;
    }

    return value + 87;
  }

  /// Writes one raw 32-byte identity at a caller-selected output cursor.
  public long writeTestIdentityTextAt(
    borrow byteview identity,
    borrow mut bytes output,
    long cursor
  ) {
    assert(bufferLength(identity) == 32);
    assert(-1 < cursor);
    assert(cursor < bufferLength(output) - 63);
    long offset = 0;
    while (offset < 32) limit 32 {
      long value = identity[offset];
      setByte(output, cursor + offset * 2, hexDigit(value / 16));
      setByte(output, cursor + offset * 2 + 1, hexDigit(value % 16));
      offset += 1;
    }

    return cursor + 64;
  }

  /// Writes one complete canonical 64-byte identity text value.
  public long writeTestIdentityText(borrow byteview identity, borrow mut bytes output) {
    assert(bufferLength(output) == 64);
    return writeTestIdentityTextAt(identity, output, /* cursor= */ 0);
  }
}
