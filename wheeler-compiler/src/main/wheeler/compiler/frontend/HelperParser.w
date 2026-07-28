//! Parses helper functions in the bounded bootstrap source profile.

module wheeler.compiler.helper_parser;

import wheeler.compiler.body_parser;
import wheeler.compiler.helper_calls;
import wheeler.compiler.ir;
import wheeler.compiler.sequences;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class HelperParser {
  private boolean resultStatement(long opcode) {
    if (opcode == STATEMENT_RETURN_BOOLEAN) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LONG) {
      return true;
    }

    if (opcode == STATEMENT_RETURN_LOCAL_NAMED) {
      return true;
    }

    if (returnLocalBinaryStatement(opcode)) {
      return true;
    }

    return returnLocalPairStatement(opcode);
  }

  private MinimalProgramResult helperProgram(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long globalCount,
    long nameToken,
    long helperKind,
    long proofToken,
    long proofCount,
    long entryStatement,
    long helperCallCount,
    long preReverseStatement,
    long resultEntryCount,
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

    long parameterCount = 0;
    if (helperKind == HELPER_SIGNED_ONE) {
      parameterCount = 1;
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      parameterCount = 2;
    }

    if (0 < parameterCount) {
      long shifted = helperStatementCount;
      while (0 < shifted) limit MAX_MINIMAL_STATEMENTS {
        set(helperStarts, shifted + parameterCount - 1, helperStarts[shifted - 1]);
        shifted -= 1;
      }

      set(helperStarts, 0, 0 - (nameToken + 3));
      if (parameterCount == 2) {
        set(helperStarts, 1, 0 - (nameToken + 6));
      }
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

    if (helperKind == HELPER_SIGNED) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long resultIndex = helperSequence.count - 1;
      long resultOpcode = helperSequence.opcodes[resultIndex];
      boolean supportedResult = resultOpcode == STATEMENT_RETURN_LONG;
      if (resultOpcode == STATEMENT_RETURN_LOCAL_NAMED) {
        supportedResult = true;
      }

      if (supportedResult == false) {
        return new MinimalProgramResult.Error(0);
      }

      long preludeStatement = 0;
      while (preludeStatement < resultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[preludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        preludeStatement += 1;
      }
    }

    if (helperKind == HELPER_BOOLEAN) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long booleanResultIndex = helperSequence.count - 1;
      if (helperSequence.opcodes[booleanResultIndex] == STATEMENT_RETURN_BOOLEAN) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long booleanPreludeStatement = 0;
      while (booleanPreludeStatement < booleanResultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[booleanPreludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        booleanPreludeStatement += 1;
      }
    }

    if (helperKind == HELPER_SIGNED_ONE) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long parameterResultIndex = helperSequence.count - 1;
      if (resultStatement(helperSequence.opcodes[parameterResultIndex])) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long parameterPreludeStatement = 0;
      while (parameterPreludeStatement < parameterResultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[parameterPreludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        parameterPreludeStatement += 1;
      }
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      if (0 < helperSequence.count) {} else {
        return new MinimalProgramResult.Error(0);
      }

      long pairResultIndex = helperSequence.count - 1;
      if (helperSequence.count == 1) {
        if (returnLocalPairStatement(helperSequence.opcodes[pairResultIndex])) {} else {
          return new MinimalProgramResult.Error(0);
        }
      } else {
        if (helperSequence.opcodes[pairResultIndex] == STATEMENT_RETURN_LOCAL_NAMED) {} else {
          return new MinimalProgramResult.Error(0);
        }
      }

      long pairPreludeStatement = 0;
      while (pairPreludeStatement < pairResultIndex) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[pairPreludeStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        pairPreludeStatement += 1;
      }
    }

    if (helperKind < HELPER_SIGNED) {
      long helperStatement = 0;
      while (helperStatement < helperSequence.count) limit MAX_MINIMAL_STATEMENTS {
        if (resultStatement(helperSequence.opcodes[helperStatement])) {
          return new MinimalProgramResult.Error(0);
        }

        helperStatement += 1;
      }
    }

    if (helperKind == HELPER_REVERSIBLE) {
      if (reversibleSequenceValid(helperSequence) == false) {
        return new MinimalProgramResult.Error(0);
      }
    }

    long entryCount = 0;
    long preReverseCount = 0;
    if (0 < resultEntryCount) {
      while (entryCount < resultEntryCount) limit MAX_MINIMAL_STATEMENTS {
        set(helperStarts, entryCount, helperStarts[MAX_HELPER_RESOLUTION_STARTS + entryCount]);
        entryCount += 1;
      }
    } else {
      if (-1 < preReverseStatement) {
        set(helperStarts, entryCount, preReverseStatement);
        entryCount += 1;
        if (helperKind == HELPER_REVERSIBLE) {
          preReverseCount = 1;
        }
      }

      if (-1 < entryStatement) {
        set(helperStarts, entryCount, entryStatement);
        entryCount += 1;
      }
    }

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
      helperKind,
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
    long helperKind,
    long proofToken,
    long proofCount,
    long helperCallCount,
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
            helperKind,
            proofToken,
            proofCount,
            entryStatement,
            helperCallCount,
            preReverseStatement,
            0,
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
    long helperKind
  ) {
    ProofHeader absent = new ProofHeader(entryStart, -1, 0);
    if (helperKind == HELPER_REVERSIBLE) {} else {
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

    long helperKind = HELPER_VOID;
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
      helperKind = HELPER_REVERSIBLE;
      voidToken += 1;
    }

    long helperType = tokenHash(source, tokenStarts, tokenLengths, voidToken);
    if (helperType == TOKEN_VOID) {} else {
      if (helperType == TOKEN_LONG) {
        if (helperKind == HELPER_VOID) {
          helperKind = HELPER_SIGNED;
        } else {
          return new MinimalProgramResult.Error(0);
        }
      } else {
        if (helperType == TOKEN_BOOLEAN) {
          if (helperKind == HELPER_VOID) {
            helperKind = HELPER_BOOLEAN;
          } else {
            return new MinimalProgramResult.Error(0);
          }
        } else {
          return new MinimalProgramResult.Error(0);
        }
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
    if (helperKind == HELPER_SIGNED) {
      if (tokenHash(source, tokenStarts, tokenLengths, closeParameters) == TOKEN_LONG) {
        parameterToken = nameToken + 3;
        if (tokenKinds[parameterToken] == 1) {} else {
          return new MinimalProgramResult.Error(0);
        }

        if (tokenLengths[parameterToken] < 257) {} else {
          return new MinimalProgramResult.Error(0);
        }

        closeParameters = nameToken + 4;
        helperKind = HELPER_SIGNED_ONE;
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
            helperKind = HELPER_SIGNED_TWO;
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

    if (helperKind == HELPER_SIGNED_ONE) {
      if (statements.count == 1) {
        long returnStart = statementStarts[0];
        if (
          sameTokenText(source, tokenStarts, tokenLengths, parameterToken, returnStart + 1) == false
        ) {
          return new MinimalProgramResult.Error(0);
        }

        long returnOpcode = statementOpcode(source, tokenStarts, tokenLengths, returnStart);
        if (returnLocalPairStatement(returnOpcode)) {
          if (
            sameTokenText(source, tokenStarts, tokenLengths, parameterToken, returnStart + 3)
              == false
          ) {
            return new MinimalProgramResult.Error(0);
          }
        }
      }
    }

    if (helperKind == HELPER_SIGNED_TWO) {
      if (statements.count == 1) {
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
      helperKind
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

    if (HELPER_REVERSIBLE < helperKind) {
      long resultEntryCount = 0;
      long resultCallCount = 0;
      long entryCursor = entryBody;
      while (
        punctuationAt(source, tokenKinds, tokenStarts, entryCursor, PUNCTUATION_CLOSE_BRACE)
          == false
      ) limit MAX_MINIMAL_STATEMENTS {
        if (resultEntryCount < MAX_MINIMAL_STATEMENTS) {} else {
          return new MinimalProgramResult.Error(0);
        }

        long entryWidth = statementWidth(
          source,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          entryCursor
        );
        if (entryWidth < 1) {
          return new MinimalProgramResult.Error(0);
        }

        set(statementStarts, MAX_HELPER_RESOLUTION_STARTS + resultEntryCount, entryCursor);
        if (
          resultCallValid(
            source,
            tokenStarts,
            tokenLengths,
            nameToken,
            entryCursor,
            helperKind
          )
        ) {
          resultCallCount += 1;
        }

        resultEntryCount += 1;
        entryCursor += entryWidth;
      }

      if (0 < resultCallCount) {} else {
        return new MinimalProgramResult.Error(0);
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, entryCursor, PUNCTUATION_CLOSE_BRACE)
      ) {} else {
        return new MinimalProgramResult.Error(0);
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          entryCursor + 1,
          PUNCTUATION_CLOSE_BRACE
        )
      ) {} else {
        return new MinimalProgramResult.Error(0);
      }

      if (count == entryCursor + 2) {} else {
        return new MinimalProgramResult.Error(0);
      }

      return helperProgram(
        source,
        tokenStarts,
        tokenLengths,
        globalCount,
        nameToken,
        helperKind,
        proof.token,
        proof.count,
        -1,
        0,
        -1,
        resultEntryCount,
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
    if (helperKind == HELPER_REVERSIBLE) {
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

    if (helperKind == HELPER_VOID) {
      return finishEntry(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        count,
        afterCalls,
        globalCount,
        nameToken,
        helperKind,
        proof.token,
        proof.count,
        helperCallCount,
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
      helperKind,
      proof.token,
      proof.count,
      helperCallCount,
      preReverseStatement,
      statementStarts,
      statements.count
    );
  }
}
