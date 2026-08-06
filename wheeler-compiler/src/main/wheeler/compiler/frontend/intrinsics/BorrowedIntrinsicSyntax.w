//! Validates bounded source forms for primitive borrowed operations.

module wheeler.compiler.borrowed_intrinsic_syntax;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class BorrowedIntrinsicSyntax {
  /// Reports whether one source identity belongs to this closed intrinsic family.
  public boolean borrowedIntrinsicSourceStatement(long kind) {
    if (kind == STATEMENT_SET_WORD_NAMED) {
      return true;
    }

    if (kind == STATEMENT_SET_BYTE_NAMED) {
      return true;
    }

    if (kind == STATEMENT_RETURN_BUFFER_LENGTH_NAMED) {
      return true;
    }

    if (kind == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      return true;
    }

    if (kind == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
      return true;
    }

    if (kind == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      return true;
    }

    return kind == STATEMENT_LOCAL_BUFFER_GET_NAMED;
  }

  private long localBufferLengthWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (tokenKinds[statementStart + 1] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 5] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 6,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 7, PUNCTUATION_SEMICOLON)
    ) {
      return 8;
    }

    return -1;
  }

  private long returnBufferLengthWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (tokenKinds[statementStart + 3] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 4,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 5, PUNCTUATION_SEMICOLON)
    ) {
      return 6;
    }

    return -1;
  }

  private long borrowedWriteWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 4] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 5, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 6] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 7,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 8, PUNCTUATION_SEMICOLON)
    ) {
      return 9;
    }

    return -1;
  }

  private long localBufferGetWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (tokenKinds[statementStart + 1] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 3] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 4,
        PUNCTUATION_OPEN_SQUARE
      )
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 5] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 6,
        PUNCTUATION_CLOSE_SQUARE
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 7, PUNCTUATION_SEMICOLON)
    ) {
      return 8;
    }

    return -1;
  }

  private long localUtf8ScalarWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    if (tokenKinds[statementStart + 1] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 5] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 6, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 7] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 8,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 9, PUNCTUATION_SEMICOLON)
    ) {
      return 10;
    }

    return -1;
  }

  /// Validates and sizes one source statement in the closed intrinsic family.
  public long borrowedIntrinsicStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long kind
  ) {
    if (kind == STATEMENT_SET_WORD_NAMED) {
      return borrowedWriteWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    if (kind == STATEMENT_SET_BYTE_NAMED) {
      return borrowedWriteWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    if (kind == STATEMENT_LOCAL_BUFFER_LENGTH_NAMED) {
      return localBufferLengthWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    if (kind == STATEMENT_RETURN_BUFFER_LENGTH_NAMED) {
      return returnBufferLengthWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    if (kind == STATEMENT_LOCAL_UTF8_SCALAR_NAMED) {
      return localUtf8ScalarWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    if (kind == STATEMENT_LOCAL_UTF8_WIDTH_NAMED) {
      return localUtf8ScalarWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    if (kind == STATEMENT_LOCAL_BUFFER_GET_NAMED) {
      return localBufferGetWidth(source, tokenKinds, tokenStarts, statementStart);
    }

    return -1;
  }
}
