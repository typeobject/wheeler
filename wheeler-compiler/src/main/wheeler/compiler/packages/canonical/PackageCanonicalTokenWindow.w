//! Projects one canonical package-manifest line token window.

module wheeler.compiler.packages.canonical_token_window;

import wheeler.compiler.packages.canonical_token_state;

classical class PackageCanonicalTokenWindow {
  private long rowStart(borrow mut words starts, long token) {
    long start = starts[token];
    return start;
  }

  /// Returns the first token at or after the line end.
  public long canonicalLineTokenEnd(
    borrow mut words starts,
    long token,
    long count,
    long lineEnd
  ) {
    long cursor = token;
    long limit = count;
    while (cursor < limit) limit 262144 {
      long start = rowStart(starts, cursor);
      long next = cursor;
      next += 1;
      boolean beforeEnd = start < lineEnd;
      long nextCursor = canonicalProjectedToken(beforeEnd, cursor, next);
      long nextLimit = canonicalProjectedTokenLimit(beforeEnd, cursor, limit);
      cursor = nextCursor;
      limit = nextLimit;
    }

    return cursor;
  }
}
