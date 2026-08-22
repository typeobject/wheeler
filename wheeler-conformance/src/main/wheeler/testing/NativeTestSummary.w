//! Runs canonical test summary reduction as a conformance executable.

module wheeler.conformance.testing.native_test_summary;

import wheeler.runtime.testing.test_summary;

classical class NativeTestSummary {
  /// Reduces one complete bounded test outcome stream.
  ///
  /// - Effects: Publishes only after canonical ordering and complete validation.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = reduceTestSummary(input, output);
    setOutputLength(output, length);
  }
}
