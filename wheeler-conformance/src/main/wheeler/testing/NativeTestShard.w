//! Runs deterministic test-case shard assignment as a conformance executable.

module wheeler.conformance.testing.native_test_shard;

import wheeler.runtime.testing.test_shard;

classical class NativeTestShard {
  /// Publishes one byte: one when the identity belongs to the requested shard.
  ///
  /// - Effects: Publishes only after validating the complete identity and shard range.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(output) == 1);
    if (assignedToShard(input)) {
      setByte(output, 0, 1);
    } else {
      setByte(output, 0, 0);
    }

    setOutputLength(output, 1);
  }
}
