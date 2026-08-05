//! Owns bounded helper kinds, table capacity, and reversible result-slot widths.

module wheeler.compiler.helper_abi;

classical class HelperAbi {
  /// Names an ordinary void helper.
  public const long HELPER_VOID = 0;
  /// Names a reversible void helper.
  public const long HELPER_REVERSIBLE = 1;
  /// Names a zero-argument signed-result helper.
  public const long HELPER_SIGNED = 2;
  /// Names a one-parameter signed-result helper.
  public const long HELPER_SIGNED_ONE = 3;
  /// Names a two-parameter signed-result helper.
  public const long HELPER_SIGNED_TWO = 4;
  /// Names a zero-argument Boolean-result helper.
  public const long HELPER_BOOLEAN = 5;
  /// Names a one-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_ONE = 6;
  /// Names a two-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_TWO = 7;
  /// Names a one-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_ONE = 8;
  /// Names a two-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_TWO = 9;
  /// Names a zero-argument reversible signed result-slot helper.
  public const long HELPER_REVERSIBLE_SIGNED = 10;
  /// Names a one-parameter reversible signed result-slot helper.
  public const long HELPER_REVERSIBLE_SIGNED_ONE = 11;
  /// Names a two-parameter reversible signed result-slot helper.
  public const long HELPER_REVERSIBLE_SIGNED_TWO = 12;
  /// Names the canonical reversible signed-result function flags.
  public const long RESULT_SLOT_FUNCTION_FLAGS = 13;
  /// Names the adjacent result-slot tag and payload locals.
  public const long RESULT_SLOT_LOCAL_COUNT = 2;
  /// Names the bounded resolver's logical result local before slot expansion.
  public const long RESULT_SLOT_LOGICAL_RESULT_LOCAL = 1;
  /// Names one direct fill-and-return result-slot body width.
  public const long RESULT_SLOT_BODY_LENGTH = 40;
  /// Names one binary fill-and-return result-slot body width.
  public const long RESULT_SLOT_BINARY_BODY_LENGTH = 56;
  /// Caps scalar helpers in one bounded entryless library.
  public const long MAX_SCALAR_HELPERS = 9;
}
