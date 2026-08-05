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
  /// Names a three-parameter signed-result helper.
  public const long HELPER_SIGNED_THREE = 13;
  /// Names a three-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_THREE = 14;
  /// Names a four-parameter signed-result helper.
  public const long HELPER_SIGNED_FOUR = 15;
  /// Names a four-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_FOUR = 16;
  /// Names a five-parameter signed-result helper.
  public const long HELPER_SIGNED_FIVE = 17;
  /// Names a five-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_FIVE = 18;
  /// Names a six-parameter signed-result helper.
  public const long HELPER_SIGNED_SIX = 19;
  /// Names a six-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_SIX = 20;
  /// Names a seven-parameter signed-result helper.
  public const long HELPER_SIGNED_SEVEN = 21;
  /// Names a seven-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_SEVEN = 22;
  /// Names an eight-parameter signed-result helper.
  public const long HELPER_SIGNED_EIGHT = 23;
  /// Names an eight-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_EIGHT = 24;
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
  /// Caps signed scalar parameters in one bounded helper.
  public const long MAX_SCALAR_HELPER_PARAMETERS = 8;
  /// Caps scalar helpers in one bounded entryless library.
  public const long MAX_SCALAR_HELPERS = 23;
  /// Caps helpers owned by one direct executable dependency.
  public const long MAX_IMPORTED_SCALAR_HELPERS = 22;
}
