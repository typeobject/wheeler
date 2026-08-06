//! Owns bounded source and resolved identities for borrowed intrinsic reads.

module wheeler.compiler.borrowed_intrinsic_kinds;

classical class BorrowedIntrinsicKinds {
  /// Names a signed return of an intrinsic borrowed-buffer length.
  public const long STATEMENT_RETURN_BUFFER_LENGTH_NAMED = 893;
  /// Names a local declaration initialized from an intrinsic borrowed-buffer length.
  public const long STATEMENT_LOCAL_BUFFER_LENGTH_NAMED = 894;
  /// Names a resolved signed return of one intrinsic borrowed-buffer length.
  public const long STATEMENT_RETURN_BUFFER_LENGTH = 131072;
  /// Names a resolved local initialized from one intrinsic borrowed-buffer length.
  public const long STATEMENT_LOCAL_BUFFER_LENGTH = 131073;
  /// Names a local declaration initialized from one borrowed UTF-8 scalar.
  public const long STATEMENT_LOCAL_UTF8_SCALAR_NAMED = 895;
  /// Names a resolved local initialized from one borrowed UTF-8 scalar.
  public const long STATEMENT_LOCAL_UTF8_SCALAR = 131074;
  /// Names a local declaration initialized from one borrowed buffer element.
  public const long STATEMENT_LOCAL_BUFFER_GET_NAMED = 896;
  /// Names a resolved local initialized from one borrowed buffer element.
  public const long STATEMENT_LOCAL_BUFFER_GET = 131075;
  /// Names a local declaration initialized from one borrowed UTF-8 width.
  public const long STATEMENT_LOCAL_UTF8_WIDTH_NAMED = 897;
  /// Names a resolved local initialized from one borrowed UTF-8 width.
  public const long STATEMENT_LOCAL_UTF8_WIDTH = 131076;
}
