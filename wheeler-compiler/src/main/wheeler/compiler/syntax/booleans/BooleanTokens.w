//! Classifies admitted Boolean literal word codes.

module wheeler.compiler.boolean_tokens;

classical class BooleanTokens {
  /// Names the source-word code for `true`.
  public const long TOKEN_TRUE = 3569038;
  /// Names the source-word code for `false`.
  public const long TOKEN_FALSE = 97196323;

  /// Checks the closed pair of Boolean literal word codes.
  public boolean booleanTokenCode(long wordCode) {
    if (wordCode == TOKEN_TRUE) {
      return true;
    }

    return wordCode == TOKEN_FALSE;
  }
}
