//! Projects canonical package-manifest token-window state.

module wheeler.compiler.packages.canonical_token_state;

classical class PackageCanonicalTokenState {
  /// Advances a token coordinate while its start precedes the line end.
  public long canonicalProjectedToken(boolean beforeEnd, long token, long next) {
    if (beforeEnd == true) {
      return next;
    }

    return token;
  }

  /// Closes the scan limit at the first token outside the line.
  public long canonicalProjectedTokenLimit(boolean beforeEnd, long token, long limit) {
    if (beforeEnd == true) {
      return limit;
    }

    return token;
  }
}
