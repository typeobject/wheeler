//! Resolves bounded primitive borrowed reads against typed local history.

module wheeler.compiler.borrowed_intrinsic_resolution;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.local_resolution;

classical class BorrowedIntrinsicResolution {
  /// Carries one resolved intrinsic opcode and whether this owner applies.
  public record ResolvedBorrowedIntrinsic(long opcode, boolean applies) {}

  /// Resolves one source intrinsic without consuming unrelated statements.
  public ResolvedBorrowedIntrinsic resolveBorrowedIntrinsic(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long sourceOpcode
  ) {
    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
      long bufferSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long bufferIndex = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      if (-1 < bufferSource) {
        if (-1 < bufferIndex) {
          return new ResolvedBorrowedIntrinsic(STATEMENT_LOCAL_BUFFER_GET, true);
        }
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

    boolean utf8IndexedRead = sourceOpcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED;
    if (sourceOpcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      utf8IndexedRead = true;
    }

    if (utf8IndexedRead) {
      long utf8Source = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      long scalarIndex = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 7,
        true
      );
      if (-1 < utf8Source) {
        if (-1 < scalarIndex) {
          long resolvedOpcode = STATEMENT_LOCAL_UTF8_SCALAR;
          if (sourceOpcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
            resolvedOpcode = STATEMENT_LOCAL_UTF8_WIDTH;
          }

          return new ResolvedBorrowedIntrinsic(resolvedOpcode, true);
        }
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      long localBufferSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      if (-1 < localBufferSource) {
        return new ResolvedBorrowedIntrinsic(STATEMENT_LOCAL_BUFFER_LENGTH, true);
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

    if (sourceOpcode == STATEMENT_RETURN_BUFFER_LENGTH_NAMED) {
      long returnBufferSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < returnBufferSource) {
        return new ResolvedBorrowedIntrinsic(STATEMENT_RETURN_BUFFER_LENGTH, true);
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

    return new ResolvedBorrowedIntrinsic(-1, false);
  }
}
