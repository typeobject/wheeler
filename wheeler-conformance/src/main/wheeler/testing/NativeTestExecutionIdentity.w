//! Publishes one runtime-owned profile-2 test execution identity.

module wheeler.conformance.testing.native_test_execution_identity;

import wheeler.runtime.testing.test_execution_identity;

classical class NativeTestExecutionIdentity {
  /// Derives the execution identity from the validated profile-2 transport.
  ///
  /// - Effects: Writes the runtime-owned identity and publishes its length.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveTestExecutionIdentity(input, output);
    setOutputLength(output, length);
  }
}
