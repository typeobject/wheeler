//! Parses helper functions in the bounded bootstrap source profile.

module wheeler.compiler.helper_parser;

import wheeler.compiler.body_parser;
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

  private boolean resultCallValid(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long nameToken,
    long callStart,
    long helperKind
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, callStart);
    boolean expectedCall = opcode == STATEMENT_LOCAL_CALL_NAMED;
    if (helperKind == 3) {
      expectedCall = opcode == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED;
      if (opcode == STATEMENT_LOCAL_CALL_LOCAL_ARGUMENT_NAMED) {
        expectedCall = true;
      }
    }

    if (helperKind == 4) {
      expectedCall = opcode == STATEMENT_LOCAL_CALL_TWO_ARGUMENT_NAMED;
    }

    if (expectedCall) {
      return sameTokenText(source, tokenStarts, tokenLengths, nameToken, callStart + 3);
    }

    return false;
  }

  private MinimalProgramResult helperProgram(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long globalCount,
    long nameToken,
    long reversible,
    long proofToken,
    long proofCount,
    long entryStatement,
    long helperCallCount,
    long entryPreludeStatement,
    long preReverseStatement,
    borrow mut words helperStarts,
    long helperStatementCount
  ) {
    SourceRange name = new SourceRange(tokenStarts[2], tokenLengths[2]);
    SourceRange global = new SourceRange(0, 0);
    long initial = 0;
    if (globalCount == 1) {
      global = new SourceRange(tokenStarts[6], tokenLengths[6]);
      initial = parsedSignedNumber(source, tokenStarts, tokenLengths, 8);
    }

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

    if (reversible == 2) {
      if (helperSequence.count == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }

      if (helperSequence.opcodes[0] == STATEMENT_RETURN_LONG) {} else {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (reversible == 3) {
      if (helperSequence.count == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }

      boolean parameterReturn = helperSequence.opcodes[0] == STATEMENT_RETURN_LOCAL_NAMED;
      if (returnLocalBinaryStatement(helperSequence.opcodes[0])) {
        parameterReturn = true;
      }

      if (returnLocalPairStatement(helperSequence.opcodes[0])) {
        parameterReturn = true;
      }

      if (parameterReturn == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (reversible == 4) {
      if (helperSequence.count == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }

      if (returnLocalPairStatement(helperSequence.opcodes[0]) == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (reversible < 2) {
      long helperStatement = 0;
      while (helperStatement < helperSequence.count) limit MAX_MINIMAL_STATEMENTS {
        if (helperSequence.opcodes[helperStatement] == STATEMENT_RETURN_LONG) {
          return new MinimalProgramResult.Error(0);
        }

        if (helperSequence.opcodes[helperStatement] == STATEMENT_RETURN_LOCAL_NAMED) {
          return new MinimalProgramResult.Error(0);
        }

        if (returnLocalBinaryStatement(helperSequence.opcodes[helperStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        if (returnLocalPairStatement(helperSequence.opcodes[helperStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        helperStatement += 1;
      }
    }

    if (reversible == 1) {
      if (reversibleSequenceValid(helperSequence) == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    long entryCount = 0;
    long entryFirst = -1;
    long entrySecond = -1;
    long entryThird = -1;
    long preReverseCount = 0;
    if (-1 < entryPreludeStatement) {
      entryCount = 1;
      entryFirst = entryPreludeStatement;
    }

    if (-1 < preReverseStatement) {
      if (entryCount == 0) {
        entryCount = 1;
        entryFirst = preReverseStatement;
      } else {
        entryCount = 2;
        entrySecond = preReverseStatement;
      }

      if (reversible == 1) {
        preReverseCount = 1;
      }
    }

    if (-1 < entryStatement) {
      if (entryCount == 0) {
        entryCount = 1;
        entryFirst = entryStatement;
      } else {
        if (entryCount == 1) {
          entryCount = 2;
          entrySecond = entryStatement;
        } else {
          entryCount = 3;
          entryThird = entryStatement;
        }
      }
    }

    set(helperStarts, 0, entryFirst);
    set(helperStarts, 1, entrySecond);
    set(helperStarts, 2, entryThird);
    StatementSequence entrySequence = parseStatementSequence(
      source,
      tokenStarts,
      tokenLengths,
      helperStarts,
      entryCount
    );
    if (entrySequence.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    MinimalProgram program = new MinimalProgram(
      name,
      global,
      globalCount,
      initial,
      entrySequence.count,
      entrySequence.opcodes,
      entrySequence.operands,
      entrySequence.secondaryOperands,
      helper,
      1,
      helperSequence.opcodes,
      helperSequence.operands,
      helperSequence.secondaryOperands,
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
    long globalCount,
    long nameToken,
    long reversible,
    long proofToken,
    long proofCount,
    long helperCallCount,
    long entryPreludeStatement,
    long preReverseStatement,
    borrow mut words helperStarts,
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
            globalCount,
            nameToken,
            reversible,
            proofToken,
            proofCount,
            entryStatement,
            helperCallCount,
            entryPreludeStatement,
            preReverseStatement,
            helperStarts,
            helperStatementCount
          );
        }
      }
    }

    return new MinimalProgramResult.Error(0);
  }

  private record ProofHeader(long entryStart, long token, long count) {}

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
    if (reversible == 1) {} else {
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
    borrow mut words statementStarts,
    long count
  ) {
    long globalCount = 1;
    long memberStart = minimalEntryStart(source, tokenKinds, tokenStarts, tokenLengths);
    if (memberStart < 1) {
      globalCount = 0;
      memberStart = minimalNoGlobalMemberStart(source, tokenKinds, tokenStarts, tokenLengths);
      if (memberStart < 1) {
        return new MinimalProgramResult.Error(0);
      }
    }

    long reversible = 0;
    long voidToken = memberStart;
    long visibility = tokenHash(source, tokenStarts, tokenLengths, voidToken);
    if (visibility == TOKEN_PUBLIC) {
      voidToken += 1;
    } else {
      if (visibility == TOKEN_PRIVATE) {
        voidToken += 1;
      }
    }

    if (tokenHash(source, tokenStarts, tokenLengths, voidToken) == TOKEN_REV) {
      reversible = 1;
      voidToken += 1;
    }

    long helperType = tokenHash(source, tokenStarts, tokenLengths, voidToken);
    if (helperType == TOKEN_VOID) {} else {
      if (helperType == TOKEN_LONG) {
        if (reversible == 0) {
          reversible = 2;
        } else {
          return new MinimalProgramResult.Error(0);
        }
      } else {
        return new MinimalProgramResult.Error(0);
      }
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

    long parameterToken = -1;
    long secondParameterToken = -1;
    long closeParameters = nameToken + 2;
    if (reversible == 2) {
      if (tokenHash(source, tokenStarts, tokenLengths, closeParameters) == TOKEN_LONG) {
        parameterToken = nameToken + 3;
        if (tokenKinds[parameterToken] == 1) {} else {
          return new MinimalProgramResult.Error(0);
        }

        if (tokenLengths[parameterToken] < 257) {} else {
          return new MinimalProgramResult.Error(0);
        }

        closeParameters = nameToken + 4;
        reversible = 3;
        if (
          punctuationAt(source, tokenKinds, tokenStarts, closeParameters, PUNCTUATION_COMMA)
        ) {
          if (
            tokenHash(source, tokenStarts, tokenLengths, closeParameters + 1) == TOKEN_LONG
          ) {
            secondParameterToken = closeParameters + 2;
            if (tokenKinds[secondParameterToken] == 1) {} else {
              return new MinimalProgramResult.Error(0);
            }

            if (tokenLengths[secondParameterToken] < 257) {} else {
              return new MinimalProgramResult.Error(0);
            }

            if (
              sameTokenText(
                source,
                tokenStarts,
                tokenLengths,
                parameterToken,
                secondParameterToken
              )
            ) {
              return new MinimalProgramResult.Error(0);
            }

            closeParameters += 3;
            reversible = 4;
          }
        }
      }
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, closeParameters, PUNCTUATION_CLOSE_PAREN)
        == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        closeParameters + 1,
        PUNCTUATION_OPEN_BRACE
      ) == false
    ) {
      return new MinimalProgramResult.Error(0);
    }

    long helperBody = closeParameters + 2;
    BodyScan statements = scanBody(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      statementStarts,
      helperBody
    );
    if (statements.valid == false) {
      return new MinimalProgramResult.Error(0);
    }

    if (reversible == 3) {
      if (statements.count == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long returnStart = statementStarts[0];
      if (
        sameTokenText(source, tokenStarts, tokenLengths, parameterToken, returnStart + 1) == false
      ) {
        return new MinimalProgramResult.Error(0);
      }

      long returnOpcode = statementOpcode(source, tokenStarts, tokenLengths, returnStart);
      if (returnLocalPairStatement(returnOpcode)) {
        if (
          sameTokenText(source, tokenStarts, tokenLengths, parameterToken, returnStart + 3) == false
        ) {
          return new MinimalProgramResult.Error(0);
        }
      }
    }

    if (reversible == 4) {
      if (statements.count == 1) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long pairReturnStart = statementStarts[0];
      long pairReturnOpcode = statementOpcode(
        source,
        tokenStarts,
        tokenLengths,
        pairReturnStart
      );
      if (returnLocalPairStatement(pairReturnOpcode) == false) {
        return new MinimalProgramResult.Error(0);
      }

      if (
        sameTokenText(source, tokenStarts, tokenLengths, parameterToken, pairReturnStart + 1)
          == false
      ) {
        return new MinimalProgramResult.Error(0);
      }

      if (
        sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          secondParameterToken,
          pairReturnStart + 3
        ) == false
      ) {
        return new MinimalProgramResult.Error(0);
      }
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

    if (1 < reversible) {
      long entryPreludeStatement = -1;
      long resultCall = entryBody;
      if (
        resultCallValid(source, tokenStarts, tokenLengths, nameToken, resultCall, reversible)
          == false
      ) {
        long entryPreludeWidth = statementWidth(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          entryBody
        );
        if (entryPreludeWidth < 1) {
          return new MinimalProgramResult.Error(0);
        }

        entryPreludeStatement = entryBody;
        resultCall += entryPreludeWidth;
        if (
          resultCallValid(
            source,
            tokenStarts,
            tokenLengths,
            nameToken,
            resultCall,
            reversible
          ) == false
        ) {
          return new MinimalProgramResult.Error(0);
        }
      }

      long resultCallWidth = statementWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        resultCall
      );
      if (resultCallWidth < 1) {
        return new MinimalProgramResult.Error(0);
      }

      return finishEntry(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        count,
        resultCall + resultCallWidth,
        globalCount,
        nameToken,
        reversible,
        proof.token,
        proof.count,
        0,
        entryPreludeStatement,
        resultCall,
        statementStarts,
        statements.count
      );
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
        globalCount,
        nameToken,
        reversible,
        proof.token,
        proof.count,
        helperCallCount,
        -1,
        -1,
        statementStarts,
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
      globalCount,
      nameToken,
      reversible,
      proof.token,
      proof.count,
      helperCallCount,
      -1,
      preReverseStatement,
      statementStarts,
      statements.count
    );
  }
}
