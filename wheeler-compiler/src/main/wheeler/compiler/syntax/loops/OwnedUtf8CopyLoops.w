//! Defines the exact bounded loop used to copy UTF-8 bytes into owned storage.

module wheeler.compiler.owned_utf8_copy_loops;

import wheeler.compiler.borrowed_intrinsic_kinds;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class OwnedUtf8CopyLoops {
  /// Names resolved owner-copy loops by their carried cursor local.
  public const long STATEMENT_OWNED_UTF8_COPY_LOOP_BASE = 393216;
  /// Bounds one local index encoded in a copy-loop identity.
  private const long COPY_LOOP_LOCAL_COUNT = 256;
  /// Packs one owner and source local into the primary operand.
  public const long COPY_LOOP_SOURCE_SCALE = 256;
  /// Packs one condition local and literal limit into the secondary operand.
  public const long COPY_LOOP_LIMIT_SCALE = 65536;
  /// Names the exact source width of the admitted copy loop.
  private const long COPY_LOOP_TOKEN_WIDTH = 29;
  /// Names the loop's owner plus ten scalar and borrowed temporaries.
  public const long COPY_LOOP_FRAME_WIDTH = 11;
  /// Names the canonical encoded instruction bytes for one copy loop.
  private const long COPY_LOOP_CODE_LENGTH = 408;
  /// Names the canonical instruction count for one copy loop.
  private const long COPY_LOOP_INSTRUCTION_COUNT = 16;

  /// Checks whether one opcode carries an owned UTF-8 copy-loop cursor.
  public boolean ownedUtf8CopyLoop(long opcode) {
    if (opcode < STATEMENT_OWNED_UTF8_COPY_LOOP_BASE) {
      return false;
    }

    return opcode < STATEMENT_OWNED_UTF8_COPY_LOOP_BASE + COPY_LOOP_LOCAL_COUNT;
  }

  /// Returns the cursor local carried by one resolved copy loop.
  public long ownedUtf8CopyCursor(long opcode) {
    return opcode - STATEMENT_OWNED_UTF8_COPY_LOOP_BASE;
  }

  /// Returns the token naming the copied owner.
  public long ownedUtf8CopyOwnerToken(long statementStart) {
    return statementStart + 11;
  }

  /// Returns the token naming the immutable UTF-8 source.
  public long ownedUtf8CopySourceToken(long statementStart) {
    return statementStart + 17;
  }

  /// Returns the token naming the loop condition's right local.
  public long ownedUtf8CopyLengthToken(long statementStart) {
    return statementStart + 4;
  }

  /// Returns the token naming the loop limit constant.
  public long ownedUtf8CopyLimitToken(long statementStart) {
    return statementStart + 7;
  }

  /// Returns the token naming the loop cursor.
  public long ownedUtf8CopyCursorToken(long statementStart) {
    return statementStart + 2;
  }

  /// Recognizes the distinctive intrinsic pair after structural validation.
  public boolean ownedUtf8CopyLoopCandidate(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 9) == TOKEN_SET_BYTE
    ) {
      return tokenHash(source, tokenStarts, tokenLengths, statementStart + 15) == TOKEN_UTF8_SCALAR;
    }

    return false;
  }

  /// Returns the canonical local frame width for one resolved copy loop.
  public long ownedUtf8CopyLocalCount(long opcode) {
    if (ownedUtf8CopyLoop(opcode)) {
      return COPY_LOOP_FRAME_WIDTH;
    }

    return -1;
  }

  /// Returns the canonical code width for one resolved copy loop.
  public long ownedUtf8CopyCodeLength(long opcode) {
    if (ownedUtf8CopyLoop(opcode)) {
      return COPY_LOOP_CODE_LENGTH;
    }

    return -1;
  }

  /// Returns the canonical instruction count for one resolved copy loop.
  public long ownedUtf8CopyInstructionCount(long opcode) {
    if (ownedUtf8CopyLoop(opcode)) {
      return COPY_LOOP_INSTRUCTION_COUNT;
    }

    return -1;
  }

  private boolean identifierAt(borrow mut words tokenKinds, long token) {
    return tokenKinds[token] == 1;
  }

  /// Validates the exact bounded owner-copy loop, or returns minus one.
  public long ownedUtf8CopyLoopWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
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

    if (identifierAt(tokenKinds, statementStart + 2)) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_LESS_THAN)
    ) {} else {
      return -1;
    }

    if (identifierAt(tokenKinds, statementStart + 4)) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 5,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 6) == TOKEN_LIMIT
    ) {} else {
      return -1;
    }

    if (identifierAt(tokenKinds, statementStart + 7)) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 8,
        PUNCTUATION_OPEN_BRACE
      )
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 9) == TOKEN_SET_BYTE
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 10,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    if (identifierAt(tokenKinds, statementStart + 11)) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 12, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (identifierAt(tokenKinds, statementStart + 13)) {} else {
      return -1;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, statementStart + 2, statementStart + 13)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 14, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 15) == TOKEN_UTF8_SCALAR
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 16,
        PUNCTUATION_OPEN_PAREN
      )
    ) {} else {
      return -1;
    }

    if (identifierAt(tokenKinds, statementStart + 17)) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 18, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (identifierAt(tokenKinds, statementStart + 19)) {} else {
      return -1;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, statementStart + 2, statementStart + 19)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 20,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 21,
        PUNCTUATION_CLOSE_PAREN
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 22,
        PUNCTUATION_SEMICOLON
      )
    ) {} else {
      return -1;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, statementStart + 2, statementStart + 23)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 24, PUNCTUATION_PLUS)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 25, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (tokenLengths[statementStart + 26] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 26]) == SCALAR_DIGIT_ONE) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 27,
        PUNCTUATION_SEMICOLON
      )
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 28,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return COPY_LOOP_TOKEN_WIDTH;
    }

    return -1;
  }
}
