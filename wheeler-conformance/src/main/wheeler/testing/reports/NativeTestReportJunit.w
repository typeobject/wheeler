//! Publishes the JUnit XML adapter for complete native profile-2 rows.

module wheeler.conformance.testing.reports.native_test_report_junit;

import wheeler.runtime.testing.test_report_junit;

classical class NativeTestReportJunit {
  /// Renders one validated native test-report transport.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = renderTestReportJunit(input, output);
    setOutputLength(output, length);
  }
}
