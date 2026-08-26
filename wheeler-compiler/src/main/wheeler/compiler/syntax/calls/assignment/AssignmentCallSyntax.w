//! Parses and measures bounded calls assigned into existing signed locals.

module wheeler.compiler.assignment_call_syntax;

import wheeler.compiler.assignment_call_arities;
import wheeler.compiler.assignment_call_columns;
import wheeler.compiler.assignment_call_identities;
import wheeler.compiler.identifier_starts;
import wheeler.compiler.source_scalars;

classical class AssignmentCallSyntax {
  private long classifyArguments(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long arity,
    long cursor
  ) {
    long currentKind = sourceKind(arity);
    if (arity == MAX_ASSIGNMENT_CALL_ARGUMENTS) {
      return currentKind;
    }

    long offset = tokenStarts[cursor];
    long scalar = utf8Scalar(source, offset);
    boolean starts = identifierStart(scalar);
    if (starts == false) {
      return currentKind;
    }

    long nextArity = arity + 1;
    long nextKind = sourceKind(nextArity);
    long nextCursor = cursor + 1;
    long punctuationOffset = tokenStarts[nextCursor];
    long punctuation = utf8Scalar(source, punctuationOffset);
    boolean comma = punctuation == PUNCTUATION_COMMA;
    if (comma == false) {
      return nextKind;
    }

    long followingCursor = nextCursor + 1;
    return classifyArguments(source, tokenStarts, nextArity, followingCursor);
  }

  private long classifyAfterOpening(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long cursor
  ) {
    long offset = tokenStarts[cursor];
    long scalar = utf8Scalar(source, offset);
    long arity = 0;
    long emptyKind = sourceKind(arity);
    if (scalar == PUNCTUATION_CLOSE_PAREN) {
      return emptyKind;
    }

    return classifyArguments(source, tokenStarts, arity, cursor);
  }

  /// Classifies one assignment whose right side starts with a helper call.
  public long namedAssignmentCallKind(
    borrow utf8 source,
    borrow mut words tokenStarts,
    long statementStart
  ) {
    long openingToken = statementStart + 3;
    long openingOffset = tokenStarts[openingToken];
    long opening = utf8Scalar(source, openingOffset);
    boolean validOpening = opening == PUNCTUATION_OPEN_PAREN;
    if (validOpening == false) {
      return -1;
    }

    long cursor = statementStart + 4;
    return classifyAfterOpening(source, tokenStarts, cursor);
  }

  /// Returns one argument token in a call assignment.
  public long assignmentCallArgumentToken(long statementStart, long argument) {
    long doubled = argument * 2;
    long first = statementStart + 4;
    return first + doubled;
  }

  private long assignmentArgumentAfterKind(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long nextArgument,
    long arity,
    long nextCursor
  ) {
    if (nextArgument == arity) {
      return nextCursor;
    }

    long punctuationOffset = tokenStarts[nextCursor];
    long punctuation = utf8Scalar(source, punctuationOffset);
    boolean comma = punctuation == PUNCTUATION_COMMA;
    if (comma == false) {
      return -1;
    }

    long followingCursor = nextCursor + 1;
    return assignmentArgumentsEnd(
      source,
      tokenKinds,
      tokenStarts,
      nextArgument,
      arity,
      followingCursor
    );
  }

  private long assignmentArgumentsEnd(
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
    boolean argumentKind = kind == 1;
    if (argumentKind == false) {
      return -1;
    }

    long nextArgument = argument + 1;
    long nextCursor = cursor + 1;
    return assignmentArgumentAfterKind(
      source,
      tokenKinds,
      tokenStarts,
      nextArgument,
      arity,
      nextCursor
    );
  }

  private long widthAfterClosing(long statementStart, long cursor, long semicolon) {
    long width = cursor - statementStart;
    long result = width + 2;
    if (semicolon == PUNCTUATION_SEMICOLON) {
      return result;
    }

    return -1;
  }

  private long widthAfterArguments(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long arity = assignmentCallArity(opcode);
    if (arity < 0) {
      return -1;
    }

    long argument = 0;
    long firstArgument = statementStart + 4;
    long cursor = assignmentArgumentsEnd(
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
    long semicolonToken = cursor + 1;
    long semicolonOffset = tokenStarts[semicolonToken];
    long semicolon = utf8Scalar(source, semicolonOffset);
    boolean validClosing = closing == PUNCTUATION_CLOSE_PAREN;
    if (validClosing == false) {
      return -1;
    }

    return widthAfterClosing(statementStart, cursor, semicolon);
  }

  private long widthAfterHelper(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long openingToken = statementStart + 3;
    long openingOffset = tokenStarts[openingToken];
    long opening = utf8Scalar(source, openingOffset);
    boolean validOpening = opening == PUNCTUATION_OPEN_PAREN;
    if (validOpening == false) {
      return -1;
    }

    return widthAfterArguments(source, tokenKinds, tokenStarts, statementStart, opcode);
  }

  private long widthAfterAssignment(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long helperToken = statementStart + 2;
    long helperKind = tokenKinds[helperToken];
    boolean validHelper = helperKind == 1;
    if (validHelper == false) {
      return -1;
    }

    return widthAfterHelper(source, tokenKinds, tokenStarts, statementStart, opcode);
  }

  private long widthAfterTarget(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long assignmentToken = statementStart + 1;
    long assignmentOffset = tokenStarts[assignmentToken];
    long assignment = utf8Scalar(source, assignmentOffset);
    boolean validAssignment = assignment == PUNCTUATION_ASSIGN;
    if (validAssignment == false) {
      return -1;
    }

    return widthAfterAssignment(source, tokenKinds, tokenStarts, statementStart, opcode);
  }

  /// Validates and measures one exact call-assignment source statement.
  public long assignmentCallWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long statementStart,
    long opcode
  ) {
    long targetKind = tokenKinds[statementStart];
    boolean validTarget = targetKind == 1;
    if (validTarget == false) {
      return -1;
    }

    return widthAfterTarget(source, tokenKinds, tokenStarts, statementStart, opcode);
  }
}
