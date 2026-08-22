//! Publishes one native package test-report evidence identity.

module wheeler.conformance.testing.native_test_package_report_identity;

import wheeler.runtime.testing.test_package_report_identity;

classical class NativeTestPackageReportIdentity {
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = deriveTestPackageReportIdentity(input, output);
    setOutputLength(output, length);
  }
}
