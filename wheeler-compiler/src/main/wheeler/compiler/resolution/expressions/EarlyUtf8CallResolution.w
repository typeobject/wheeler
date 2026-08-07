//! Resolves guarded UTF-8 owner-result calls against prior primitive locals.

module wheeler.compiler.early_utf8_call_resolution;

import wheeler.compiler.early_utf8_call_forms;
import wheeler.compiler.local_resolution;
import wheeler.compiler.tokens;

classical class EarlyUtf8CallResolution {
  /// Resolves a guarded call identity carrying its condition local and selector.
  public long resolveEarlyUtf8CallOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long condition = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      earlyUtf8ConditionToken(statementStart),
      true
    );
    if (condition < 0) {
      return -1;
    }

    long selectorToken = earlyUtf8SelectorToken(statementStart);
    if (signedNumberValid(source, tokenStarts, tokenLengths, selectorToken)) {} else {
      return -1;
    }

    long selector = parsedSignedNumber(source, tokenStarts, tokenLengths, selectorToken);
    if (selector < 0) {
      return -1;
    }

    if (selector < EARLY_UTF8_SELECTOR_COUNT) {} else {
      return -1;
    }

    return STATEMENT_IF_EQ_RETURN_UTF8_CALL_BASE + condition * EARLY_UTF8_SELECTOR_COUNT + selector;
  }

  /// Packs the guarded call's two primitive source locals.
  public long resolveEarlyUtf8CallOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long first = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      earlyUtf8FirstSourceToken(statementStart),
      true
    );
    if (first < 0) {
      return -1;
    }

    long second = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      earlyUtf8SecondSourceToken(statementStart),
      true
    );
    if (second < 0) {
      return -1;
    }

    return first * EARLY_UTF8_CALL_SOURCE_SCALE + second;
  }
}
