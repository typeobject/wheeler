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

  private long namedWideLocalCallKindAfterArguments(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long arity,
    long cursor,
    boolean booleanResult
  ) {
    long currentKind = wideLocalCallKind(arity, booleanResult);
    if (arity == MAX_WIDE_LOCAL_CALL_ARGUMENTS) {
      return currentKind;
    }

    long punctuationOffset = tokenStarts[cursor];
    long punctuation = utf8Scalar(source, punctuationOffset);
    boolean comma = punctuation == PUNCTUATION_COMMA;
    if (comma == false) {
      return currentKind;
    }

    long argumentToken = cursor + 1;
    long argumentOffset = tokenStarts[argumentToken];
    long argument = utf8Scalar(source, argumentOffset);
    boolean starts = identifierStart(argument);
    if (starts == false) {
      return currentKind;
    }

    long nextArity = arity + 1;
    long nextCursor = cursor + 2;
    return namedWideLocalCallKindAfterArguments(
      source,
      tokenStarts,
      nextArity,
      nextCursor,
      booleanResult
    );
  }

  /// Returns the unresolved statement kind for an exact named arity and result type.
  public long namedWideLocalCallKind(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart,
    boolean booleanResult
  ) {
    long arity = 3;
    long cursor = statementStart + 10;
    return namedWideLocalCallKindAfterArguments(
      source,
      tokenStarts,
      arity,
      cursor,
      booleanResult
    );
  }

  private long namedBooleanWideLocalCallKind(long arity) {
    if (arity == 3) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_THREE_LOCALS_NAMED;
    }

    if (arity == 4) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_FOUR_LOCALS_NAMED;
    }

    if (arity == 5) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS_NAMED;
    }

    if (arity == 6) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS_NAMED;
    }

    if (arity == MAX_WIDE_LOCAL_CALL_ARGUMENTS) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS_NAMED;
    }

    return -1;
  }

  /// Returns one exact unresolved wide-local statement kind.
  public long wideLocalCallKind(long arity, boolean booleanResult) {
    long booleanKind = namedBooleanWideLocalCallKind(arity);
    if (booleanResult == true) {
      return booleanKind;
    }

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

  private long resolvedBooleanWideLocalCall(long arity) {
    if (arity == 5) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS;
    }

    if (arity == 6) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS;
    }

    if (arity == MAX_WIDE_LOCAL_CALL_ARGUMENTS) {
      return STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS;
    }

    return -1;
  }

  /// Returns one exact resolved wide-local statement identity.
  public long resolvedWideLocalCall(long arity, boolean booleanResult) {
    long booleanKind = resolvedBooleanWideLocalCall(arity);
    if (booleanResult == true) {
      return booleanKind;
    }

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

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS;
  }

  /// Checks whether one wide-local call returns Boolean.
  public boolean booleanWideLocalCall(long opcode) {
    if (threeArgumentBooleanCall(opcode)) {
      return true;
    }

    if (fourArgumentBooleanCall(opcode)) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS;
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

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS_NAMED) {
      return 5;
    }

    if (opcode == STATEMENT_LOCAL_CALL_FIVE_LOCALS) {
      return 5;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_FIVE_LOCALS) {
      return 5;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS_NAMED) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SIX_LOCALS) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SIX_LOCALS) {
      return 6;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS_NAMED) {
      return MAX_WIDE_LOCAL_CALL_ARGUMENTS;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS_NAMED) {
      return MAX_WIDE_LOCAL_CALL_ARGUMENTS;
    }

    if (opcode == STATEMENT_LOCAL_CALL_SEVEN_LOCALS) {
      return MAX_WIDE_LOCAL_CALL_ARGUMENTS;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_CALL_SEVEN_LOCALS) {
      return MAX_WIDE_LOCAL_CALL_ARGUMENTS;
    }

    return -1;
  }

  /// Returns one source token in a named wide-local call.
  public long wideLocalCallArgumentToken(long statementStart, long argument) {
    long doubled = argument * 2;
    long first = statementStart + 5;
    return first + doubled;
  }

  private long wideLocalArgumentsEnd(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long argument,
    long arity,
    long cursor
  ) {
    if (argument == arity) {
      return cursor;
    }

    long kind = tokenKinds[cursor];
    boolean validKind = kind == 1;
    if (validKind == false) {
      return -1;
    }

    long nextArgument = argument + 1;
    long nextCursor = cursor + 1;
    if (nextArgument == arity) {
      return nextCursor;
    }

    long commaOffset = tokenStarts[nextCursor];
    long commaScalar = utf8Scalar(source, commaOffset);
    boolean comma = commaScalar == PUNCTUATION_COMMA;
    if (comma == false) {
      return -1;
    }

    long followingCursor = nextCursor + 1;
    return wideLocalArgumentsEnd(
      source,
      tokenKinds,
      tokenStarts,
      nextArgument,
      arity,
      followingCursor
    );
  }

  /// Validates and measures one exact wide-local source statement.
  public long wideLocalCallWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long statementKind
  ) {
    long targetToken = statementStart + 1;
    long targetKind = tokenKinds[targetToken];
    boolean validTarget = targetKind == 1;
    if (validTarget == false) {
      return -1;
    }

    long assignmentToken = statementStart + 2;
    long assignmentOffset = tokenStarts[assignmentToken];
    long assignment = utf8Scalar(source, assignmentOffset);
    boolean validAssignment = assignment == PUNCTUATION_ASSIGN;
    if (validAssignment == false) {
      return -1;
    }

    long helperToken = statementStart + 3;
    long helperKind = tokenKinds[helperToken];
    boolean validHelper = helperKind == 1;
    if (validHelper == false) {
      return -1;
    }

    long openingToken = statementStart + 4;
    long openingOffset = tokenStarts[openingToken];
    long opening = utf8Scalar(source, openingOffset);
    boolean validOpening = opening == PUNCTUATION_OPEN_PAREN;
    if (validOpening == false) {
      return -1;
    }

    long arity = wideLocalCallArity(statementKind);
    if (arity < 0) {
      return -1;
    }

    long argument = 0;
    long firstArgument = statementStart + 5;
    long cursor = wideLocalArgumentsEnd(
      source,
      tokenKinds,
      tokenStarts,
      argument,
      arity,
      firstArgument
    );
    if (cursor < 0) {
      return -1;
    }

    long closingOffset = tokenStarts[cursor];
    long closing = utf8Scalar(source, closingOffset);
    boolean validClosing = closing == PUNCTUATION_CLOSE_PAREN;
    if (validClosing == false) {
      return -1;
    }

    long semicolonToken = cursor + 1;
    long semicolonOffset = tokenStarts[semicolonToken];
    long semicolon = utf8Scalar(source, semicolonOffset);
    long width = cursor - statementStart;
    long result = width + 2;
    if (semicolon == PUNCTUATION_SEMICOLON) {
      return result;
    }

    return -1;
  }

  private long packedSource(long packed, long source, long selected) {
    if (source < selected) {
      return -1;
    }

    if (selected == source) {
      return packed % WIDE_LOCAL_SOURCE_RADIX;
    }

    long reduced = packed / WIDE_LOCAL_SOURCE_RADIX;
    long next = selected + 1;
    return packedSource(reduced, source, next);
  }

  /// Decodes one validated wide-local source.
  public long wideLocalCallSource(long opcode, long operand, long secondaryOperand, long source) {
    long arity = wideLocalCallArity(opcode);
    if (source < 0) {
      return -1;
    }

    boolean validSource = source < arity;
    if (validSource == false) {
      return -1;
    }

    long threeThird = threeArgumentThirdSource(opcode);
    long fourThird = fourArgumentCallThirdSource(opcode);
    long fourFourth = fourArgumentCallFourthSource(opcode);
    long firstBase = 0;
    long firstSource = packedSource(operand, source, firstBase);
    long trailingBase = WIDE_LOCAL_TRAILING_SOURCE;
    long trailingSource = packedSource(secondaryOperand, source, trailingBase);
    long scaledArity = arity * 8;
    long selector = scaledArity + source;
    if (selector == 24) {
      return operand;
    }

    if (selector == 25) {
      return secondaryOperand;
    }

    if (selector == 26) {
      return threeThird;
    }

    if (selector == 32) {
      return operand;
    }

    if (selector == 33) {
      return secondaryOperand;
    }

    if (selector == 34) {
      return fourThird;
    }

    if (selector == 35) {
      return fourFourth;
    }

    if (source < WIDE_LOCAL_TRAILING_SOURCE) {
      return firstSource;
    }

    return trailingSource;
  }
}
