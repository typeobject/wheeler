//! Runs the Wheeler-owned coverage reducer as a bounded conformance executable.

module wheeler.conformance.runtime.native_coverage_reducer;

import wheeler.runtime.coverage_reducer;

classical class NativeCoverageReducer {
  /// Reduces one complete bounded canonical fragment stream.
  ///
  /// - Effects: Publishes the output only after complete validation and reduction.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = reduce(input, output);
    setOutputLength(output, length);
  }
}
