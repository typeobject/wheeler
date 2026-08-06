//! Owns the bounded source keyword token identities.

module wheeler.compiler.keyword_tokens;

classical class KeywordTokens {
  /// Names the stable token hash for `module`.
  public const long TOKEN_MODULE = 3226183276;
  /// Names the stable token hash for `import`.
  public const long TOKEN_IMPORT = 3110171557;
  /// Names the stable token hash for `public`.
  public const long TOKEN_PUBLIC = 3317543529;
  /// Names the stable token hash for `private`.
  public const long TOKEN_PRIVATE = 102764717443;
  /// Names the stable token hash for `classical`.
  public const long TOKEN_CLASSICAL = 87497064671293;
  /// Names the stable token hash for `class`.
  public const long TOKEN_CLASS = 94742904;
  /// Names the stable token hash for `state`.
  public const long TOKEN_STATE = 109757585;
  /// Names the stable token hash for `entry`.
  public const long TOKEN_ENTRY = 96667762;
  /// Names the stable token hash for `void`.
  public const long TOKEN_VOID = 3625364;
  /// Names the stable token hash for `main`.
  public const long TOKEN_MAIN = 3343801;
  /// Names the stable token hash for `rev`.
  public const long TOKEN_REV = 112803;
  /// Names the stable token hash for `reverse`.
  public const long TOKEN_REVERSE = 104179061474;
  /// Names the stable token hash for `theorem`.
  public const long TOKEN_THEOREM = 106024553916;
  /// Names the stable token hash for `proves`.
  public const long TOKEN_PROVES = 3315169751;
  /// Names the stable token hash for `inverse`.
  public const long TOKEN_INVERSE = 96449190704;
  /// Names the stable token hash for `assert`.
  public const long TOKEN_ASSERT = 2886759238;
  /// Names the stable token hash for `if`.
  public const long TOKEN_IF = 3357;
  /// Names the stable token hash for `while`.
  public const long TOKEN_WHILE = 113101617;
  /// Names the stable token hash for `limit`.
  public const long TOKEN_LIMIT = 102976443;
  /// Names the stable token hash for `long`.
  public const long TOKEN_LONG = 3327612;
  /// Names the stable token hash for `borrow`.
  public const long TOKEN_BORROW = 2911676917;
  /// Names the stable token hash for `mut`.
  public const long TOKEN_MUT = 108492;
  /// Names the stable token hash for `utf8`.
  public const long TOKEN_UTF8 = 3600241;
  /// Names the stable token hash for `bytes`.
  public const long TOKEN_BYTES = 94224491;
  /// Names the stable token hash for `byteview`.
  public const long TOKEN_BYTEVIEW = 2807042004909;
  /// Names the stable token hash for `words`.
  public const long TOKEN_WORDS = 113318569;
  /// Names the stable token hash for `region`.
  public const long TOKEN_REGION = 3360171764;
  /// Names the stable token hash for `longmap`.
  public const long TOKEN_LONGMAP = 99132996960;
  /// Names the stable token hash for `boolean`.
  public const long TOKEN_BOOLEAN = 90259024936;
  /// Names the stable token hash for intrinsic `bufferLength`.
  public const long TOKEN_BUFFER_LENGTH = 2588713963992550214;
  /// Names the stable token hash for intrinsic `utf8Scalar`.
  public const long TOKEN_UTF8_SCALAR = 3195229610631869;
  /// Names the stable token hash for intrinsic `utf8Width`.
  public const long TOKEN_UTF8_WIDTH = 103071926799573;
  /// Names the stable token hash for intrinsic `set`.
  public const long TOKEN_SET = 113762;
  /// Names the stable token hash for intrinsic `setByte`.
  public const long TOKEN_SET_BYTE = 105063682186;
  /// Names the stable token hash for `return`.
  public const long TOKEN_RETURN = 3360570672;
}
