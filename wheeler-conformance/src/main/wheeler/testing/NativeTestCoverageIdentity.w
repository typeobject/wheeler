//! Publishes one runtime-owned profile-2 coverage identity.

module wheeler.conformance.testing.native_test_coverage_identity;

import wheeler.runtime.testing.test_coverage_identity;

classical class NativeTestCoverageIdentity {
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveTestCoverageIdentity(input, output);
    setOutputLength(output, length);
  }
}
