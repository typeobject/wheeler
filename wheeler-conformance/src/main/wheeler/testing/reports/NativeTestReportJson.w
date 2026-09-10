//! Publishes the canonical JSON adapter for complete native profile-2 rows.

module wheeler.conformance.testing.reports.native_test_report_json;

import wheeler.runtime.testing.test_report_json;

classical class NativeTestReportJson {
  /// Renders one validated native test-report transport.
  ///
  /// - Effects: Writes canonical JSON bytes and publishes their length.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = renderTestReportJson(input, output);
    setOutputLength(output, length);
  }
}
