//! Parses bounded entryless libraries with several scalar helpers.

module wheeler.compiler.scalar_helper_libraries;

import wheeler.compiler.body_parser;
import wheeler.compiler.class_constants;
import wheeler.compiler.class_layouts;
import wheeler.compiler.early_comparison_forms;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.resolved_early_result_kinds;
import wheeler.compiler.sequences;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;

classical class ScalarHelperLibraries {
  /// Carries one complete scalar helper and the following declaration token.
  private record ParsedScalarHelper(HelperBody body, long nextToken, boolean valid) {}

  private ParsedScalarHelper invalidHelper() {
    return new ParsedScalarHelper(emptyHelperBody(), 0, false);
  }

  private boolean signedResult(long opcode) {
    if (opcode == STATEMENT_RETURN_LONG) {
      return true;
    }

    if (resolvedSignedLocalReturn(opcode)) {
      return true;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return true;
    }

    return returnLocalPairStatement(opcode);
  }

  private boolean booleanResult(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      return true;
    }

    if (returnComparisonStatement(opcode)) {
      return true;
    }

    if (resolvedLocalReturn(opcode)) {
      return resolvedSignedLocalReturn(opcode) == false;
    }

    return false;
  }

  private boolean scalarSequenceValid(StatementSequence sequence, long kind) {
    if (0 < sequence.count) {} else {
      return false;
    }

    long result = sequence.count - 1;
    boolean validResult = signedResult(sequence.opcodes[result]);
    if (kind == HELPER_BOOLEAN_SIGNED_ONE) {
      validResult = booleanResult(sequence.opcodes[result]);
    }

    if (validResult) {} else {
      return false;
    }

    long statement = 0;
    while (statement < result) limit MAX_MINIMAL_STATEMENTS {
      long earlyOpcode = sequence.opcodes[statement];
      boolean earlyReturn = resolvedEarlyComparisonReturn(earlyOpcode);
      if (resolvedEarlyHelperReturn(earlyOpcode)) {
        earlyReturn = true;
      }

      if (earlyReturn) {} else {
        return false;
      }

      boolean signedEarlyReturn = resolvedEarlySignedReturn(earlyOpcode);
      if (kind == HELPER_BOOLEAN_SIGNED_ONE) {
        if (signedEarlyReturn) {
          return false;
        }
      } else {
        if (signedEarlyReturn == false) {
          return false;
        }
      }

      statement += 1;
    }

    return true;
  }

  private ParsedScalarHelper parseScalarHelper(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long start
  ) {
    long visibility = tokenHash(source, tokenStarts, tokenLengths, start);
    if (visibility == TOKEN_PUBLIC) {} else {
      if (visibility == TOKEN_PRIVATE) {} else {
        return invalidHelper();
      }
    }

    long returnType = tokenHash(source, tokenStarts, tokenLengths, start + 1);
    long kind = HELPER_SIGNED_ONE;
    if (returnType == TOKEN_LONG) {} else {
      if (returnType == TOKEN_BOOLEAN) {
        kind = HELPER_BOOLEAN_SIGNED_ONE;
      } else {
        return invalidHelper();
      }
    }

    long nameToken = start + 2;
    long parameterToken = start + 5;
    if (tokenKinds[nameToken] == 1) {} else {
      return invalidHelper();
    }

    if (tokenKinds[parameterToken] == 1) {} else {
      return invalidHelper();
    }

    if (tokenLengths[nameToken] < 257) {} else {
      return invalidHelper();
    }

    if (tokenLengths[parameterToken] < 257) {} else {
      return invalidHelper();
    }

    if (classConstantNameExists(source, tokenStarts, tokenLengths, nameToken)) {
      return invalidHelper();
    }

    if (classConstantNameExists(source, tokenStarts, tokenLengths, parameterToken)) {
      return invalidHelper();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 3, PUNCTUATION_OPEN_PAREN)
    ) {} else {
      return invalidHelper();
    }

    if (tokenHash(source, tokenStarts, tokenLengths, start + 4) == TOKEN_LONG) {} else {
      return invalidHelper();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 6, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      return invalidHelper();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 7, PUNCTUATION_OPEN_BRACE)
    ) {} else {
      return invalidHelper();
    }

    BodyScan statements = scanBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      start + 8
    );
    if (statements.valid) {} else {
      return invalidHelper();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statements.end, PUNCTUATION_CLOSE_BRACE)
    ) {} else {
      return invalidHelper();
    }

    SourceRange callTarget = new SourceRange(0, 0);
    long callCount = 0;
    long sourceStatement = 0;
    while (sourceStatement < statements.count) limit MAX_MINIMAL_STATEMENTS {
      long sourceOpcode = statementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        statementStarts[sourceStatement]
      );
      boolean helperCall = sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED;
      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
        helperCall = true;
      }

      if (sourceOpcode == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
        helperCall = true;
      }

      if (helperCall) {
        long targetToken = statementStarts[sourceStatement] + 2;
        callTarget = new SourceRange(tokenStarts[targetToken], tokenLengths[targetToken]);
        callCount += 1;
      }

      sourceStatement += 1;
    }

    if (callCount < 2) {} else {
      return invalidHelper();
    }

    long shifted = statements.count;
    while (0 < shifted) limit MAX_MINIMAL_STATEMENTS {
      set(statementStarts, shifted, statementStarts[shifted - 1]);
      shifted -= 1;
    }

    set(statementStarts, 0, 0 - (nameToken + 3));
    StatementSequence sequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      statements.count
    );
    if (scalarSequenceValid(sequence, kind)) {} else {
      return invalidHelper();
    }

    HelperBody body = new HelperBody(
      new SourceRange(tokenStarts[nameToken], tokenLengths[nameToken]),
      sequence.opcodes,
      sequence.operands,
      sequence.secondaryOperands,
      kind,
      sequence.count,
      sequence.count - 1,
      callTarget,
      -1
    );
    return new ParsedScalarHelper(body, statements.end + 1, true);
  }

  private long compareHelpers(borrow utf8 source, HelperBody left, HelperBody right) {
    return compareAsciiSlices(
      source,
      left.name.start,
      left.name.length,
      right.name.start,
      right.name.length
    );
  }

  private HelperBody selectedBody(
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    long index
  ) {
    if (index == 0) {
      return first;
    }

    if (index == 1) {
      return second;
    }

    if (index == 2) {
      return third;
    }

    return fourth;
  }

  private long resolveCallFunction(
    borrow utf8 source,
    HelperBody caller,
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    long helperCount
  ) {
    if (caller.callTargetName.length == 0) {
      return -1;
    }

    long found = -1;
    long helper = 0;
    while (helper < helperCount) limit 4 {
      HelperBody candidate = selectedBody(first, second, third, fourth, helper);
      long order = compareAsciiSlices(
        source,
        caller.callTargetName.start,
        caller.callTargetName.length,
        candidate.name.start,
        candidate.name.length
      );
      if (order == 0) {
        if (candidate.kind == HELPER_BOOLEAN_SIGNED_ONE) {
          found = helper;
        }
      }

      helper += 1;
    }

    return found;
  }

  private HelperBody withCallFunction(HelperBody body, long callFunction) {
    return new HelperBody(
      body.name,
      body.opcodes,
      body.operands,
      body.secondaryOperands,
      body.kind,
      body.statementCount,
      body.resultStatement,
      body.callTargetName,
      callFunction
    );
  }

  /// Parses two through four scalar helpers in source declaration order.
  public MinimalProgramResult parseScalarHelperLibrary(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count,
    ClassLayout layout
  ) {
    if (layout.globalCount == 0) {} else {
      return new MinimalProgramResult.Error(0);
    }

    ParsedScalarHelper first = parseScalarHelper(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      layout.memberStart
    );
    if (first.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    ParsedScalarHelper second = parseScalarHelper(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      first.nextToken
    );
    if (second.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    long helperCount = 2;
    long classClose = second.nextToken;
    ParsedScalarHelper third = invalidHelper();
    ParsedScalarHelper fourth = invalidHelper();
    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      third = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (third.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 3;
      classClose = third.nextToken;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
      ) {
        fourth = parseScalarHelper(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          statementStarts,
          classClose
        );
        if (fourth.valid) {} else {
          return new MinimalProgramResult.Error(0);
        }

        helperCount = 4;
        classClose = fourth.nextToken;
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE)
    ) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (count == classClose + 1) {} else {
      return new MinimalProgramResult.Error(0);
    }

    HelperBody firstBody = first.body;
    HelperBody secondBody = second.body;
    HelperBody thirdBody = third.body;
    HelperBody fourthBody = fourth.body;
    if (compareHelpers(source, firstBody, secondBody) == 0) {
      return new MinimalProgramResult.Error(0);
    }

    if (2 < helperCount) {
      if (compareHelpers(source, firstBody, thirdBody) == 0) {
        return new MinimalProgramResult.Error(0);
      }

      if (compareHelpers(source, secondBody, thirdBody) == 0) {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (3 < helperCount) {
      if (compareHelpers(source, firstBody, fourthBody) == 0) {
        return new MinimalProgramResult.Error(0);
      }

      if (compareHelpers(source, secondBody, fourthBody) == 0) {
        return new MinimalProgramResult.Error(0);
      }

      if (compareHelpers(source, thirdBody, fourthBody) == 0) {
        return new MinimalProgramResult.Error(0);
      }
    }

    long firstCallFunction = resolveCallFunction(
      source,
      firstBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      helperCount
    );
    long secondCallFunction = resolveCallFunction(
      source,
      secondBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      helperCount
    );
    long thirdCallFunction = resolveCallFunction(
      source,
      thirdBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      helperCount
    );
    long fourthCallFunction = resolveCallFunction(
      source,
      fourthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      helperCount
    );
    if (0 < firstBody.callTargetName.length) {
      if (-1 < firstCallFunction) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (0 < secondBody.callTargetName.length) {
      if (-1 < secondCallFunction) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (2 < helperCount) {
      if (0 < thirdBody.callTargetName.length) {
        if (-1 < thirdCallFunction) {} else {
          return new MinimalProgramResult.Error(0);
        }
      }
    }

    if (3 < helperCount) {
      if (0 < fourthBody.callTargetName.length) {
        if (-1 < fourthCallFunction) {} else {
          return new MinimalProgramResult.Error(0);
        }
      }
    }

    firstBody = withCallFunction(firstBody, firstCallFunction);
    secondBody = withCallFunction(secondBody, secondCallFunction);
    thirdBody = withCallFunction(thirdBody, thirdCallFunction);
    fourthBody = withCallFunction(fourthBody, fourthCallFunction);

    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange absent = new SourceRange(0, 0);
    MinimalProgram program = new MinimalProgram(
      name,
      absent,
      0,
      0,
      0,
      emptyStatementOpcodes(),
      emptyStatementOperands(),
      emptyStatementOperands(),
      helperCount,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      absent,
      0,
      0,
      0,
      true
    );
    return new MinimalProgramResult.Value(program);
  }
}
