//! Runs one-case profile-2 test report identity derivation.

module wheeler.conformance.testing.native_test_report_identity;

import wheeler.runtime.testing.test_report_identity;

classical class NativeTestReportIdentity {
  /// Derives one complete semantic report identity.
  ///
  /// - Effects: Publishes only after validating and hashing the complete report.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveOneCaseReportIdentity(input, output);
    setOutputLength(output, length);
  }
}
