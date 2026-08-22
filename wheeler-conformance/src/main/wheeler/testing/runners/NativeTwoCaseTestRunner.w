//! Publishes the canonical runtime two-case test product.

module wheeler.conformance.testing.runners.native_two_case_test_runner;

import wheeler.runtime.testing.runners.two_case_test_runner;

classical class NativeTwoCaseTestRunner {
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = runTwoCaseTests(input, output);
    setOutputLength(output, length);
  }
}
