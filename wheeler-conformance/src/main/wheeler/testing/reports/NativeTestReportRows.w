//! Publishes canonical native profile-2 report rows.

module wheeler.conformance.testing.native_test_report_rows;

import wheeler.runtime.testing.test_report_rows;

classical class NativeTestReportRows {
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = reduceCanonicalReportRows(input, output);
    setOutputLength(output, length);
  }
}
