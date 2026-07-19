//! Parses helper functions in the bounded bootstrap source profile.

module wheeler.compiler.helper_parser;

import wheeler.compiler.ir;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class HelperParser {
  private boolean reversibleBodyValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_UPDATE_ADD) {
      return true;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return true;
    }

    return opcode == STATEMENT_UPDATE_XOR;
  }

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
    long helperBody,
    long reversible,
    long proofToken,
    long proofCount,
    long entryStatement,
    long helperCallCount,
    long preReverseStatement,
    long helperSecondStatement,
    long helperThirdStatement,
    long helperFourthStatement
  ) {
    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(tokenStarts[6], tokenLengths[6]);
    SourceRange helper = new SourceRange(tokenStarts[nameToken], tokenLengths[nameToken]);
    SourceRange proof = new SourceRange(0, 0);
    if (proofCount == 1) {
      proof = new SourceRange(tokenStarts[proofToken], tokenLengths[proofToken]);
    }

    long helperOpcode = statementOpcode(source, tokenStarts, tokenLengths, helperBody);
    long helperOperand = sequenceStatementOperand(
      source,
      tokenStarts,
      tokenLengths,
      helperBody,
      -1,
      -1,
      -1,
      -1
    );
    long helperStatementCount = 1;
    long helperSecondOpcode = -1;
    long helperSecondOperand = 0;
    long helperThirdOpcode = -1;
    long helperThirdOperand = 0;
    long helperFourthOpcode = -1;
    long helperFourthOperand = 0;
    if (-1 < helperSecondStatement) {
      helperStatementCount = 2;
      helperSecondOpcode = statementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        helperSecondStatement
      );
      helperSecondOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        helperSecondStatement,
        helperBody,
        -1,
        -1,
        -1
      );
    }

    if (-1 < helperThirdStatement) {
      helperStatementCount = 3;
      helperThirdOpcode = statementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        helperThirdStatement
      );
      helperThirdOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        helperThirdStatement,
        helperBody,
        helperSecondStatement,
        -1,
        -1
      );
    }

    if (-1 < helperFourthStatement) {
      helperStatementCount = 4;
      helperFourthOpcode = statementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        helperFourthStatement
      );
      helperFourthOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        helperFourthStatement,
        helperBody,
        helperSecondStatement,
        helperThirdStatement,
        -1
      );
    }

    long entryCount = 0;
    long entryOpcode = -1;
    long entryOperand = 0;
    long secondEntryOpcode = -1;
    long secondEntryOperand = 0;
    long preReverseCount = 0;
    if (-1 < preReverseStatement) {
      entryCount = 1;
      preReverseCount = 1;
      entryOpcode = statementOpcode(source, tokenStarts, tokenLengths, preReverseStatement);
      entryOperand = sequenceStatementOperand(
        source,
        tokenStarts,
        tokenLengths,
        preReverseStatement,
        -1,
        -1,
        -1,
        -1
      );
    }

    if (-1 < entryStatement) {
      if (entryCount == 0) {
        entryCount = 1;
        entryOpcode = statementOpcode(source, tokenStarts, tokenLengths, entryStatement);
        entryOperand = sequenceStatementOperand(
          source,
          tokenStarts,
          tokenLengths,
          entryStatement,
          -1,
          -1,
          -1,
          -1
        );
      } else {
        entryCount = 2;
        secondEntryOpcode = statementOpcode(source, tokenStarts, tokenLengths, entryStatement);
        secondEntryOperand = sequenceStatementOperand(
          source,
          tokenStarts,
          tokenLengths,
          entryStatement,
          preReverseStatement,
          -1,
          -1,
          -1
        );
      }
    }

    if (sequenceOperandValid(helperOpcode, helperOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(helperSecondOpcode, helperSecondOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(helperThirdOpcode, helperThirdOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(helperFourthOpcode, helperFourthOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(entryOpcode, entryOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (sequenceOperandValid(secondEntryOpcode, secondEntryOperand) == false) {
      return new MinimalProgramResult.Error(0);
    }

    MinimalProgram program = new MinimalProgram(
      name,
      global,
      1,
      parsedSignedNumber(source, tokenStarts, tokenLengths, 8),
      entryCount,
      entryOpcode,
      entryOperand,
      secondEntryOpcode,
      secondEntryOperand,
      -1,
      0,
      -1,
      0,
      -1,
      0,
      helper,
      1,
      helperOpcode,
      helperOperand,
      reversible,
      proof,
      proofCount,
      helperCallCount,
      preReverseCount,
      helperStatementCount,
      helperSecondOpcode,
      helperSecondOperand,
      helperThirdOpcode,
      helperThirdOperand,
      helperFourthOpcode,
      helperFourthOperand
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
    long helperBody,
    long reversible,
    long proofToken,
    long proofCount,
    long helperCallCount,
    long preReverseStatement,
    long helperSecondStatement,
    long helperThirdStatement,
    long helperFourthStatement
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
            helperBody,
            reversible,
            proofToken,
            proofCount,
            entryStatement,
            helperCallCount,
            preReverseStatement,
            helperSecondStatement,
            helperThirdStatement,
            helperFourthStatement
          );
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

  private record HelperStatements(
    long end,
    long second,
    long third,
    long fourth,
    boolean valid
  ) {}

  private record ProofHeader(long entryStart, long token, long count) {}

  private HelperStatements helperStatements(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long body
  ) {
    long firstWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, body);
    if (firstWidth < 1) {
      return new HelperStatements(-1, -1, -1, -1, false);
    }

    long end = body + firstWidth;
    if (punctuationAt(source, tokenKinds, tokenStarts, end, PUNCTUATION_CLOSE_BRACE)) {
      return new HelperStatements(end, -1, -1, -1, true);
    }

    long second = end;
    long secondWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, second);
    if (secondWidth < 1) {
      return new HelperStatements(-1, second, -1, -1, false);
    }

    end += secondWidth;
    if (punctuationAt(source, tokenKinds, tokenStarts, end, PUNCTUATION_CLOSE_BRACE)) {
      return new HelperStatements(end, second, -1, -1, true);
    }

    long third = end;
    long thirdWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, third);
    if (thirdWidth < 1) {
      return new HelperStatements(-1, second, third, -1, false);
    }

    end += thirdWidth;
    if (punctuationAt(source, tokenKinds, tokenStarts, end, PUNCTUATION_CLOSE_BRACE)) {
      return new HelperStatements(end, second, third, -1, true);
    }

    long fourth = end;
    long fourthWidth = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, fourth);
    if (fourthWidth < 1) {
      return new HelperStatements(-1, second, third, fourth, false);
    }

    return new HelperStatements(end + fourthWidth, second, third, fourth, true);
  }

  private boolean helperStatementsValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long body,
    long reversible,
    HelperStatements statements
  ) {
    if (statements.valid == false) {
      return false;
    }

    if (reversible == 0) {
      return true;
    }

    if (reversibleBodyValid(source, tokenStarts, tokenLengths, body) == false) {
      return false;
    }

    if (-1 < statements.second) {
      if (
        reversibleBodyValid(source, tokenStarts, tokenLengths, statements.second) == false
      ) {
        return false;
      }
    }

    if (-1 < statements.third) {
      if (
        reversibleBodyValid(source, tokenStarts, tokenLengths, statements.third) == false
      ) {
        return false;
      }
    }

    if (-1 < statements.fourth) {
      if (
        reversibleBodyValid(source, tokenStarts, tokenLengths, statements.fourth) == false
      ) {
        return false;
      }
    }

    return true;
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
    if (
      helperStatementsValid(
        source,
        tokenStarts,
        tokenLengths,
        helperBody,
        reversible,
        statements
      ) == false
    ) {
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
        helperBody,
        reversible,
        proof.token,
        proof.count,
        helperCallCount,
        -1,
        statements.second,
        statements.third,
        statements.fourth
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
      helperBody,
      reversible,
      proof.token,
      proof.count,
      helperCallCount,
      preReverseStatement,
      statements.second,
      statements.third,
      statements.fourth
    );
  }
}
