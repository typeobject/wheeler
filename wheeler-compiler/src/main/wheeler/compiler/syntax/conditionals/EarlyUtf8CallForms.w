//! Defines exact guarded UTF-8 owner-result calls for bounded source selection.

module wheeler.compiler.early_utf8_call_forms;

import wheeler.compiler.keyword_tokens;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class EarlyUtf8CallForms {
  /// Names the unresolved exact guarded two-argument UTF-8 call.
  public const long STATEMENT_IF_EQ_RETURN_UTF8_CALL_NAMED = 918;
  /// Names resolved guarded calls by condition local and literal selector.
  public const long STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE = 458752;
  /// Bounds selector literals admitted by the seven-source graph frame.
  public const long EARLY_UTF8_SELECTOR_COUNT = 8;
  /// Packs two source locals into one statement operand.
  public const long EARLY_UTF8_CALL_SOURCE_SCALE = 256;
  /// Names the exact token width of one guarded call.
  private const long EARLY_UTF8_CALL_TOKEN_WIDTH = 17;
  /// Names condition, argument, reborrow, and result locals.
  public const long EARLY_UTF8_CALL_LOCAL_COUNT = 8;
  /// Names the canonical encoded bytes for one guarded call.
  private const long EARLY_UTF8_CALL_CODE_LENGTH = 272;
  /// Names the canonical guarded call instruction count.
  private const long EARLY_UTF8_CALL_INSTRUCTION_COUNT = 11;

  /// Checks whether one opcode carries a guarded UTF-8 call selector.
  public boolean earlyUtf8Call(long opcode) {
    if (opcode < STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE) {
      return false;
    }

    return opcode < STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE + EARLY_UTF8_CALL_SOURCE_SCALE
      * EARLY_UTF8_SELECTOR_COUNT;
  }

  /// Returns the guarded call's condition local.
  public long earlyUtf8ConditionLocal(long opcode) {
    return(opcode - STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE) / EARLY_UTF8_SELECTOR_COUNT;
  }

  /// Returns the guarded call's selector literal.
  public long earlyUtf8Selector(long opcode) {
    return(opcode - STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE) % EARLY_UTF8_SELECTOR_COUNT;
  }

  /// Returns the first call-argument token.
  public long earlyUtf8FirstSourceToken(long statementStart) {
    return statementStart + 11;
  }

  /// Returns the second call-argument token.
  public long earlyUtf8SecondSourceToken(long statementStart) {
    return statementStart + 13;
  }

  /// Returns the helper target token.
  public long earlyUtf8CallTargetToken(long statementStart) {
    return statementStart + 9;
  }

  /// Returns the condition-local token.
  public long earlyUtf8ConditionToken(long statementStart) {
    return statementStart + 2;
  }

  /// Returns the selector literal token.
  public long earlyUtf8SelectorToken(long statementStart) {
    return statementStart + 5;
  }

  /// Returns the canonical local frame width for one guarded call.
  public long earlyUtf8CallLocalCount(long opcode) {
    if (earlyUtf8Call(opcode)) {
      return EARLY_UTF8_CALL_LOCAL_COUNT;
    }

    return -1;
  }

  /// Returns the canonical code width for one guarded call.
  public long earlyUtf8CallCodeLength(long opcode) {
    if (earlyUtf8Call(opcode)) {
      return EARLY_UTF8_CALL_CODE_LENGTH;
    }

    return -1;
  }

  /// Returns the canonical instruction count for one guarded call.
  public long earlyUtf8CallInstructionCount(long opcode) {
    if (earlyUtf8Call(opcode)) {
      return EARLY_UTF8_CALL_INSTRUCTION_COUNT;
    }

    return -1;
  }

  /// Validates one exact guarded two-argument UTF-8 call.
  public long earlyUtf8CallWidth(
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

    if (tokenKinds[statementStart + 2] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, PUNCTUATION_ASSIGN)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 5] == 2) {} else {
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
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 7,
        PUNCTUATION_OPEN_BRACE
      )
    ) {} else {
      return -1;
    }

    if (
      tokenHash(source, tokenStarts, tokenLengths, statementStart + 8) == TOKEN_RETURN
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 9] == 1) {} else {
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

    if (tokenKinds[statementStart + 11] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 12, PUNCTUATION_COMMA)
    ) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 13] == 1) {} else {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 14,
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
        statementStart + 15,
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
        statementStart + 16,
        PUNCTUATION_CLOSE_BRACE
      )
    ) {
      return EARLY_UTF8_CALL_TOKEN_WIDTH;
    }

    return -1;
  }
}
