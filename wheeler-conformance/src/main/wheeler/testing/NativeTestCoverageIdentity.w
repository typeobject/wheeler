//! Publishes one runtime-owned profile-2 coverage identity.

module wheeler.conformance.testing.native_test_coverage_identity;

import wheeler.runtime.testing.test_coverage_identity;

classical class NativeTestCoverageIdentity {
  /// Derives the coverage identity from the validated profile-2 transport.
  ///
  /// - Effects: Writes the runtime-owned identity and publishes its length.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveTestCoverageIdentity(input, output);
    setOutputLength(output, length);
  }
}
