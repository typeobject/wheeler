//! Owns and classifies the closed Boolean literal token vocabulary.

module wheeler.compiler.boolean_tokens;

classical class BooleanTokens {
  /// Names the stable token hash for `true`.
  public const long TOKEN_TRUE = 3569038;
  /// Names the stable token hash for `false`.
  public const long TOKEN_FALSE = 97196323;

  /// Checks the closed pair of Boolean literal token hashes.
  public boolean booleanTokenHash(long hash) {
    if (hash == TOKEN_TRUE) {
      return true;
    }

    return hash == TOKEN_FALSE;
  }
}
