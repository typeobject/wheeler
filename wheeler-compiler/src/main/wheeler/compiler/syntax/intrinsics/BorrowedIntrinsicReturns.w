//! Owns bounded source and resolved identities for borrowed intrinsic returns.

module wheeler.compiler.borrowed_intrinsic_returns;

classical class BorrowedIntrinsicReturns {
  /// Names a signed return of an intrinsic borrowed-buffer length.
  public const long STATEMENT_RETURN_BUFFER_LENGTH_NAMED = 893;
  /// Names a local declaration initialized from an intrinsic borrowed-buffer length.
  public const long STATEMENT_LOCAL_BUFFER_LENGTH_NAMED = 894;
  /// Names a resolved signed return of one intrinsic borrowed-buffer length.
  public const long STATEMENT_RETURN_BUFFER_LENGTH = 131072;
  /// Names a resolved local initialized from one intrinsic borrowed-buffer length.
  public const long STATEMENT_LOCAL_BUFFER_LENGTH = 131073;
}
