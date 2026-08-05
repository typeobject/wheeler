//! Builds bounded entryless programs from resolved scalar helpers.

module wheeler.compiler.scalar_helper_programs;

import wheeler.compiler.class_layouts;
import wheeler.compiler.ir;
import wheeler.compiler.scalar_helper_parsing;
import wheeler.compiler.scalar_helper_resolution;

classical class ScalarHelperPrograms {
  /// Builds one resolved library from two through twenty-three scalar helpers.
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
    ResolvedScalarHelperTable resolved = resolveScalarHelperTable(source, parsed);
    if (resolved.valid) {} else {
      return new MinimalProgramResult.Error(0);
    }

    long helperCount = resolved.helperCount;
    HelperBody firstBody = resolved.first;
    HelperBody secondBody = resolved.second;
    HelperBody thirdBody = resolved.third;
    HelperBody fourthBody = resolved.fourth;
    HelperBody fifthBody = resolved.fifth;
    HelperBody sixthBody = resolved.sixth;
    HelperBody seventhBody = resolved.seventh;
    HelperBody eighthBody = resolved.eighth;
    HelperBody ninthBody = resolved.ninth;
    HelperBody tenthBody = resolved.tenth;
    HelperBody eleventhBody = resolved.eleventh;
    HelperBody twelfthBody = resolved.twelfth;
    HelperBody thirteenthBody = resolved.thirteenth;
    HelperBody fourteenthBody = resolved.fourteenth;
    HelperBody fifteenthBody = resolved.fifteenth;
    HelperBody sixteenthBody = resolved.sixteenth;
    HelperBody seventeenthBody = resolved.seventeenth;
    HelperBody eighteenthBody = resolved.eighteenth;
    HelperBody nineteenthBody = resolved.nineteenth;
    HelperBody twentiethBody = resolved.twentieth;
    HelperBody twentyFirstBody = resolved.twentyFirst;
    HelperBody twentySecondBody = resolved.twentySecond;
    HelperBody twentyThirdBody = resolved.twentyThird;
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
      twentyThirdBody,
      absent,
      0,
      0,
      0,
      true
    );
    return new MinimalProgramResult.Value(program);
  }
}
