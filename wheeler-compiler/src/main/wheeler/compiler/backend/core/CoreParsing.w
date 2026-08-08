//! Scans and parses one bounded compiler source into its minimal program IR.

module wheeler.compiler.core_parsing;

import wheeler.compiler.compiler_token_limits;

classical class CoreParsing {
  /// Removes comments and documentation from one mutable token prefix.
  public long compactCompilerTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long readCursor = 0;
    long writeCursor = 0;
    while (readCursor < count) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readCursor];
      boolean emit = true;
      if (kind == 4) {
        emit = false;
      }

      if (kind == 5) {
        emit = false;
      }

      if (emit) {
        set(tokenKinds, writeCursor, kind);
        set(tokenStarts, writeCursor, tokenStarts[readCursor]);
        set(tokenLengths, writeCursor, tokenLengths[readCursor]);
        writeCursor += 1;
      }

      readCursor += 1;
    }

    return writeCursor;
  }

  /// Moves the class-body token suffix to the front of each mutable column.
  public long discardLeadingTokens(
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long bodyStart,
    long count
  ) {
    long readCursor = bodyStart;
    long writeCursor = 0;
    while (readCursor < count) limit MAX_COMPILER_TOKENS {
      set(tokenKinds, writeCursor, tokenKinds[readCursor]);
      set(tokenStarts, writeCursor, tokenStarts[readCursor]);
      set(tokenLengths, writeCursor, tokenLengths[readCursor]);
      readCursor += 1;
      writeCursor += 1;
    }

    return writeCursor;
  }

}
