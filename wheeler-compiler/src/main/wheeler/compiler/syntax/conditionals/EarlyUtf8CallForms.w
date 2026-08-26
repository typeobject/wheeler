//! Defines exact guarded UTF-8 owner-result calls for bounded source selection.

module wheeler.compiler.early_utf8_call_forms;

import wheeler.compiler.source_scalars;

classical class EarlyUtf8CallForms {
  /// Names the unresolved exact guarded two-argument UTF-8 call.
  public const long STATEMENT_IF_EQ_RETURN_UTF8_CALL_NAMED = 918;
  /// Names resolved guarded calls by condition local and literal selector.
  public const long STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE = 458752;
  /// Bounds selector literals admitted by the seven-source graph frame.
  public const long EARLY_UTF8_SELECTOR_COUNT = 8;
  /// Packs two source locals into one statement operand.
  public const long EARLY_UTF8_CALL_SOURCE_SCALE = 256;
  /// Excludes selectors beyond eight packed source rows.
  private const long EARLY_UTF8_CALL_LIMIT = 460800;
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

    return opcode < EARLY_UTF8_CALL_LIMIT;
  }

  /// Returns the guarded call's condition local.
  public long earlyUtf8ConditionLocal(long opcode) {
    long relative = opcode - STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE;
    return relative / EARLY_UTF8_SELECTOR_COUNT;
  }

  /// Returns the guarded call's selector literal.
  public long earlyUtf8Selector(long opcode) {
    long relative = opcode - STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE;
    return relative % EARLY_UTF8_SELECTOR_COUNT;
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

  private boolean punctuationAt(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long token,
    long scalar
  ) {
    long kind = tokenKinds[token];
    boolean punctuation = kind == 3;
    if (punctuation == false) {
      return false;
    }

    long start = tokenStarts[token];
    long actual = utf8Scalar(source, start);
    return actual == scalar;
  }

  private boolean returnTokenAt(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long length = tokenLengths[token];
    boolean validLength = length == 6;
    if (validLength == false) {
      return false;
    }

    long start = tokenStarts[token];
    long first = utf8Scalar(source, start);
    boolean validFirst = first == 114;
    if (validFirst == false) {
      return false;
    }

    long secondStart = start + 1;
    long second = utf8Scalar(source, secondStart);
    boolean validSecond = second == 101;
    if (validSecond == false) {
      return false;
    }

    long thirdStart = start + 2;
    long third = utf8Scalar(source, thirdStart);
    boolean validThird = third == 116;
    if (validThird == false) {
      return false;
    }

    long fourthStart = start + 3;
    long fourth = utf8Scalar(source, fourthStart);
    boolean validFourth = fourth == 117;
    if (validFourth == false) {
      return false;
    }

    long fifthStart = start + 4;
    long fifth = utf8Scalar(source, fifthStart);
    boolean validFifth = fifth == 114;
    if (validFifth == false) {
      return false;
    }

    long sixthStart = start + 5;
    long sixth = utf8Scalar(source, sixthStart);
    return sixth == 110;
  }

  private boolean validEarlyUtf8Condition(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long openParen = PUNCTUATION_OPEN_PAREN;
    long assignment = PUNCTUATION_ASSIGN;
    long closeParen = PUNCTUATION_CLOSE_PAREN;
    long openBrace = PUNCTUATION_OPEN_BRACE;
    long openCondition = statementStart + 1;
    boolean validOpenCondition = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      openCondition,
      openParen
    );
    if (validOpenCondition == false) {
      return false;
    }

    long conditionLocal = statementStart + 2;
    long conditionKind = tokenKinds[conditionLocal];
    boolean validConditionKind = conditionKind == 1;
    if (validConditionKind == false) {
      return false;
    }

    long firstAssignment = statementStart + 3;
    boolean validFirstAssignment = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      firstAssignment,
      assignment
    );
    if (validFirstAssignment == false) {
      return false;
    }

    long secondAssignment = statementStart + 4;
    boolean validSecondAssignment = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      secondAssignment,
      assignment
    );
    if (validSecondAssignment == false) {
      return false;
    }

    long selector = statementStart + 5;
    long selectorKind = tokenKinds[selector];
    boolean validSelectorKind = selectorKind == 2;
    if (validSelectorKind == false) {
      return false;
    }

    long closeCondition = statementStart + 6;
    boolean validCloseCondition = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      closeCondition,
      closeParen
    );
    if (validCloseCondition == false) {
      return false;
    }

    long openBody = statementStart + 7;
    return punctuationAt(source, tokenKinds, tokenStarts, openBody, openBrace);
  }

  private boolean validEarlyUtf8CallBody(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long openParen = PUNCTUATION_OPEN_PAREN;
    long comma = PUNCTUATION_COMMA;
    long closeParen = PUNCTUATION_CLOSE_PAREN;
    long semicolon = PUNCTUATION_SEMICOLON;
    long closeBrace = PUNCTUATION_CLOSE_BRACE;
    long returnKeyword = statementStart + 8;
    boolean validReturnToken = returnTokenAt(source, tokenStarts, tokenLengths, returnKeyword);
    if (validReturnToken == false) {
      return false;
    }

    long callTarget = statementStart + 9;
    long callTargetKind = tokenKinds[callTarget];
    boolean validCallTargetKind = callTargetKind == 1;
    if (validCallTargetKind == false) {
      return false;
    }

    long openArguments = statementStart + 10;
    boolean validOpenArguments = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      openArguments,
      openParen
    );
    if (validOpenArguments == false) {
      return false;
    }

    long firstSource = statementStart + 11;
    long firstSourceKind = tokenKinds[firstSource];
    boolean validFirstSourceKind = firstSourceKind == 1;
    if (validFirstSourceKind == false) {
      return false;
    }

    long separator = statementStart + 12;
    boolean validSeparator = punctuationAt(source, tokenKinds, tokenStarts, separator, comma);
    if (validSeparator == false) {
      return false;
    }

    long secondSource = statementStart + 13;
    long secondSourceKind = tokenKinds[secondSource];
    boolean validSecondSourceKind = secondSourceKind == 1;
    if (validSecondSourceKind == false) {
      return false;
    }

    long closeArguments = statementStart + 14;
    boolean validCloseArguments = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      closeArguments,
      closeParen
    );
    if (validCloseArguments == false) {
      return false;
    }

    long callEnd = statementStart + 15;
    boolean validCallEnd = punctuationAt(source, tokenKinds, tokenStarts, callEnd, semicolon);
    if (validCallEnd == false) {
      return false;
    }

    long closeBody = statementStart + 16;
    return punctuationAt(source, tokenKinds, tokenStarts, closeBody, closeBrace);
  }

  /// Validates one exact guarded two-argument UTF-8 call.
  public long earlyUtf8CallWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    boolean conditionValid = validEarlyUtf8Condition(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStart
    );
    if (conditionValid == false) {
      return -1;
    }

    boolean callValid = validEarlyUtf8CallBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStart
    );
    if (callValid == false) {
      return -1;
    }

    return EARLY_UTF8_CALL_TOKEN_WIDTH;
  }
}
