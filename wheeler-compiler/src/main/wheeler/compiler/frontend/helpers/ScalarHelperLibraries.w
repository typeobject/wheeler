//! Parses the first bounded entryless library with two scalar helpers.

module wheeler.compiler.scalar_helper_libraries;

import wheeler.compiler.class_constants;
import wheeler.compiler.class_layouts;
import wheeler.compiler.encoding;
import wheeler.compiler.ir;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.sequences;
import wheeler.compiler.statement_forms;
import wheeler.compiler.tokens;

classical class ScalarHelperLibraries {
  /// Defines one closed one-parameter scalar helper header.
  private record ScalarHelperHeader(
    long nameToken,
    long parameterToken,
    long returnStart,
    long nextToken,
    boolean valid
  ) {}

  private ScalarHelperHeader invalidHeader() {
    return new ScalarHelperHeader(0, 0, 0, 0, false);
  }

  private ScalarHelperHeader scalarIdentityHeader(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long start
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, start) == TOKEN_PUBLIC) {} else {
      return invalidHeader();
    }

    if (tokenHash(source, tokenStarts, tokenLengths, start + 1) == TOKEN_LONG) {} else {
      return invalidHeader();
    }

    long nameToken = start + 2;
    long parameterToken = start + 5;
    if (tokenKinds[nameToken] == 1) {} else {
      return invalidHeader();
    }

    if (tokenKinds[parameterToken] == 1) {} else {
      return invalidHeader();
    }

    if (tokenLengths[nameToken] < 257) {} else {
      return invalidHeader();
    }

    if (tokenLengths[parameterToken] < 257) {} else {
      return invalidHeader();
    }

    if (classConstantNameExists(source, tokenStarts, tokenLengths, nameToken)) {
      return invalidHeader();
    }

    if (classConstantNameExists(source, tokenStarts, tokenLengths, parameterToken)) {
      return invalidHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 3, PUNCTUATION_OPEN_PAREN)
    ) {} else {
      return invalidHeader();
    }

    if (tokenHash(source, tokenStarts, tokenLengths, start + 4) == TOKEN_LONG) {} else {
      return invalidHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 6, PUNCTUATION_CLOSE_PAREN)
    ) {} else {
      return invalidHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, start + 7, PUNCTUATION_OPEN_BRACE)
    ) {} else {
      return invalidHeader();
    }

    long returnStart = start + 8;
    if (
      statementOpcode(source, tokenStarts, tokenLengths, returnStart)
        == STATEMENT_RETURN_LOCAL_NAMED
    ) {} else {
      return invalidHeader();
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, parameterToken, returnStart + 1)
    ) {} else {
      return invalidHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, returnStart + 2, PUNCTUATION_SEMICOLON)
    ) {} else {
      return invalidHeader();
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, returnStart + 3, PUNCTUATION_CLOSE_BRACE)
    ) {} else {
      return invalidHeader();
    }

    return new ScalarHelperHeader(
      nameToken,
      parameterToken,
      returnStart,
      returnStart + 4,
      true
    );
  }

  private StatementSequence scalarIdentitySequence(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    ScalarHelperHeader header
  ) {
    set(statementStarts, 0, 0 - (header.nameToken + 3));
    set(statementStarts, 1, header.returnStart);
    return parseStatementSequence(source, tokenStarts, tokenLengths, statementStarts, 1);
  }

  private boolean orderedHelpers(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    ScalarHelperHeader left,
    ScalarHelperHeader right
  ) {
    return compareAsciiSlices(
      source,
      tokenStarts[left.nameToken],
      tokenLengths[left.nameToken],
      tokenStarts[right.nameToken],
      tokenLengths[right.nameToken]
    ) < 0;
  }

  private HelperBody scalarIdentityBody(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    ScalarHelperHeader header
  ) {
    StatementSequence sequence = scalarIdentitySequence(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      header
    );
    if (sequence.valid) {} else {
      return emptyHelperBody();
    }

    if (resolvedSignedLocalReturn(sequence.opcodes[0])) {} else {
      return emptyHelperBody();
    }

    if (resolvedLocalReturnSource(sequence.opcodes[0]) == 0) {} else {
      return emptyHelperBody();
    }

    return new HelperBody(
      new SourceRange(tokenStarts[header.nameToken], tokenLengths[header.nameToken]),
      sequence.opcodes,
      sequence.operands,
      sequence.secondaryOperands,
      HELPER_SIGNED_ONE,
      1,
      0
    );
  }

  /// Parses two through four sorted public scalar identity helpers.
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

    ScalarHelperHeader first = scalarIdentityHeader(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      layout.memberStart
    );
    if (first.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    ScalarHelperHeader second = scalarIdentityHeader(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      first.nextToken
    );
    if (second.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    long helperCount = 2;
    long classClose = second.nextToken;
    ScalarHelperHeader third = invalidHeader();
    ScalarHelperHeader fourth = invalidHeader();
    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      third = scalarIdentityHeader(source, tokenKinds, tokenStarts, tokenLengths, classClose);
      if (third.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 3;
      classClose = third.nextToken;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
      ) {
        fourth = scalarIdentityHeader(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
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

    if (orderedHelpers(source, tokenStarts, tokenLengths, first, second)) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (2 < helperCount) {
      if (orderedHelpers(source, tokenStarts, tokenLengths, second, third)) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (3 < helperCount) {
      if (orderedHelpers(source, tokenStarts, tokenLengths, third, fourth)) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    HelperBody firstBody = scalarIdentityBody(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      first
    );
    HelperBody secondBody = scalarIdentityBody(
      source,
      tokenStarts,
      tokenLengths,
      statementStarts,
      second
    );
    if (firstBody.statementCount == 1) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (secondBody.statementCount == 1) {} else {
      return new MinimalProgramResult.Error(0);
    }

    HelperBody thirdBody = emptyHelperBody();
    HelperBody fourthBody = emptyHelperBody();
    if (2 < helperCount) {
      thirdBody = scalarIdentityBody(source, tokenStarts, tokenLengths, statementStarts, third);
      if (thirdBody.statementCount == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (3 < helperCount) {
      fourthBody = scalarIdentityBody(
        source,
        tokenStarts,
        tokenLengths,
        statementStarts,
        fourth
      );
      if (fourthBody.statementCount == 1) {} else {
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
