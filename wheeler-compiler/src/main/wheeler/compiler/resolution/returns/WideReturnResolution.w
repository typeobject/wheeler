//! Resolves packed source operands for five- through seven-argument final calls.

module wheeler.compiler.wide_return_resolution;

import wheeler.compiler.forwarded_helper_result_statements;
import wheeler.compiler.local_resolution;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.wide_return_sources;

classical class WideReturnResolution {
  /// Checks whether one resolved opcode keeps sources outside its identity.
  public boolean wideReturnCall(long opcode) {
    if (opcode == STATEMENT_RETURN_HELPER_CALL_FIVE) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_HELPER_CALL_SIX) {
      return true;
    }

    return opcode == STATEMENT_RETURN_HELPER_CALL_SEVEN;
  }

  /// Resolves and packs the first four prior-local sources.
  public long resolveWideReturnFirstSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart
  ) {
    long first = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 3,
      true
    );
    long second = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 5,
      true
    );
    long third = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 7,
      true
    );
    long fourth = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 9,
      true
    );
    if (first < 0) {
      return -1;
    }

    if (second < 0) {
      return -1;
    }

    if (third < 0) {
      return -1;
    }

    if (fourth < 0) {
      return -1;
    }

    return packWideReturnFirstSources(first, second, third, fourth);
  }

  /// Resolves and packs the final one through three prior-local sources.
  public long resolveWideReturnLastSources(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long statementStart,
    long opcode
  ) {
    long fifth = resolvePriorDeclaration(
      source,
      tokenStarts,
      tokenLengths,
      previousStarts,
      previousCount,
      statementStart + 11,
      true
    );
    if (fifth < 0) {
      return -1;
    }

    long sixth = 0;
    if (opcode == STATEMENT_RETURN_HELPER_CALL_SIX) {
      sixth = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 13,
        true
      );
    }

    long seventh = 0;
    if (opcode == STATEMENT_RETURN_HELPER_CALL_SEVEN) {
      sixth = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 13,
        true
      );
      seventh = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 15,
        true
      );
    }

    if (sixth < 0) {
      return -1;
    }

    if (seventh < 0) {
      return -1;
    }

    return packWideReturnLastSources(fifth, sixth, seventh);
  }
}
