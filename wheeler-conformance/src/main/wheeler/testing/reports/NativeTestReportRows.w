//! Publishes canonical native profile-2 report rows.

module wheeler.conformance.testing.native_test_report_rows;

import wheeler.runtime.testing.test_report_rows;

classical class NativeTestReportRows {
  /// Validates and sorts the transported case rows into one profile-2 report.
  ///
  /// - Effects: Writes the canonical report rows and publishes their extent.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = reduceCanonicalReportRows(input, output);
    setOutputLength(output, length);
  }
}
