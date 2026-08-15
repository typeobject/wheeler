//! Owns reversible source-token coordinate advancement.

module wheeler.compiler.closure.reversible_token_coordinates;

classical class ReversibleTokenCoordinates {
  /// Returns the token immediately after one source coordinate.
  ///
  /// - Inverse: Reconstructs the exact input coordinate from the result relation.
  public rev long nextSourceToken(long token) {
    return token + 1;
  }

  /// Checks the generated inverse for `nextSourceToken`.
  theorem nextSourceTokenInverse proves inverse(nextSourceToken);
}
