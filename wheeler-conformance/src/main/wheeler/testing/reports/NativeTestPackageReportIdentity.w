//! Publishes one native package test-report evidence identity.

module wheeler.conformance.testing.native_test_package_report_identity;

import wheeler.runtime.testing.test_package_report_identity;

classical class NativeTestPackageReportIdentity {
  /// Reduces target report identities into one validated package report identity.
  ///
  /// - Effects: Writes the runtime-owned identity and publishes its length.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveTestPackageReportIdentity(input, output);
    setOutputLength(output, length);
  }
}
