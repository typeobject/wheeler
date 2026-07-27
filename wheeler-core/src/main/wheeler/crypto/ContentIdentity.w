//! Owns bounded binary metadata and publishes its content identity after validation.

module wheeler.crypto.content_identity;

import wheeler.crypto.sha256;

classical class ContentIdentities {
  /// Copies bounded binary metadata into one strict immutable UTF-8 owner.
  public utf8 freezeBoundedUtf8(
    borrow byteview source,
    long maximumLength,
    borrow mut region arena
  ) {
    if (maximumLength < 0) {
      long negativeLimit = source[-1];
    }

    if (4096 < maximumLength) {
      long unsupportedLimit = source[-1];
    }

    if (maximumLength < bufferLength(source)) {
      long oversized = source[-1];
    }

    bytes owned = allocateBytes(arena, bufferLength(source));
    long cursor = 0;
    while (cursor < bufferLength(source)) limit 4096 {
      setByte(owned, cursor, source[cursor]);
      cursor += 1;
    }

    return freezeUtf8(owned);
  }

  /// Computes and publishes all 32 digest bytes into caller-owned output.
  public void publishSha256(
    borrow byteview source,
    borrow mut bytes output,
    borrow mut region arena
  ) {
    publishSha256Range(source, 0, bufferLength(source), output, arena);
  }

  /// Computes and publishes SHA-256 over one checked input range.
  public void publishSha256Range(
    borrow byteview source,
    long start,
    long length,
    borrow mut bytes output,
    borrow mut region arena
  ) {
    if (bufferLength(output) < 32) {
      long undersized = output[-1];
    }

    bytes digest = allocateBytes(arena, 32);
    hashSha256Range(source, start, length, digest, arena);
    long cursor = 0;
    while (cursor < 32) limit 32 {
      setByte(output, cursor, digest[cursor]);
      cursor += 1;
    }

    drop(digest);
  }
}
