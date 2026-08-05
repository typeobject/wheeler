//! Parses complete bounded scalar helper tables.

module wheeler.compiler.scalar_helper_parsing;

import wheeler.compiler.class_layouts;
import wheeler.compiler.ir;
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
      false
    );
  }

  /// Parses two through sixteen scalar helper declarations in source order.
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

    ParsedScalarHelper second = parseScalarHelper(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      first.nextToken
    );
    if (second.valid) {} else {
      return invalidTable();
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
    ParsedScalarHelper eleventh = invalidHelper();
    ParsedScalarHelper twelfth = invalidHelper();
    ParsedScalarHelper thirteenth = invalidHelper();
    ParsedScalarHelper fourteenth = invalidHelper();
    ParsedScalarHelper fifteenth = invalidHelper();
    ParsedScalarHelper sixteenth = invalidHelper();
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
        return invalidTable();
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
        return invalidTable();
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
        return invalidTable();
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
        return invalidTable();
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
        return invalidTable();
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
        return invalidTable();
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
        return invalidTable();
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
        return invalidTable();
      }

      helperCount = 10;
      classClose = tenth.nextToken;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE) == false
    ) {
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

    if (
      punctuationAt(source, tokenKinds, tokenStarts, classClose, PUNCTUATION_CLOSE_BRACE)
    ) {} else {
      return invalidTable();
    }

    if (count == classClose + 1) {} else {
      return invalidTable();
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
      true
    );
  }
}
