//! Assigns one canonical test-case identity to a deterministic shard.

module wheeler.conformance.testing.native_test_shard;

import wheeler.core.encoding.binary;

classical class NativeTestShard {
  private const long IDENTITY_BYTES = 64;
  private const long INPUT_BYTES = 68;
  private const long MAX_SHARDS = 65535;

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

  /// Publishes one byte: one when the identity belongs to the requested shard.
  ///
  /// - Effects: Publishes only after validating the complete identity and shard range.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(input) == INPUT_BYTES);
    assert(bufferLength(output) == 1);
    long shardIndex = readUnsigned(input, IDENTITY_BYTES, /* width= */ 2);
    long shardCount = readUnsigned(input, IDENTITY_BYTES + 2, /* width= */ 2);
    assert(0 < shardCount);
    assert(shardCount < MAX_SHARDS + 1);
    assert(-1 < shardIndex);
    assert(shardIndex < shardCount);

    long remainder = 0;
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long high = hexNibble(input[offset]);
      long low = hexNibble(input[offset + 1]);
      assert(-1 < high);
      assert(-1 < low);
      remainder = (remainder * 256 + high * 16 + low) % shardCount;
      offset += 2;
    }

    if (remainder == shardIndex) {
      setByte(output, 0, 1);
    } else {
      setByte(output, 0, 0);
    }

    setOutputLength(output, 1);
  }
}
