//! Parses complete bounded scalar helper tables.

module wheeler.compiler.scalar_helper_parsing;

import wheeler.compiler.class_layouts;
import wheeler.compiler.ir;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.scalar_helper_libraries;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class ScalarHelperParsing {
  /// Carries one complete parsed scalar helper table.
  public record ScalarHelperTable(
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
    HelperBody twentyThird,
    long nextToken,
    boolean valid
  ) {}

  private ScalarHelperTable invalidTable() {
    return new ScalarHelperTable(
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
      emptyHelperBody(),
      0,
      false
    );
  }

  private boolean scalarHelperStartsAt(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long token
  ) {
    long declaration = token;
    long first = tokenHash(source, tokenStarts, tokenLengths, declaration);
    if (first == TOKEN_PUBLIC) {
      declaration += 1;
    } else {
      if (first == TOKEN_PRIVATE) {
        declaration += 1;
      }
    }

    if (tokenHash(source, tokenStarts, tokenLengths, declaration) == TOKEN_REV) {
      declaration += 1;
    }

    long result = tokenHash(source, tokenStarts, tokenLengths, declaration);
    if (result == TOKEN_VOID) {
      return true;
    }

    if (result == TOKEN_LONG) {
      return true;
    }

    return result == TOKEN_BOOLEAN;
  }

  /// Parses one through twenty-three scalar helper declarations in source order.
  public ScalarHelperTable parseScalarHelpers(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words statementStarts,
    long count,
    ClassLayout layout
  ) {
    if (layout.globalCount == 0) {} else {
      return invalidTable();
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
      return invalidTable();
    }

    long helperCount = 1;
    long classClose = first.nextToken;
    ParsedScalarHelper second = invalidHelper();
    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      second = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (second.valid) {} else {
        return invalidTable();
      }

      helperCount = 2;
      classClose = second.nextToken;
    }

    ParsedScalarHelper third = invalidHelper();
    ParsedScalarHelper fourth = invalidHelper();
    ParsedScalarHelper fifth = invalidHelper();
    ParsedScalarHelper sixth = invalidHelper();
    ParsedScalarHelper seventh = invalidHelper();
    ParsedScalarHelper eighth = invalidHelper();
    ParsedScalarHelper ninth = invalidHelper();
    ParsedScalarHelper tenth = invalidHelper();
    ParsedScalarHelper eleventh = invalidHelper();
    ParsedScalarHelper twelfth = invalidHelper();
    ParsedScalarHelper thirteenth = invalidHelper();
    ParsedScalarHelper fourteenth = invalidHelper();
    ParsedScalarHelper fifteenth = invalidHelper();
    ParsedScalarHelper sixteenth = invalidHelper();
    ParsedScalarHelper seventeenth = invalidHelper();
    ParsedScalarHelper eighteenth = invalidHelper();
    ParsedScalarHelper nineteenth = invalidHelper();
    ParsedScalarHelper twentieth = invalidHelper();
    ParsedScalarHelper twentyFirst = invalidHelper();
    ParsedScalarHelper twentySecond = invalidHelper();
    ParsedScalarHelper twentyThird = invalidHelper();
    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      third = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (third.valid) {} else {
        return invalidTable();
      }

      helperCount = 3;
      classClose = third.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      fourth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (fourth.valid) {} else {
        return invalidTable();
      }

      helperCount = 4;
      classClose = fourth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      fifth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (fifth.valid) {} else {
        return invalidTable();
      }

      helperCount = 5;
      classClose = fifth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      sixth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (sixth.valid) {} else {
        return invalidTable();
      }

      helperCount = 6;
      classClose = sixth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      seventh = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (seventh.valid) {} else {
        return invalidTable();
      }

      helperCount = 7;
      classClose = seventh.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      eighth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (eighth.valid) {} else {
        return invalidTable();
      }

      helperCount = 8;
      classClose = eighth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      ninth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (ninth.valid) {} else {
        return invalidTable();
      }

      helperCount = 9;
      classClose = ninth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      tenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (tenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 10;
      classClose = tenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      eleventh = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (eleventh.valid) {} else {
        return invalidTable();
      }

      helperCount = 11;
      classClose = eleventh.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      twelfth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (twelfth.valid) {} else {
        return invalidTable();
      }

      helperCount = 12;
      classClose = twelfth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      thirteenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (thirteenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 13;
      classClose = thirteenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      fourteenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (fourteenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 14;
      classClose = fourteenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      fifteenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (fifteenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 15;
      classClose = fifteenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      sixteenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (sixteenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 16;
      classClose = sixteenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      seventeenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (seventeenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 17;
      classClose = seventeenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      eighteenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (eighteenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 18;
      classClose = eighteenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      nineteenth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (nineteenth.valid) {} else {
        return invalidTable();
      }

      helperCount = 19;
      classClose = nineteenth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      twentieth = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (twentieth.valid) {} else {
        return invalidTable();
      }

      helperCount = 20;
      classClose = twentieth.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      twentyFirst = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (twentyFirst.valid) {} else {
        return invalidTable();
      }

      helperCount = 21;
      classClose = twentyFirst.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      twentySecond = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (twentySecond.valid) {} else {
        return invalidTable();
      }

      helperCount = 22;
      classClose = twentySecond.nextToken;
    }

    if (scalarHelperStartsAt(source, tokenStarts, tokenLengths, classClose)) {
      twentyThird = parseScalarHelper(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStarts,
        classClose
      );
      if (twentyThird.valid) {} else {
        return invalidTable();
      }

      helperCount = 23;
      classClose = twentyThird.nextToken;
    }

    boolean library = punctuationAt(
      source,
      tokenKinds,
      tokenStarts,
      classClose,
      PUNCTUATION_CLOSE_BRACE
    );
    if (library) {
      if (count == classClose + 1) {} else {
        return invalidTable();
      }
    } else {
      if (tokenHash(source, tokenStarts, tokenLengths, classClose) == TOKEN_ENTRY) {} else {
        return invalidTable();
      }
    }

    return new ScalarHelperTable(
      helperCount,
      first.body,
      second.body,
      third.body,
      fourth.body,
      fifth.body,
      sixth.body,
      seventh.body,
      eighth.body,
      ninth.body,
      tenth.body,
      eleventh.body,
      twelfth.body,
      thirteenth.body,
      fourteenth.body,
      fifteenth.body,
      sixteenth.body,
      seventeenth.body,
      eighteenth.body,
      nineteenth.body,
      twentieth.body,
      twentyFirst.body,
      twentySecond.body,
      twentyThird.body,
      classClose,
      true
    );
  }
}
