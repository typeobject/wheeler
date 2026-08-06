//! Owns bounded source and resolved identities for borrowed intrinsic operations.

module wheeler.compiler.borrowed_intrinsic_kinds;

classical class BorrowedIntrinsicKinds {
  /// Bounds packed local sources for three-operand borrowed writes.
  public const long INTRINSIC_LOCAL_SOURCE_COUNT = 256;
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
  /// Names a mutable word-loan element write.
  public const long STATEMENT_SET_WORD_NAMED = 898;
  /// Names a resolved mutable word-loan element write.
  public const long STATEMENT_SET_WORD = 131077;
  /// Names a mutable byte-loan element write.
  public const long STATEMENT_SET_BYTE_NAMED = 899;
  /// Names a resolved mutable byte-loan element write.
  public const long STATEMENT_SET_BYTE = 131078;
  /// Names a mutable signed-map entry write.
  public const long STATEMENT_MAP_PUT_NAMED = 904;
  /// Names a resolved mutable signed-map entry write.
  public const long STATEMENT_MAP_PUT = 131338;
  /// Names a signed local initialized from a signed-map entry.
  public const long STATEMENT_LOCAL_MAP_GET_NAMED = 905;
  /// Names a resolved signed local initialized from a signed-map entry.
  public const long STATEMENT_LOCAL_MAP_GET = 131339;
  /// Names a Boolean local initialized from signed-map membership.
  public const long STATEMENT_LOCAL_MAP_HAS_NAMED = 906;
  /// Names a resolved Boolean local initialized from signed-map membership.
  public const long STATEMENT_LOCAL_MAP_HAS = 131340;
}
