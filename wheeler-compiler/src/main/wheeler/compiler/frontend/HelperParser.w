//! Parses helper functions in the bounded bootstrap source profile.

module wheeler.compiler.helper_parser;

import wheeler.compiler.ir;
import wheeler.compiler.sequences;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class HelperParser {
  private boolean callValid(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    long callStart
  ) {
    if (sameTokenText(source, tokenStarts, tokenLengths, nameToken, callStart)) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, callStart + 1, PUNCTUATION_OPEN_PAREN)
      ) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            callStart + 2,
            PUNCTUATION_CLOSE_PAREN
          )
        ) {
          return punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            callStart + 3,
            PUNCTUATION_SEMICOLON
          );
        }
      }
    }

    return false;
  }

  private MinimalProgramResult helperProgram(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    long reversible,
    long proofToken,
    long proofCount,
    long entryStatement,
    long helperCallCount,
    long preReverseStatement,
    long[8] helperStarts,
    long helperStatementCount
  ) {
    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(tokenStarts[6], tokenLengths[6]);
    SourceRange helper = new SourceRange(tokenStarts[nameToken], tokenLengths[nameToken]);
    SourceRange proof = new SourceRange(0, 0);
    if (proofCount == 1) {
      proof = new SourceRange(tokenStarts[proofToken], tokenLengths[proofToken]);
    }

    StatementSequence helperSequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      helperStarts,
      helperStatementCount
    );
    if (helperSequence.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (reversible == 1) {
      if (reversibleSequenceValid(helperSequence) == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    long entryCount = 0;
    long entryFirst = -1;
    long entrySecond = -1;
    long preReverseCount = 0;
    if (-1 < preReverseStatement) {
      entryCount = 1;
      preReverseCount = 1;
      entryFirst = preReverseStatement;
    }

    if (-1 < entryStatement) {
      if (entryCount == 0) {
        entryCount = 1;
        entryFirst = entryStatement;
      } else {
        entryCount = 2;
        entrySecond = entryStatement;
      }
    }

    long[8] entryStarts = new long[8](entryFirst, entrySecond, -1, -1, -1, -1, -1, -1);
    StatementSequence entrySequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      entryStarts,
      entryCount
    );
    if (entrySequence.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    MinimalProgram program = new MinimalProgram(
      name,
      global,
      1,
      parsedSignedNumber(source, tokenStarts, tokenLengths, 8),
      entrySequence.count,
      entrySequence.opcodes,
      entrySequence.operands,
      helper,
      1,
      helperSequence.opcodes,
      helperSequence.operands,
      reversible,
      proof,
      proofCount,
      helperCallCount,
      preReverseCount,
      helperSequence.count
    );
    return new MinimalProgramResult.Value(program);
  }

  private MinimalProgramResult finishEntry(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count,
    long closeStart,
    long nameToken,
    long reversible,
    long proofToken,
    long proofCount,
    long helperCallCount,
    long preReverseStatement,
    long[8] helperStarts,
    long helperStatementCount
  ) {
    long entryStatement = -1;
    long entryClose = closeStart;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, entryClose, PUNCTUATION_CLOSE_BRACE)
    ) {
      entryClose = closeStart;
    } else {
      long entryWidth = statementWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        closeStart
      );
      if (entryWidth < 1) {
        return new MinimalProgramResult.Error(0);
      }

      entryStatement = closeStart;
      entryClose += entryWidth;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, entryClose, PUNCTUATION_CLOSE_BRACE)
    ) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, entryClose + 1, PUNCTUATION_CLOSE_BRACE)
      ) {
        if (count == entryClose + 2) {
          return helperProgram(
            source,
            tokenStarts,
            tokenLengths,
            nameToken,
            reversible,
            proofToken,
            proofCount,
            entryStatement,
            helperCallCount,
            preReverseStatement,
            helperStarts,
            helperStatementCount
          );
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

  private record HelperStatements(long end, long count, long[8] starts, boolean valid) {}

  private record ProofHeader(long entryStart, long token, long count) {}

  private HelperStatements helperStatements(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long body
  ) {
    long[8] absent = new long[8](-1, -1, -1, -1, -1, -1, -1, -1);
    long firstWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, body);
    if (firstWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long firstEnd = body + firstWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, firstEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        firstEnd,
        1,
        new long[8](body, -1, -1, -1, -1, -1, -1, -1),
        true
      );
    }

    long secondWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, firstEnd);
    if (secondWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long secondEnd = firstEnd + secondWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, secondEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        secondEnd,
        2,
        new long[8](body, firstEnd, -1, -1, -1, -1, -1, -1),
        true
      );
    }

    long thirdWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, secondEnd);
    if (thirdWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long thirdEnd = secondEnd + thirdWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, thirdEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        thirdEnd,
        3,
        new long[8](body, firstEnd, secondEnd, -1, -1, -1, -1, -1),
        true
      );
    }

    long fourthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, thirdEnd);
    if (fourthWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long fourthEnd = thirdEnd + fourthWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, fourthEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        fourthEnd,
        4,
        new long[8](body, firstEnd, secondEnd, thirdEnd, -1, -1, -1, -1),
        true
      );
    }

    long fifthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, fourthEnd);
    if (fifthWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long fifthEnd = fourthEnd + fifthWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, fifthEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        fifthEnd,
        5,
        new long[8](body, firstEnd, secondEnd, thirdEnd, fourthEnd, -1, -1, -1),
        true
      );
    }

    long sixthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, fifthEnd);
    if (sixthWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long sixthEnd = fifthEnd + sixthWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, sixthEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        sixthEnd,
        6,
        new long[8](body, firstEnd, secondEnd, thirdEnd, fourthEnd, fifthEnd, -1, -1),
        true
      );
    }

    long seventhWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, sixthEnd);
    if (seventhWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long seventhEnd = sixthEnd + seventhWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, seventhEnd, PUNCTUATION_CLOSE_BRACE)
    ) {
      return new HelperStatements(
        seventhEnd,
        7,
        new long[8](body, firstEnd, secondEnd, thirdEnd, fourthEnd, fifthEnd, sixthEnd, -1),
        true
      );
    }

    long eighthWidth = statementWidth(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      seventhEnd
    );
    if (eighthWidth < 1) {
      return new HelperStatements(-1, 0, absent, false);
    }

    long[8] eighthStarts = new long[8](
      body,
      firstEnd,
      secondEnd,
      thirdEnd,
      fourthEnd,
      fifthEnd,
      sixthEnd,
      seventhEnd
    );
    return new HelperStatements(seventhEnd + eighthWidth, 8, eighthStarts, true);
  }

  private ProofHeader proofHeader(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long entryStart,
    long nameToken,
    long reversible
  ) {
    ProofHeader absent = new ProofHeader(entryStart, -1, 0);
    if (reversible == 0) {
      return absent;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, entryStart) == TOKEN_THEOREM) {} else {
      return absent;
    }

    if (tokenKinds[entryStart + 1] == 1) {} else {
      return absent;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, entryStart + 2) == TOKEN_PROVES) {} else {
      return absent;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, entryStart + 3) == TOKEN_INVERSE) {} else {
      return absent;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, entryStart + 4, PUNCTUATION_OPEN_PAREN)
        == false
    ) {
      return absent;
    }

    if (
      sameTokenText(source, tokenStarts, tokenLengths, nameToken, entryStart + 5) == false
    ) {
      return absent;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, entryStart + 6, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return absent;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, entryStart + 7, PUNCTUATION_SEMICOLON) == false
    ) {
      return absent;
    }

    return new ProofHeader(entryStart + 8, entryStart + 1, 1);
  }

  /// Parses helper and entry declarations from the bounded compiler source profile.
  public MinimalProgramResult parseHelperProgram(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count
  ) {
    long memberStart = minimalEntryStart(source, tokenKinds, tokenStarts, tokenLengths);
    if (memberStart < 1) {
      return new MinimalProgramResult.Error(0);
    }

    long reversible = 0;
    long voidToken = memberStart;
    if (tokenHash(source, tokenStarts, tokenLengths, memberStart) == TOKEN_REV) {
      reversible = 1;
      voidToken += 1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, voidToken) == TOKEN_VOID) {} else {
      return new MinimalProgramResult.Error(0);
    }

    long nameToken = voidToken + 1;
    if (tokenKinds[nameToken] == 1) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (tokenLengths[nameToken] < 257) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, nameToken + 1, PUNCTUATION_OPEN_PAREN) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, nameToken + 2, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, nameToken + 3, PUNCTUATION_OPEN_BRACE) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long helperBody = nameToken + 4;
    HelperStatements statements = helperStatements(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      helperBody
    );
    if (statements.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statements.end, PUNCTUATION_CLOSE_BRACE)
        == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    ProofHeader proof = proofHeader(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statements.end + 1,
      nameToken,
      reversible
    );
    long entryBody = minimalBodyStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      proof.entryStart
    );
    if (entryBody < 1) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      callValid(source, tokenKinds, tokenStarts, tokenLengths, nameToken, entryBody) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long helperCallCount = 1;
    long afterCalls = entryBody + 4;
    if (
      callValid(source, tokenKinds, tokenStarts, tokenLengths, nameToken, afterCalls)
    ) {
      helperCallCount = 2;
      afterCalls += 4;
    }

    long preReverseStatement = -1;
    if (reversible == 1) {
      long reverseHash = tokenHash(source, tokenStarts, tokenLengths, afterCalls);
      if (reverseHash == TOKEN_REVERSE) {} else {
        long preReverseWidth = statementWidth(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          afterCalls
        );
        if (preReverseWidth < 1) {
          return new MinimalProgramResult.Error(0);
        }

        preReverseStatement = afterCalls;
        afterCalls += preReverseWidth;
      }
    }

    if (reversible == 0) {
      return finishEntry(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        count,
        afterCalls,
        nameToken,
        reversible,
        proof.token,
        proof.count,
        helperCallCount,
        -1,
        statements.starts,
        statements.count
      );
    }

    if (tokenHash(source, tokenStarts, tokenLengths, afterCalls) == TOKEN_REVERSE) {} else {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, afterCalls + 1, PUNCTUATION_OPEN_BRACE)
        == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long reverseCall = afterCalls + 2;
    if (
      callValid(source, tokenKinds, tokenStarts, tokenLengths, nameToken, reverseCall) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long reverseEnd = reverseCall + 4;
    if (helperCallCount == 2) {
      if (
        callValid(source, tokenKinds, tokenStarts, tokenLengths, nameToken, reverseEnd) == false
      ) {
        return new MinimalProgramResult.Error(0);
      }

      reverseEnd += 4;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, reverseEnd, PUNCTUATION_CLOSE_BRACE) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    return finishEntry(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      count,
      reverseEnd + 1,
      nameToken,
      reversible,
      proof.token,
      proof.count,
      helperCallCount,
      preReverseStatement,
      statements.starts,
      statements.count
    );
  }
}
