//! Resolves bounded primitive borrowed operations against typed local history.

module wheeler.compiler.borrowed_intrinsic_resolution;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.local_resolution;

classical class BorrowedIntrinsicResolution {
  /// Carries one resolved intrinsic opcode and whether this owner applies.
  public record ResolvedBorrowedIntrinsic(long opcode, boolean applies) {}

  /// Carries one primary source local and whether this owner applies.
  public record BorrowedIntrinsicOperand(long value, boolean applies) {}

  private long borrowedPrimaryTokenOffset(long sourceOpcode) {
    boolean mutation = sourceOpcode == STATEMENT_SET_WORD_NAMED;
    if (sourceOpcode == STATEMENT_SET_BYTE_NAMED) {
      mutation = true;
    }

    if (sourceOpcode == STATEMENT_MAP_PUT_NAMED) {
      mutation = true;
    }

    if (mutation) {
      return 2;
    }

    if (sourceOpcode == STATEMENT_RETURN_BUFFER_GET_NAMED) {
      return 1;
    }

    boolean directIndexed = sourceOpcode == STATEMENT_RETURN_UTF8_SCALAR_NAMED;
    if (sourceOpcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
      directIndexed = true;
    }

    if (sourceOpcode == STATEMENT_RETURN_MAP_GET_NAMED) {
      directIndexed = true;
    }

    if (sourceOpcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
      directIndexed = true;
    }

    if (directIndexed) {
      return 3;
    }

    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
      return 3;
    }

    boolean localIndexed = sourceOpcode == STATEMENT_LOCAL_UTF8_SCALAR_NAMED;
    if (sourceOpcode == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      localIndexed = true;
    }

    if (sourceOpcode == STATEMENT_LOCAL_MAP_GET_NAMED) {
      localIndexed = true;
    }

    if (sourceOpcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      localIndexed = true;
    }

    if (localIndexed) {
      return 5;
    }

    if (sourceOpcode == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      return 5;
    }

    if (sourceOpcode == STATEMENT_RETURN_BUFFER_LENGTH_NAMED) {
      return 3;
    }

    return -1;
  }

  /// Resolves one intrinsic's primary source local, when applicable.
  public BorrowedIntrinsicOperand resolveBorrowedIntrinsicOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long sourceOpcode
  ) {
    long tokenOffset = borrowedPrimaryTokenOffset(sourceOpcode);
    if (tokenOffset < 0) {
      return new BorrowedIntrinsicOperand(-1, false);
    }

    long value = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + tokenOffset,
      true
    );
    return new BorrowedIntrinsicOperand(value, true);
  }

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
    boolean borrowedWrite = sourceOpcode == STATEMENT_SET_WORD_NAMED;
    if (sourceOpcode == STATEMENT_SET_BYTE_NAMED) {
      borrowedWrite = true;
    }

    if (sourceOpcode == STATEMENT_MAP_PUT_NAMED) {
      borrowedWrite = true;
    }

    if (borrowedWrite) {
      long writeOwner = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      long writeIndex = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 4,
        true
      );
      long writeValue = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 6,
        true
      );
      if (-1 < writeOwner) {
        if (-1 < writeIndex) {
          if (-1 < writeValue) {
            long resolvedWrite = STATEMENT_SET_WORD;
            if (sourceOpcode == STATEMENT_SET_BYTE_NAMED) {
              resolvedWrite = STATEMENT_SET_BYTE;
            }

            if (sourceOpcode == STATEMENT_MAP_PUT_NAMED) {
              resolvedWrite = STATEMENT_MAP_PUT;
            }

            return new ResolvedBorrowedIntrinsic(resolvedWrite, true);
          }
        }
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

    if (sourceOpcode == STATEMENT_RETURN_BUFFER_GET_NAMED) {
      long directReturnBufferSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 1,
        true
      );
      long directReturnBufferIndex = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < directReturnBufferSource) {
        if (-1 < directReturnBufferIndex) {
          return new ResolvedBorrowedIntrinsic(STATEMENT_RETURN_BUFFER_GET, true);
        }
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

    boolean directIndexedIntrinsic = sourceOpcode == STATEMENT_RETURN_UTF8_SCALAR_NAMED;
    if (sourceOpcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
      directIndexedIntrinsic = true;
    }

    if (sourceOpcode == STATEMENT_RETURN_MAP_GET_NAMED) {
      directIndexedIntrinsic = true;
    }

    if (sourceOpcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
      directIndexedIntrinsic = true;
    }

    if (directIndexedIntrinsic) {
      long directIntrinsicSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      long directIntrinsicIndex = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      if (-1 < directIntrinsicSource) {
        if (-1 < directIntrinsicIndex) {
          long directOpcode = STATEMENT_RETURN_UTF8_SCALAR;
          if (sourceOpcode == STATEMENT_RETURN_UTF8_WIDTH_NAMED) {
            directOpcode = STATEMENT_RETURN_UTF8_WIDTH;
          }

          if (sourceOpcode == STATEMENT_RETURN_MAP_GET_NAMED) {
            directOpcode = STATEMENT_RETURN_MAP_GET;
          }

          if (sourceOpcode == STATEMENT_RETURN_MAP_HAS_NAMED) {
            directOpcode = STATEMENT_RETURN_MAP_HAS;
          }

          return new ResolvedBorrowedIntrinsic(directOpcode, true);
        }
      }

      return new ResolvedBorrowedIntrinsic(-1, true);
    }

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

    boolean mapRead = sourceOpcode == STATEMENT_LOCAL_MAP_GET_NAMED;
    if (sourceOpcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
      mapRead = true;
    }

    if (mapRead) {
      long mapSource = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 5,
        true
      );
      long mapKey = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 7,
        true
      );
      if (-1 < mapSource) {
        if (-1 < mapKey) {
          long mapResolvedOpcode = STATEMENT_LOCAL_MAP_GET;
          if (sourceOpcode == STATEMENT_LOCAL_MAP_HAS_NAMED) {
            mapResolvedOpcode = STATEMENT_LOCAL_MAP_HAS;
          }

          return new ResolvedBorrowedIntrinsic(mapResolvedOpcode, true);
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
