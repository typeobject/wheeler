//! Publishes one canonical runtime test product.

module wheeler.conformance.testing.runners.native_test_runner;

import wheeler.runtime.testing.runners.test_runner;

classical class NativeTestRunner {
  /// Runs the validated test transport through the runtime-owned runner.
  ///
  /// - Effects: Writes the selected test product and publishes its length.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = runTests(input, output);
    setOutputLength(output, length);
  }
}
