//! Derives one profile-2 test-case identity without host code.

module wheeler.conformance.testing.native_test_case_identity;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;

classical class NativeTestCaseIdentity {
  private const long DIGEST_TEXT_BYTES = 64;
  private const long DOMAIN_BYTES = 19;
  private const long FIELD_PREFIX_BYTES = 8;
  private const long FIXED_INPUT_BYTES = 130;
  private const long MAX_CASE_NAME_BYTES = 255;
  private const long MESSAGE_BYTES = 434;
  private const long OUTPUT_BYTES = 32;
  private const long STAGING_BYTES = 1522;

  private long hexNibble(long value) {
    if (47 < value) {
      if (value < 58) {
        return value - 48;
      }
    }

    if (96 < value) {
      if (value < 103) {
        return value - 87;
      }
    }

    return -1;
  }

  private void validateIdentity(borrow byteview input, long start) {
    long offset = 0;
    while (offset < DIGEST_TEXT_BYTES) limit DIGEST_TEXT_BYTES {
      assert(-1 < hexNibble(input[start + offset]));
      offset += 1;
    }
  }

  private long writeLength(long length, borrow mut bytes output, long cursor) {
    long prefix = 0;
    while (prefix < FIELD_PREFIX_BYTES - 1) limit FIELD_PREFIX_BYTES {
      setByte(output, cursor + prefix, 0);
      prefix += 1;
    }

    setByte(output, cursor + FIELD_PREFIX_BYTES - 1, length);
    return cursor + FIELD_PREFIX_BYTES;
  }

  private long writeRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    long offset = 0;
    while (offset < length) limit MAX_CASE_NAME_BYTES {
      setByte(output, cursor + offset, input[start + offset]);
      offset += 1;
    }

    return cursor + length;
  }

  /// Publishes the raw SHA-256 case identity after complete frame validation.
  ///
  /// - Effects: Publishes only after validating both identities and the case name.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(FIXED_INPUT_BYTES < bufferLength(input));
    assert(bufferLength(output) == OUTPUT_BYTES);
    long nameLength = readUnsigned(input, DIGEST_TEXT_BYTES * 2, /* width= */ 2);
    assert(0 < nameLength);
    assert(nameLength < MAX_CASE_NAME_BYTES + 1);
    assert(bufferLength(input) == FIXED_INPUT_BYTES + nameLength);
    validateIdentity(input, /* start= */ 0);
    validateIdentity(input, /* start= */ DIGEST_TEXT_BYTES);

    long messageLength = 179 + nameLength;
    region arena = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 4);
    bytes message = allocateBytes(arena, MESSAGE_BYTES);
    long cursor = writeLength(DOMAIN_BYTES, message, /* cursor= */ 0);
    writeAscii(message, cursor, "wheeler.test-case/1");
    cursor += DOMAIN_BYTES;
    cursor = writeLength(DIGEST_TEXT_BYTES, message, cursor);
    cursor = writeRange(input, /* start= */ 0, DIGEST_TEXT_BYTES, message, cursor);
    cursor = writeLength(nameLength, message, cursor);
    cursor = writeRange(input, FIXED_INPUT_BYTES, nameLength, message, cursor);
    cursor = writeLength(DIGEST_TEXT_BYTES, message, cursor);
    cursor = writeRange(input, DIGEST_TEXT_BYTES, DIGEST_TEXT_BYTES, message, cursor);
    assert(cursor == messageLength);
    hashSha256Range(message, /* inputStart= */ 0, messageLength, output, arena);
    setOutputLength(output, OUTPUT_BYTES);
    drop(message);
    drop(arena);
  }
}
