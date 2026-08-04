//! Parses bounded entryless libraries with several scalar helpers.

module wheeler.compiler.scalar_helper_libraries;

import wheeler.compiler.body_parser;
import wheeler.compiler.class_constants;
import wheeler.compiler.class_layouts;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.sequences;
import wheeler.compiler.statement_forms;
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
      if (resolvedEarlyBooleanReturn(sequence.opcodes[statement])) {} else {
        return false;
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
    if (tokenHash(source, tokenStarts, tokenLengths, start) == TOKEN_PUBLIC) {} else {
      return invalidHelper();
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
      sequence.count - 1
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
