//! Builds bounded entryless programs from parsed scalar helpers.

module wheeler.compiler.scalar_helper_programs;

import wheeler.compiler.class_layouts;
import wheeler.compiler.ir;
import wheeler.compiler.scalar_helper_parsing;
import wheeler.compiler.scalar_helper_tables;

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
    HelperBody eleventh,
    HelperBody twelfth,
    HelperBody thirteenth,
    HelperBody fourteenth,
    HelperBody fifteenth,
    HelperBody sixteenth,
    HelperBody seventeenth,
    HelperBody eighteenth,
    HelperBody nineteenth,
    HelperBody twentieth,
    HelperBody twentyFirst,
    HelperBody twentySecond,
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
      eleventh,
      twelfth,
      thirteenth,
      fourteenth,
      fifteenth,
      sixteenth,
      seventeenth,
      eighteenth,
      nineteenth,
      twentieth,
      twentyFirst,
      twentySecond,
      helperCount
    );
    return new ResolvedHelperBody(withCalls(body, calls), calls.valid);
  }

  /// Builds one resolved library from two through twenty-two scalar helpers.
  public MinimalProgramResult parseScalarHelperLibrary(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count,
    ClassLayout layout
  ) {
    ScalarHelperTable parsed = parseScalarHelpers(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      count,
      layout
    );
    if (parsed.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    long helperCount = parsed.helperCount;
    HelperBody firstBody = parsed.first;
    HelperBody secondBody = parsed.second;
    HelperBody thirdBody = parsed.third;
    HelperBody fourthBody = parsed.fourth;
    HelperBody fifthBody = parsed.fifth;
    HelperBody sixthBody = parsed.sixth;
    HelperBody seventhBody = parsed.seventh;
    HelperBody eighthBody = parsed.eighth;
    HelperBody ninthBody = parsed.ninth;
    HelperBody tenthBody = parsed.tenth;
    HelperBody eleventhBody = parsed.eleventh;
    HelperBody twelfthBody = parsed.twelfth;
    HelperBody thirteenthBody = parsed.thirteenth;
    HelperBody fourteenthBody = parsed.fourteenth;
    HelperBody fifteenthBody = parsed.fifteenth;
    HelperBody sixteenthBody = parsed.sixteenth;
    HelperBody seventeenthBody = parsed.seventeenth;
    HelperBody eighteenthBody = parsed.eighteenth;
    HelperBody nineteenthBody = parsed.nineteenth;
    HelperBody twentiethBody = parsed.twentieth;
    HelperBody twentyFirstBody = parsed.twentyFirst;
    HelperBody twentySecondBody = parsed.twentySecond;
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
        eleventhBody,
        twelfthBody,
        thirteenthBody,
        fourteenthBody,
        fifteenthBody,
        sixteenthBody,
        seventeenthBody,
        eighteenthBody,
        nineteenthBody,
        twentiethBody,
        twentyFirstBody,
        twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody eleventhResolved = resolvedHelperBody(
      source,
      eleventhBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody twelfthResolved = resolvedHelperBody(
      source,
      twelfthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody thirteenthResolved = resolvedHelperBody(
      source,
      thirteenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody fourteenthResolved = resolvedHelperBody(
      source,
      fourteenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody fifteenthResolved = resolvedHelperBody(
      source,
      fifteenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody sixteenthResolved = resolvedHelperBody(
      source,
      sixteenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody seventeenthResolved = resolvedHelperBody(
      source,
      seventeenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody eighteenthResolved = resolvedHelperBody(
      source,
      eighteenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody nineteenthResolved = resolvedHelperBody(
      source,
      nineteenthBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody twentiethResolved = resolvedHelperBody(
      source,
      twentiethBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody twentyFirstResolved = resolvedHelperBody(
      source,
      twentyFirstBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      helperCount
    );
    ResolvedHelperBody twentySecondResolved = resolvedHelperBody(
      source,
      twentySecondBody,
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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
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

    if (10 < helperCount) {
      if (eleventhResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (11 < helperCount) {
      if (twelfthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (12 < helperCount) {
      if (thirteenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (13 < helperCount) {
      if (fourteenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (14 < helperCount) {
      if (fifteenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (15 < helperCount) {
      if (sixteenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (16 < helperCount) {
      if (seventeenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (17 < helperCount) {
      if (eighteenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (18 < helperCount) {
      if (nineteenthResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (19 < helperCount) {
      if (twentiethResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (20 < helperCount) {
      if (twentyFirstResolved.valid) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (21 < helperCount) {
      if (twentySecondResolved.valid) {} else {
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
    eleventhBody = eleventhResolved.body;
    twelfthBody = twelfthResolved.body;
    thirteenthBody = thirteenthResolved.body;
    fourteenthBody = fourteenthResolved.body;
    fifteenthBody = fifteenthResolved.body;
    sixteenthBody = sixteenthResolved.body;
    seventeenthBody = seventeenthResolved.body;
    eighteenthBody = eighteenthResolved.body;
    nineteenthBody = nineteenthResolved.body;
    twentiethBody = twentiethResolved.body;
    twentyFirstBody = twentyFirstResolved.body;
    twentySecondBody = twentySecondResolved.body;

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
      eleventhBody,
      twelfthBody,
      thirteenthBody,
      fourteenthBody,
      fifteenthBody,
      sixteenthBody,
      seventeenthBody,
      eighteenthBody,
      nineteenthBody,
      twentiethBody,
      twentyFirstBody,
      twentySecondBody,
      absent,
      0,
      0,
      0,
      true
    );
    return new MinimalProgramResult.Value(program);
  }
}
