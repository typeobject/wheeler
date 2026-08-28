//! Defines resolved forwarding helper-return statement identities.

module wheeler.compiler.forwarded_helper_result_statements;

classical class ForwardedHelperResultStatements {
  /// Starts forwarding returns over one resolved source local.
  public const long STATEMENT_RETURN_HELPER_CALL_BASE = 27648;
  /// Names one forwarding return without arguments.
  public const long STATEMENT_RETURN_HELPER_CALL_ZERO = 27904;
  /// Starts forwarding returns over two resolved source locals.
  public const long STATEMENT_RETURN_HELPER_CALL_TWO_BASE = 65536;
  /// Starts forwarding returns over three resolved source locals.
  public const long STATEMENT_RETURN_HELPER_CALL_THREE_BASE = 16777216;
  /// Starts forwarding returns over four resolved source locals.
  public const long STATEMENT_RETURN_HELPER_CALL_FOUR_BASE = 33554432;
  /// Names one forwarding return over five source locals.
  public const long STATEMENT_RETURN_HELPER_CALL_FIVE = 29440;
  /// Names one forwarding return over six source locals.
  public const long STATEMENT_RETURN_HELPER_CALL_SIX = 29696;
  /// Names one forwarding return over seven source locals.
  public const long STATEMENT_RETURN_HELPER_CALL_SEVEN = 29952;
}
