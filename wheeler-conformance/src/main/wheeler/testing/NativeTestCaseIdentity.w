//! Runs canonical test-case identity derivation as a conformance executable.

module wheeler.conformance.testing.native_test_case_identity;

import wheeler.runtime.testing.test_case_identity;

classical class NativeTestCaseIdentity {
  /// Derives one complete profile-2 test-case identity.
  ///
  /// - Effects: Publishes only after complete frame validation and hashing.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveTestCaseIdentity(input, output);
    setOutputLength(output, length);
  }
}
