//! Defines exact five- through seven-local scalar helper calls.

module wheeler.compiler.wide_local_calls;

import wheeler.compiler.four_argument_calls;
import wheeler.compiler.identifier_starts;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.three_argument_calls;
import wheeler.compiler.tokens;

classical class WideLocalCalls {
  /// Bounds scalar-call arguments by the final forwarding profile.
  public const long MAX_WIDE_LOCAL_CALL_ARGUMENTS = 7;
  /// Names one packed prior-local source digit.
  public const long WIDE_LOCAL_SOURCE_RADIX = 256;
  /// Names the first source stored in the trailing packed operand.
  private const long WIDE_LOCAL_TRAILING_SOURCE = 4;

  /// Returns the unresolved statement kind for an exact named arity.
  public long namedWideLocalCallKind(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    long arity = 3;
    long cursor = statementStart + 10;
    while (arity < MAX_WIDE_LOCAL_CALL_ARGUMENTS) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_COMMA) {} else {
        return wideLocalCallKind(arity);
      }

      if (identifierStart(utf8Scalar(source, tokenStarts[cursor + 1]))) {} else {
        return wideLocalCallKind(arity);
      }

      arity += 1;
      cursor += 2;
    }

    return wideLocalCallKind(arity);
  }

  /// Returns one exact unresolved wide-local statement kind.
  public long wideLocalCallKind(long arity) {
    if (arity == 3) {
      return STATEMENT_LOCAL_CALL_THREE_LOCALS_NAMED;
    }

    if (arity == 4) {
      return STATEMENT_LOCAL_CALL_FOUR_LOCALS_NAMED;
    }

    if (arity == 5) {
      return STATEMENT_LOCAL_CALL_FIVE_LOCALS_NAMED;
    }

    if (arity == 6) {
      return STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED;
    }

    if (arity == MAX_WIDE_LOCAL_CALL_ARGUMENTS) {
      return STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED;
    }

    return -1;
  }

  /// Returns one exact resolved wide-local statement identity.
  public long resolvedWideLocalCall(long arity) {
    if (arity == 5) {
      return STATEMENT_LOCAL_CALL_FIVE_LOCALS;
    }

    if (arity == 6) {
      return STATEMENT_LOCAL_CALL_SIX_LOCALS;
    }

    if (arity == MAX_WIDE_LOCAL_CALL_ARGUMENTS) {
      return STATEMENT_LOCAL_CALL_SEVEN_LOCALS;
    }

    return -1;
  }

  /// Checks for a fixed five- through seven-local identity.
  public boolean packedWideLocalCall(long opcode) {
    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS;
  }

  /// Returns the exact argument count, or minus one.
  public long wideLocalCallArity(long opcode) {
    if (threeArgumentCallStatement(opcode)) {
      return 3;
    }

    if (fourArgumentCallStatement(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS_NAMED) {
      return 5;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS) {
      return 5;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED) {
      return MAX_WIDE_LOCAL_CALL_ARGUMENTS;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS) {
      return MAX_WIDE_LOCAL_CALL_ARGUMENTS;
    }

    return -1;
  }

  /// Returns one source token in a named wide-local call.
  public long wideLocalCallArgumentToken(long statementStart, long argument) {
    return statementStart + 5 + argument * 2;
  }

  /// Validates and measures one exact wide-local source statement.
  public long wideLocalCallWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long statementKind
  ) {
    if (tokenKinds[statementStart + 1] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 2]) == PUNCTUATION_ASSIGN) {} else {
      return -1;
    }

    if (tokenKinds[statementStart + 3] == 1) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[statementStart + 4]) == PUNCTUATION_OPEN_PAREN) {} else {
      return -1;
    }

    long arity = wideLocalCallArity(statementKind);
    long argument = 0;
    long cursor = statementStart + 5;
    while (argument < arity) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      if (tokenKinds[cursor] == 1) {} else {
        return -1;
      }

      cursor += 1;
      argument += 1;
      if (argument < arity) {
        if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_COMMA) {} else {
          return -1;
        }

        cursor += 1;
      }
    }

    if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_CLOSE_PAREN) {} else {
      return -1;
    }

    if (utf8Scalar(source, tokenStarts[cursor + 1]) == PUNCTUATION_SEMICOLON) {
      return cursor - statementStart + 2;
    }

    return -1;
  }

  private long packedSource(long packed, long source, long base) {
    long selected = base;
    while (selected < source) limit MAX_WIDE_LOCAL_CALL_ARGUMENTS {
      packed = packed / WIDE_LOCAL_SOURCE_RADIX;
      selected += 1;
    }

    return packed % WIDE_LOCAL_SOURCE_RADIX;
  }

  /// Decodes one validated wide-local source.
  public long wideLocalCallSource(long opcode, long operand, long secondaryOperand, long source) {
    long arity = wideLocalCallArity(opcode);
    if (source < 0) {
      return -1;
    }

    if (source < arity) {} else {
      return -1;
    }

    if (arity == 3) {
      if (source == 0) {
        return operand;
      }

      if (source == 1) {
        return secondaryOperand;
      }

      return threeArgumentThirdSource(opcode);
    }

    if (arity == 4) {
      if (source == 0) {
        return operand;
      }

      if (source == 1) {
        return secondaryOperand;
      }

      if (source == 2) {
        return fourArgumentCallThirdSource(opcode);
      }

      return fourArgumentCallFourthSource(opcode);
    }

    if (source < WIDE_LOCAL_TRAILING_SOURCE) {
      return packedSource(operand, source, 0);
    }

    return packedSource(secondaryOperand, source, WIDE_LOCAL_TRAILING_SOURCE);
  }
}
