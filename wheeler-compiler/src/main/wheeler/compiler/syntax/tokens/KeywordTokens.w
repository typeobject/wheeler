//! Owns shared source-word codes, not hash-based lexical admission.

module wheeler.compiler.keyword_tokens;

classical class KeywordTokens {
  /// Names the source-word code for `module`.
  public const long TOKEN_MODULE = 3226183276;
  /// Names the source-word code for `import`.
  public const long TOKEN_IMPORT = 3110171557;
  /// Names the source-word code for `public`.
  public const long TOKEN_PUBLIC = 3317543529;
  /// Names the source-word code for `private`.
  public const long TOKEN_PRIVATE = 102764717443;
  /// Names the source-word code for `classical`.
  public const long TOKEN_CLASSICAL = 87497064671293;
  /// Names the source-word code for `class`.
  public const long TOKEN_CLASS = 94742904;
  /// Names the source-word code for `state`.
  public const long TOKEN_STATE = 109757585;
  /// Names the source-word code for `entry`.
  public const long TOKEN_ENTRY = 96667762;
  /// Names the source-word code for `void`.
  public const long TOKEN_VOID = 3625364;
  /// Names the source-word code for `main`.
  public const long TOKEN_MAIN = 3343801;
  /// Names the source-word code for `rev`.
  public const long TOKEN_REV = 112803;
  /// Names the source-word code for `reverse`.
  public const long TOKEN_REVERSE = 104179061474;
  /// Names the source-word code for `theorem`.
  public const long TOKEN_THEOREM = 106024553916;
  /// Names the source-word code for `proves`.
  public const long TOKEN_PROVES = 3315169751;
  /// Names the source-word code for `inverse`.
  public const long TOKEN_INVERSE = 96449190704;
  /// Names the source-word code for `assert`.
  public const long TOKEN_ASSERT = 2886759238;
  /// Names the source-word code for `if`.
  public const long TOKEN_IF = 3357;
  /// Names the source-word code for `while`.
  public const long TOKEN_WHILE = 113101617;
  /// Names the source-word code for `limit`.
  public const long TOKEN_LIMIT = 102976443;
  /// Names the source-word code for `long`.
  public const long TOKEN_LONG = 3327612;
  /// Names the source-word code for `borrow`.
  public const long TOKEN_BORROW = 2911676917;
  /// Names the source-word code for `mut`.
  public const long TOKEN_MUT = 108492;
  /// Names the source-word code for `utf8`.
  public const long TOKEN_UTF8 = 3600241;
  /// Names the source-word code for `bytes`.
  public const long TOKEN_BYTES = 94224491;
  /// Names the source-word code for intrinsic `allocateBytes`.
  public const long TOKEN_ALLOCATE_BYTES = 7757814110573215534;
  /// Names the source-word code for `drop`.
  public const long TOKEN_DROP = 3092207;
  /// Names the source-word code for intrinsic `freezeUtf8`.
  public const long TOKEN_FREEZE_UTF8 = 2796943039232680;
  /// Names the source-word code for `byteview`.
  public const long TOKEN_BYTEVIEW = 2807042004909;
  /// Names the source-word code for `words`.
  public const long TOKEN_WORDS = 113318569;
  /// Names the source-word code for `region`.
  public const long TOKEN_REGION = 3360171764;
  /// Names the source-word code for `longmap`.
  public const long TOKEN_LONGMAP = 99132996960;
  /// Names the source-word code for `boolean`.
  public const long TOKEN_BOOLEAN = 90259024936;
  /// Names the source-word code for intrinsic `bufferLength`.
  public const long TOKEN_BUFFER_LENGTH = 2588713963992550214;
  /// Names the source-word code for intrinsic `utf8Scalar`.
  public const long TOKEN_UTF8_SCALAR = 3195229610631869;
  /// Names the source-word code for intrinsic `utf8Width`.
  public const long TOKEN_UTF8_WIDTH = 103071926799573;
  /// Names the source-word code for intrinsic `set`.
  public const long TOKEN_SET = 113762;
  /// Names the source-word code for intrinsic `setByte`.
  public const long TOKEN_SET_BYTE = 105063682186;
  /// Names the source-word code for intrinsic `put`.
  public const long TOKEN_PUT = 111375;
  /// Names the source-word code for intrinsic `mapGet`.
  public const long TOKEN_MAP_GET = 3213567066;
  /// Names the source-word code for intrinsic `mapHas`.
  public const long TOKEN_MAP_HAS = 3213567902;
  /// Names the source-word code for `return`.
  public const long TOKEN_RETURN = 3360570672;
  /// Names the source-word code for `const`.
  public const long TOKEN_CONST = 94844771;
  /// Names the source-word code for `coherent`.
  public const long TOKEN_COHERENT = 2825335909666;
  /// Names the source-word code for `test`.
  public const long TOKEN_TEST = 3556498;
  /// Names the source-word code for `new`.
  public const long TOKEN_NEW = 108960;
  /// Names the source-word code for `record`.
  public const long TOKEN_RECORD = 3360058449;
  /// Names the source-word code for `case`.
  public const long TOKEN_CASE = 3046192;
  /// Names the source-word code for `variant`.
  public const long TOKEN_VARIANT = 107610968197;
  /// Names the source-word code for `slice`.
  public const long TOKEN_SLICE = 109526418;
  /// Names the source-word code for `Done`.
  public const long TOKEN_DONE = 2135970;
  /// Names the source-word code for `cases`.
  public const long TOKEN_CASES = 94432067;
  /// Names the source-word code for `history`.
  public const long TOKEN_HISTORY = 95416214676;
  /// Names the source-word code for `limits`.
  public const long TOKEN_LIMITS = 3192269848;
  /// Names the source-word code for `steps`.
  public const long TOKEN_STEPS = 109761319;
  /// Names the source-word code for `tags`.
  public const long TOKEN_TAGS = 3552281;
  /// Names the source-word code for `rotateRight32`.
  public const long TOKEN_ROTATE_RIGHT_32 = 3360224995018391456;
  /// Names the source-word code for `enum`.
  public const long TOKEN_ENUM = 3118337;
  /// Names the source-word code for `qreg`.
  public const long TOKEN_QREG = 3479171;
  /// Names the source-word code for `static`.
  public const long TOKEN_STATIC = 3402485358;
  /// Names the source-word code for `unitary`.
  public const long TOKEN_UNITARY = 107087659620;
  /// Names the source-word code for `dynamic`.
  public const long TOKEN_DYNAMIC = 92319080511;
  /// Names the source-word code for `protected`.
  public const long TOKEN_PROTECTED = 98762164431790;
  /// Names the source-word code for `Slot`.
  public const long TOKEN_SLOT = 2579998;
  /// Names the source-word code for `adjoint`.
  public const long TOKEN_ADJOINT = 89052076615;
  /// Names the source-word code for `equivalent`.
  public const long TOKEN_EQUIVALENT = 2770094160335466;
  /// Names the source-word code for `done`.
  public const long TOKEN_DONE_VALUE = 3089282;
  /// Names the source-word code for `nil`.
  public const long TOKEN_NIL = 109073;
  /// Names the source-word code for `none`.
  public const long TOKEN_NONE = 3387192;
  /// Names the source-word code for `null`.
  public const long TOKEN_NULL = 3392903;
  /// Names the source-word code for `undefined`.
  public const long TOKEN_UNDEFINED = 102906378281296;
}
