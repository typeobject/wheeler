//! Owns the bounded native test-case and report transport profile.

module wheeler.runtime.testing.test_limits;

classical class TestLimits {
  /// Caps complete native cases in one target or package report.
  public const long MAX_TEST_CASES = 255;
  /// Caps one complete profile-2 case row.
  public const long MAX_TEST_CASE_RESULT_BYTES = 5345;
  /// Caps concatenated complete profile-2 case rows.
  public const long MAX_TEST_REPORT_ROWS_BYTES = 1362975;
  /// Caps a published identity, summary, row length, and complete rows.
  public const long MAX_TEST_REPORT_PUBLICATION_BYTES = 1363018;
  /// Caps raw case identities before summary reduction.
  public const long MAX_TEST_SUMMARY_ROWS_BYTES = 8160;
}
