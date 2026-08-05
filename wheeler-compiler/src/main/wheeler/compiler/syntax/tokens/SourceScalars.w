//! Owns the bounded ASCII digit and punctuation scalar identities.

module wheeler.compiler.source_scalars;

classical class SourceScalars {
  /// Names the ASCII scalar for the canonical digit `0`.
  public const long SCALAR_DIGIT_ZERO = 48;
  /// Names the ASCII scalar for the canonical digit `1`.
  public const long SCALAR_DIGIT_ONE = 49;
  /// Names the ASCII scalar for the canonical digit `9`.
  public const long SCALAR_DIGIT_NINE = 57;
  /// Names the ASCII `!` punctuation scalar.
  public const long PUNCTUATION_BANG = 33;
  /// Names the ASCII `%` punctuation scalar.
  public const long PUNCTUATION_PERCENT = 37;
  /// Names the ASCII `&` punctuation scalar.
  public const long PUNCTUATION_AMPERSAND = 38;
  /// Names the ASCII `(` punctuation scalar.
  public const long PUNCTUATION_OPEN_PAREN = 40;
  /// Names the ASCII `)` punctuation scalar.
  public const long PUNCTUATION_CLOSE_PAREN = 41;
  /// Names the ASCII `*` punctuation scalar.
  public const long PUNCTUATION_STAR = 42;
  /// Names the ASCII `+` punctuation scalar.
  public const long PUNCTUATION_PLUS = 43;
  /// Names the ASCII `,` punctuation scalar.
  public const long PUNCTUATION_COMMA = 44;
  /// Names the ASCII `-` punctuation scalar.
  public const long PUNCTUATION_MINUS = 45;
  /// Names the ASCII `.` punctuation scalar.
  public const long PUNCTUATION_DOT = 46;
  /// Names the ASCII `/` punctuation scalar.
  public const long PUNCTUATION_SLASH = 47;
  /// Names the ASCII `:` punctuation scalar.
  public const long PUNCTUATION_COLON = 58;
  /// Names the ASCII `;` punctuation scalar.
  public const long PUNCTUATION_SEMICOLON = 59;
  /// Names the ASCII `<` punctuation scalar.
  public const long PUNCTUATION_LESS_THAN = 60;
  /// Names the ASCII `=` punctuation scalar.
  public const long PUNCTUATION_ASSIGN = 61;
  /// Names the ASCII `^` punctuation scalar.
  public const long PUNCTUATION_CARET = 94;
  /// Names the ASCII `{` punctuation scalar.
  public const long PUNCTUATION_OPEN_BRACE = 123;
  /// Names the ASCII `}` punctuation scalar.
  public const long PUNCTUATION_CLOSE_BRACE = 125;
}
