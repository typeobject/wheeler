//! Projects canonical package-manifest line and indentation coordinates.

module wheeler.compiler.packages.canonical_coordinates;

classical class PackageCanonicalCoordinates {
  private long lineCursor(long scalar, long cursor, long width, long end) {
    long next = cursor + width;
    if (scalar == 10) {
      return end;
    }

    return next;
  }

  private long projectedLineEnd(long scalar, long cursor, long current) {
    if (scalar == 10) {
      return cursor;
    }

    return current;
  }

  /// Returns the next newline coordinate or the source end.
  public long canonicalLineEnd(borrow utf8 source, long start) {
    long cursor = start;
    long end = bufferLength(source);
    long projected = end;
    while (cursor < end) limit 262144 {
      long scalar = utf8Scalar(source, cursor);
      long width = utf8Width(source, cursor);
      long nextCursor = lineCursor(scalar, cursor, width, end);
      long nextProjected = projectedLineEnd(scalar, cursor, projected);
      cursor = nextCursor;
      projected = nextProjected;
    }

    return projected;
  }

  private long indentStartState(long lineStart, long tokenStart, long expected) {
    long expectedStart = lineStart + expected;
    if (tokenStart == expectedStart) {
      return 1;
    }

    return 0;
  }

  private long indentState(long current, long scalar) {
    if (current == 0) {
      return 0;
    }

    if (scalar == 32) {
      return 1;
    }

    return 0;
  }

  private boolean validIndentState(long state) {
    if (state == 1) {
      return true;
    }

    return false;
  }

  /// Checks one exact zero-, two-, four-, or six-space indent.
  public boolean canonicalExactIndent(
    borrow utf8 source,
    long lineStart,
    long tokenStart,
    long expected
  ) {
    long state = indentStartState(lineStart, tokenStart, expected);
    long cursor = lineStart;
    while (cursor < tokenStart) limit 6 {
      long scalar = utf8Scalar(source, cursor);
      long nextState = indentState(state, scalar);
      state = nextState;
      cursor += 1;
    }

    return validIndentState(state);
  }
}
