//! Parses helper functions in the bounded bootstrap source profile.

module wheeler.compiler.helper_parser;

import wheeler.compiler.body_parser;
import wheeler.compiler.class_constants;
import wheeler.compiler.class_layouts;
import wheeler.compiler.helper_abi;
import wheeler.compiler.helper_calls;
import wheeler.compiler.helper_programs;
import wheeler.compiler.ir;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.named_return_arithmetic_kinds;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.statements;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class HelperParser {
  private MinimalProgramResult finishEntry(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long count,
    long closeStart,
    ClassLayout layout,
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
            layout,
            nameToken,
            helperKind,
            proofToken,
            proofCount,
            entryStatement,
            helperCallCount,
            preReverseStatement,
            0,
            helperStarts,
            helperStatementCount,
            false
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
    if (reversibleHelper(helperKind)) {} else {
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
    long count,
    ClassLayout layout
  ) {
    long memberStart = layout.memberStart;
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
          if (helperKind == HELPER_REVERSIBLE) {
            helperKind = HELPER_REVERSIBLE_SIGNED;
          } else {
            return new MinimalProgramResult.Error(0);
          }
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

    if (classConstantNameExists(source, tokenStarts, tokenLengths, nameToken)) {
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

    if (helperKind == HELPER_REVERSIBLE_SIGNED) {
      if (tokenHash(source, tokenStarts, tokenLengths, closeParameters) == TOKEN_LONG) {
        parameterToken = nameToken + 3;
        if (tokenKinds[parameterToken] == 1) {} else {
          return new MinimalProgramResult.Error(0);
        }

        if (tokenLengths[parameterToken] < 257) {} else {
          return new MinimalProgramResult.Error(0);
        }

        closeParameters = nameToken + 4;
        helperKind = HELPER_REVERSIBLE_SIGNED_ONE;
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
            helperKind = HELPER_REVERSIBLE_SIGNED_TWO;
          }
        }
      }
    }

    if (helperKind == HELPER_BOOLEAN) {
      long booleanParameterType = tokenHash(source, tokenStarts, tokenLengths, closeParameters);
      boolean booleanParameter = booleanParameterType == TOKEN_BOOLEAN;
      boolean signedBooleanParameter = booleanParameterType == TOKEN_LONG;
      boolean acceptedBooleanParameter = booleanParameter;
      if (signedBooleanParameter) {
        acceptedBooleanParameter = true;
      }

      if (acceptedBooleanParameter) {
        parameterToken = nameToken + 3;
        if (tokenKinds[parameterToken] == 1) {} else {
          return new MinimalProgramResult.Error(0);
        }

        if (tokenLengths[parameterToken] < 257) {} else {
          return new MinimalProgramResult.Error(0);
        }

        closeParameters = nameToken + 4;
        helperKind = HELPER_BOOLEAN_ONE;
        if (signedBooleanParameter) {
          helperKind = HELPER_BOOLEAN_SIGNED_ONE;
        }
      }
    }

    boolean oneBooleanParameter = helperKind == HELPER_BOOLEAN_ONE;
    if (helperKind == HELPER_BOOLEAN_SIGNED_ONE) {
      oneBooleanParameter = true;
    }

    if (oneBooleanParameter) {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, closeParameters, PUNCTUATION_COMMA)
      ) {
        long expectedParameterType = TOKEN_BOOLEAN;
        if (helperKind == HELPER_BOOLEAN_SIGNED_ONE) {
          expectedParameterType = TOKEN_LONG;
        }

        if (
          tokenHash(source, tokenStarts, tokenLengths, closeParameters + 1) == expectedParameterType
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
          helperKind = HELPER_BOOLEAN_TWO;
          if (expectedParameterType == TOKEN_LONG) {
            helperKind = HELPER_BOOLEAN_SIGNED_TWO;
          }
        } else {
          return new MinimalProgramResult.Error(0);
        }
      }
    }

    if (0 < parameterToken) {
      if (classConstantNameExists(source, tokenStarts, tokenLengths, parameterToken)) {
        return new MinimalProgramResult.Error(0);
      }
    }

    if (0 < secondParameterToken) {
      if (
        classConstantNameExists(source, tokenStarts, tokenLengths, secondParameterToken)
      ) {
        return new MinimalProgramResult.Error(0);
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
            if (
              classConstantHasType(source, tokenStarts, tokenLengths, returnStart + 3, true)
                == false
            ) {
              return new MinimalProgramResult.Error(0);
            }
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
          if (
            classConstantHasType(source, tokenStarts, tokenLengths, pairReturnStart + 3, true)
              == false
          ) {
            return new MinimalProgramResult.Error(0);
          }
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
    if (
      punctuationAt(source, tokenKinds, tokenStarts, proof.entryStart, PUNCTUATION_CLOSE_BRACE)
    ) {
      if (count == proof.entryStart + 1) {
        if (resultSlotHelper(helperKind)) {} else {
          return helperProgram(
            source,
            tokenStarts,
            tokenLengths,
            layout,
            nameToken,
            helperKind,
            proof.token,
            proof.count,
            -1,
            0,
            -1,
            0,
            statementStarts,
            statements.count,
            true
          );
        }
      }
    }

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
          resultCallNamesHelper(source, tokenStarts, tokenLengths, nameToken, entryCursor)
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
        layout,
        nameToken,
        helperKind,
        proof.token,
        proof.count,
        -1,
        0,
        -1,
        resultEntryCount,
        statementStarts,
        statements.count,
        false
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
        layout,
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
      layout,
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
