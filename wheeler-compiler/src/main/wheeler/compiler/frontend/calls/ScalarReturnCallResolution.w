//! Resolves zero- through seven-argument scalar calls in final returns.

module wheeler.compiler.scalar_return_call_resolution;

import wheeler.compiler.local_resolution;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;

classical class ScalarReturnCallResolution {
  private const long RETURN_SOURCE_COUNT = 256;
  private const long RETURN_SOURCE_SQUARE = 65536;
  private const long RETURN_SOURCE_CUBE = 16777216;

  /// Carries one resolved return opcode and whether this owner applies.
  public record ResolvedScalarReturnCall(long opcode, boolean applies) {}

  private long resolvedArgument(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long token
  ) {
    return resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      token,
      true
    );
  }

  /// Resolves one final scalar call without consuming unrelated return forms.
  public ResolvedScalarReturnCall resolveScalarReturnCall(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long sourceOpcode
  ) {
    if (sourceOpcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {} else {
      return new ResolvedScalarReturnCall(-1, false);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 3]) == PUNCTUATION_CLOSE_PAREN) {
      return new ResolvedScalarReturnCall(STATEMENT_RETURN_HELPER_CALL_ZERO, true);
    }

    long first = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 3
    );
    if (first < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 4]) == PUNCTUATION_COMMA) {} else {
      return new ResolvedScalarReturnCall(STATEMENT_RETURN_HELPER_CALL_BASE + first, true);
    }

    long second = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 5
    );
    if (second < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 6]) == PUNCTUATION_COMMA) {} else {
      long twoArgumentOpcode = STATEMENT_RETURN_HELPER_CALL_TWO_BASE + first * RETURN_SOURCE_COUNT
        + second;
      return new ResolvedScalarReturnCall(twoArgumentOpcode, true);
    }

    long third = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 7
    );
    if (third < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 8]) == PUNCTUATION_COMMA) {} else {
      long threeArgumentOpcode = STATEMENT_RETURN_HELPER_CALL_THREE_BASE + first
        * RETURN_SOURCE_SQUARE + second * RETURN_SOURCE_COUNT + third;
      return new ResolvedScalarReturnCall(threeArgumentOpcode, true);
    }

    long fourth = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 9
    );
    if (fourth < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 10]) == PUNCTUATION_COMMA) {} else {
      long fourArgumentOpcode = STATEMENT_RETURN_HELPER_CALL_FOUR_BASE + first * RETURN_SOURCE_CUBE
        + second * RETURN_SOURCE_SQUARE + third * RETURN_SOURCE_COUNT + fourth;
      return new ResolvedScalarReturnCall(fourArgumentOpcode, true);
    }

    long fifth = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 11
    );
    if (fifth < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 12]) == PUNCTUATION_COMMA) {} else {
      return new ResolvedScalarReturnCall(STATEMENT_RETURN_HELPER_CALL_FIVE, true);
    }

    long sixth = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 13
    );
    if (sixth < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 14]) == PUNCTUATION_COMMA) {} else {
      return new ResolvedScalarReturnCall(STATEMENT_RETURN_HELPER_CALL_SIX, true);
    }

    long seventh = resolvedArgument(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 15
    );
    if (seventh < 0) {
      return new ResolvedScalarReturnCall(-1, true);
    }

    return new ResolvedScalarReturnCall(STATEMENT_RETURN_HELPER_CALL_SEVEN, true);
  }
}
