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
  /// Names a 3-parameter signed-result helper.
  public const long HELPER_SIGNED_THREE = 35;
  /// Names a 3-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_THREE = 67;
  /// Names a 4-parameter signed-result helper.
  public const long HELPER_SIGNED_FOUR = 36;
  /// Names a 4-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_FOUR = 68;
  /// Names a 5-parameter signed-result helper.
  public const long HELPER_SIGNED_FIVE = 37;
  /// Names a 5-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_FIVE = 69;
  /// Names a 6-parameter signed-result helper.
  public const long HELPER_SIGNED_SIX = 38;
  /// Names a 6-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_SIX = 70;
  /// Names a 7-parameter signed-result helper.
  public const long HELPER_SIGNED_SEVEN = 39;
  /// Names a 7-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_SEVEN = 71;
  /// Names a 8-parameter signed-result helper.
  public const long HELPER_SIGNED_EIGHT = 40;
  /// Names a 8-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_EIGHT = 72;
  /// Names a 9-parameter signed-result helper.
  public const long HELPER_SIGNED_NINE = 41;
  /// Names a 9-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_NINE = 73;
  /// Names a 10-parameter signed-result helper.
  public const long HELPER_SIGNED_TEN = 42;
  /// Names a 10-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_TEN = 74;
  /// Names a 11-parameter signed-result helper.
  public const long HELPER_SIGNED_ELEVEN = 43;
  /// Names a 11-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_ELEVEN = 75;
  /// Names a 12-parameter signed-result helper.
  public const long HELPER_SIGNED_TWELVE = 44;
  /// Names a 12-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_TWELVE = 76;
  /// Names a 13-parameter signed-result helper.
  public const long HELPER_SIGNED_THIRTEEN = 45;
  /// Names a 13-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_THIRTEEN = 77;
  /// Names a 14-parameter signed-result helper.
  public const long HELPER_SIGNED_FOURTEEN = 46;
  /// Names a 14-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_FOURTEEN = 78;
  /// Names a 15-parameter signed-result helper.
  public const long HELPER_SIGNED_FIFTEEN = 47;
  /// Names a 15-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_FIFTEEN = 79;
  /// Names a 16-parameter signed-result helper.
  public const long HELPER_SIGNED_SIXTEEN = 48;
  /// Names a 16-signed-parameter Boolean-result helper.
  public const long HELPER_BOOLEAN_SIGNED_SIXTEEN = 80;
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
  public const long MAX_SCALAR_HELPER_PARAMETERS = 16;
  /// Names the exclusive end of accepted scalar helper parameter counts.
  public const long SCALAR_HELPER_PARAMETER_END = 17;
  /// Caps same-module calls in one bounded scalar helper body.
  public const long MAX_SCALAR_HELPER_CALLS = 64;
  /// Caps scalar helpers in one bounded entryless library.
  public const long MAX_SCALAR_HELPERS = 23;
  /// Caps helpers owned by one direct executable dependency.
  public const long MAX_IMPORTED_SCALAR_HELPERS = 22;
}
