//! Owns bounded source identities and resolved target columns for call assignments.

module wheeler.compiler.assignment_call_identities;

classical class AssignmentCallIdentities {
  /// Bounds call-assignment arguments by the scalar forwarding profile.
  public const long MAX_ASSIGNMENT_CALL_ARGUMENTS = 7;
  /// Names one packed prior-local source digit and one resolved target column width.
  public const long ASSIGNMENT_CALL_SOURCE_RADIX = 256;
  /// Names the resolved target count in each call-assignment column.
  public const long RESOLVED_ASSIGNMENT_CALL_TARGET_COUNT = 256;
  /// Existing signed local assigned from a zero-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_ZERO_NAMED = 926;
  /// Existing signed local assigned from a one-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_ONE_NAMED = 927;
  /// Existing signed local assigned from a two-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_TWO_NAMED = 928;
  /// Existing signed local assigned from a three-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_THREE_NAMED = 929;
  /// Existing signed local assigned from a four-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_FOUR_NAMED = 930;
  /// Existing signed local assigned from a five-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_FIVE_NAMED = 931;
  /// Existing signed local assigned from a six-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_SIX_NAMED = 932;
  /// Existing signed local assigned from a seven-argument helper call.
  public const long STATEMENT_ASSIGN_CALL_SEVEN_NAMED = 933;
  /// Resolved zero-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_ZERO_BASE = 40000;
  /// Resolved one-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_ONE_BASE = 40256;
  /// Resolved two-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_TWO_BASE = 40512;
  /// Resolved three-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_THREE_BASE = 40768;
  /// Resolved four-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_FOUR_BASE = 41024;
  /// Resolved five-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_FIVE_BASE = 41280;
  /// Resolved six-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_SIX_BASE = 41536;
  /// Resolved seven-argument call-assignment target column.
  public const long STATEMENT_ASSIGN_CALL_SEVEN_BASE = 41792;
  /// Ends all resolved call-assignment target columns.
  public const long ASSIGNMENT_CALL_END = 42048;
}
