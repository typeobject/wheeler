//! Publishes the terminal adapter for complete native profile-2 rows.

module wheeler.conformance.testing.reports.native_test_report_terminal;

import wheeler.runtime.testing.test_report_terminal;

classical class NativeTestReportTerminal {
  /// Renders one validated native test-report transport.
  entry void main(borrow byteview input, borrow mut bytes output) {
    long length = renderTestReportTerminal(input, output);
    setOutputLength(output, length);
  }
}
