//! Resolves calls in complete bounded scalar helper tables.

module wheeler.compiler.scalar_helper_resolution;

import wheeler.compiler.ir;
import wheeler.compiler.scalar_helper_call_resolution;
import wheeler.compiler.scalar_helper_parsing;
import wheeler.compiler.scalar_helper_tables;

classical class ScalarHelperResolution {
  /// Carries one complete scalar helper table after call resolution.
  public record ResolvedScalarHelperTable(
    long helperCount,
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
    boolean valid
  ) {}

  private ResolvedScalarHelperTable invalidResolvedTable() {
    return new ResolvedScalarHelperTable(
      0,
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      emptyHelperBody(),
      false
    );
  }

  /// Resolves every bounded helper call without publishing a partial table.
  public ResolvedScalarHelperTable resolveScalarHelperTable(
    borrow utf8 source,
    ScalarHelperTable parsed
  ) {
    if (parsed.valid) {} else {
      return invalidResolvedTable();
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
      return invalidResolvedTable();
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
      return invalidResolvedTable();
    }

    if (secondResolved.valid) {} else {
      return invalidResolvedTable();
    }

    if (2 < helperCount) {
      if (thirdResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (3 < helperCount) {
      if (fourthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (4 < helperCount) {
      if (fifthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (5 < helperCount) {
      if (sixthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (6 < helperCount) {
      if (seventhResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (7 < helperCount) {
      if (eighthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (8 < helperCount) {
      if (ninthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (9 < helperCount) {
      if (tenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (10 < helperCount) {
      if (eleventhResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (11 < helperCount) {
      if (twelfthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (12 < helperCount) {
      if (thirteenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (13 < helperCount) {
      if (fourteenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (14 < helperCount) {
      if (fifteenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (15 < helperCount) {
      if (sixteenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (16 < helperCount) {
      if (seventeenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (17 < helperCount) {
      if (eighteenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (18 < helperCount) {
      if (nineteenthResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (19 < helperCount) {
      if (twentiethResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (20 < helperCount) {
      if (twentyFirstResolved.valid) {} else {
        return invalidResolvedTable();
      }
    }

    if (21 < helperCount) {
      if (twentySecondResolved.valid) {} else {
        return invalidResolvedTable();
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

    return new ResolvedScalarHelperTable(
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
      true
    );
  }
}
