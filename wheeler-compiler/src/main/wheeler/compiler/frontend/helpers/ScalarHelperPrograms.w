//! Builds bounded entryless programs from parsed scalar helpers.

module wheeler.compiler.scalar_helper_programs;

import wheeler.compiler.class_layouts;
import wheeler.compiler.ir;
import wheeler.compiler.scalar_helper_libraries;
import wheeler.compiler.scalar_helper_tables;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ScalarHelperPrograms {
  /// Carries one helper after bounded call resolution.
  private record ResolvedHelperBody(HelperBody body, boolean valid) {}

  private ResolvedHelperBody resolvedHelperBody(
    borrow utf8 source,
    HelperBody body,
    HelperBody first,
    HelperBody second,
    HelperBody third,
    HelperBody fourth,
    HelperBody fifth,
    HelperBody sixth,
    HelperBody seventh,
    HelperBody eighth,
    HelperBody ninth,
    HelperBody tenth,
    long helperCount
  ) {
    ResolvedCalls calls = resolveCalls(
      source,
      body,
      first,
      second,
      third,
      fourth,
      fifth,
      sixth,
      seventh,
      eighth,
      ninth,
      tenth,
      helperCount
    );
    return new ResolvedHelperBody(withCalls(body, calls), calls.valid);
  }

  /// Parses two through ten scalar helpers in source declaration order.
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
    ParsedScalarHelper fifth = invalidHelper();
    ParsedScalarHelper sixth = invalidHelper();
    ParsedScalarHelper seventh = invalidHelper();
    ParsedScalarHelper eighth = invalidHelper();
    ParsedScalarHelper ninth = invalidHelper();
    ParsedScalarHelper tenth = invalidHelper();
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
    }

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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      fifth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (fifth.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 5;
      classClose = fifth.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      sixth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (sixth.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 6;
      classClose = sixth.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      seventh = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (seventh.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 7;
      classClose = seventh.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      eighth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (eighth.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 8;
      classClose = eighth.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      ninth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (ninth.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 9;
      classClose = ninth.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      tenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (tenth.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }

      helperCount = 10;
      classClose = tenth.nextToken;
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
    HelperBody fifthBody = fifth.body;
    HelperBody sixthBody = sixth.body;
    HelperBody seventhBody = seventh.body;
    HelperBody eighthBody = eighth.body;
    HelperBody ninthBody = ninth.body;
    HelperBody tenthBody = tenth.body;
    if (
      uniqueHelpers(
        source,
        firstBody,
        secondBody,
        thirdBody,
        fourthBody,
        fifthBody,
        sixthBody,
        seventhBody,
        eighthBody,
        ninthBody,
        tenthBody,
        helperCount
      )
    ) {} else {
      return new MinimalProgramResult.Error(0);
    }

    ResolvedHelperBody firstResolved = resolvedHelperBody(
      source,
      firstBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody secondResolved = resolvedHelperBody(
      source,
      secondBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody thirdResolved = resolvedHelperBody(
      source,
      thirdBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody fourthResolved = resolvedHelperBody(
      source,
      fourthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody fifthResolved = resolvedHelperBody(
      source,
      fifthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody sixthResolved = resolvedHelperBody(
      source,
      sixthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody seventhResolved = resolvedHelperBody(
      source,
      seventhBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody eighthResolved = resolvedHelperBody(
      source,
      eighthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody ninthResolved = resolvedHelperBody(
      source,
      ninthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    ResolvedHelperBody tenthResolved = resolvedHelperBody(
      source,
      tenthBody,
      firstBody,
      secondBody,
      thirdBody,
      fourthBody,
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      helperCount
    );
    if (firstResolved.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (secondResolved.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (2 < helperCount) {
      if (thirdResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (3 < helperCount) {
      if (fourthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (4 < helperCount) {
      if (fifthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (5 < helperCount) {
      if (sixthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (6 < helperCount) {
      if (seventhResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (7 < helperCount) {
      if (eighthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (8 < helperCount) {
      if (ninthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (9 < helperCount) {
      if (tenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    firstBody = firstResolved.body;
    secondBody = secondResolved.body;
    thirdBody = thirdResolved.body;
    fourthBody = fourthResolved.body;
    fifthBody = fifthResolved.body;
    sixthBody = sixthResolved.body;
    seventhBody = seventhResolved.body;
    eighthBody = eighthResolved.body;
    ninthBody = ninthResolved.body;
    tenthBody = tenthResolved.body;

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
      fifthBody,
      sixthBody,
      seventhBody,
      eighthBody,
      ninthBody,
      tenthBody,
      absent,
      0,
      0,
      0,
      true
    );
    return new MinimalProgramResult.Value(program);
  }
}
