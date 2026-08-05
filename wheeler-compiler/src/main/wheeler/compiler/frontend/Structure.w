//! Computes canonical section offsets for bootstrap artifacts.

module wheeler.compiler.structure;

import wheeler.compiler.call_argument_sources;
import wheeler.compiler.call_forms;
import wheeler.compiler.one_argument_calls;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;
import wheeler.compiler.two_argument_call_kinds;

classical class Structure {
  /// Returns the first source offset inside the bounded entry body.
  public long minimalBodyStart(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long entryStart
  ) {
    if (tokenHash(source, tokenStarts, tokenLengths, entryStart) == TOKEN_ENTRY) {
      if (tokenHash(source, tokenStarts, tokenLengths, entryStart + 1) == TOKEN_VOID) {
        if (
          tokenHash(source, tokenStarts, tokenLengths, entryStart + 2) == TOKEN_MAIN
        ) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              entryStart + 3,
              PUNCTUATION_OPEN_PAREN
            )
          ) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                entryStart + 4,
                PUNCTUATION_CLOSE_PAREN
              )
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  entryStart + 5,
                  PUNCTUATION_OPEN_BRACE
                )
              ) {
                return entryStart + 6;
              }
            }
          }
        }
      }
    }

    return -1;
  }

  private long returnComparisonWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (tokenKinds[statementStart + 1] == 1) {} else {
      return -1;
    }

    long firstOperator = PUNCTUATION_ASSIGN;
    if (returnBooleanInequalityStatement(statementKind)) {
      firstOperator = PUNCTUATION_BANG;
    }

    if (returnSignedInequalityStatement(statementKind)) {
      firstOperator = PUNCTUATION_BANG;
    }

    if (returnSignedLessThanStatement(statementKind)) {
      firstOperator = PUNCTUATION_LESS_THAN;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, firstOperator) == false
    ) {
      return -1;
    }

    long rightToken = statementStart + 4;
    if (returnSignedLessThanStatement(statementKind)) {
      rightToken -= 1;
    } else {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }
    }

    long rightWidth = 1;
    if (returnComparisonLocalRight(statementKind)) {
      if (tokenKinds[rightToken] == 1) {} else {
        return -1;
      }
    } else {
      if (returnComparisonSigned(statementKind)) {
        rightWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightToken);
        if (rightWidth < 1) {
          return -1;
        }

        if (signedNumberValid(source, tokenStarts, tokenLengths, rightToken) == false) {
          return -1;
        }
      } else {
        long rightHash = tokenHash(source, tokenStarts, tokenLengths, rightToken);
        if (booleanTokenHash(rightHash) == false) {
          return -1;
        }
      }
    }

    long semicolonToken = rightToken + rightWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, semicolonToken, PUNCTUATION_SEMICOLON)
    ) {
      return semicolonToken - statementStart + 1;
    }

    return -1;
  }

  /// Validates and sizes one bounded helper value statement.
  public long helperValueStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long statementKind
  ) {
    if (statementKind == STATEMENT_RETURN_BOOLEAN) {
      long returned = tokenHash(source, tokenStarts, tokenLengths, statementStart + 1);
      boolean valid = returned == TOKEN_TRUE;
      if (returned == TOKEN_FALSE) {
        valid = true;
      }

      if (valid) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 2,
            PUNCTUATION_SEMICOLON
          )
        ) {
          return 3;
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_RETURN_BOOLEAN_NOT_NAMED) {
      if (tokenKinds[statementStart + 2] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 4;
      }

      return -1;
    }

    if (returnComparisonStatement(statementKind)) {
      return returnComparisonWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart,
        statementKind
      );
    }

    if (statementKind == STATEMENT_RETURN_LONG) {
      long returnWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 1);
      if (returnWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 1) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1 + returnWidth,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return returnWidth + 2;
      }

      return -1;
    }

    if (statementKind == STATEMENT_RETURN_HELPER_CALL_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 2,
          PUNCTUATION_OPEN_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 4,
            PUNCTUATION_SEMICOLON
          )
        ) {
          return 5;
        }

        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_CLOSE_PAREN
        )
      ) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 6;
      }

      return -1;
    }

    if (statementKind == STATEMENT_RETURN_LOCAL_NAMED) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 2,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 3;
      }

      return -1;
    }

    if (returnLocalPairStatement(statementKind)) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      long pairOperator = PUNCTUATION_PLUS;
      if (statementKind == STATEMENT_RETURN_LOCAL_SUB_LOCAL_NAMED) {
        pairOperator = PUNCTUATION_MINUS;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_MUL_LOCAL_NAMED) {
        pairOperator = PUNCTUATION_STAR;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_DIV_LOCAL_NAMED) {
        pairOperator = PUNCTUATION_SLASH;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_MOD_LOCAL_NAMED) {
        pairOperator = PUNCTUATION_PERCENT;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_XOR_LOCAL_NAMED) {
        pairOperator = PUNCTUATION_CARET;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_AND_LOCAL_NAMED) {
        pairOperator = PUNCTUATION_AMPERSAND;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, pairOperator) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 5;
      }

      return -1;
    }

    if (returnLocalBinaryStatement(statementKind)) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      long returnOperator = PUNCTUATION_PLUS;
      if (statementKind == STATEMENT_RETURN_LOCAL_SUB_NAMED) {
        returnOperator = PUNCTUATION_MINUS;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_MUL_NAMED) {
        returnOperator = PUNCTUATION_STAR;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_DIV_NAMED) {
        returnOperator = PUNCTUATION_SLASH;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_MOD_NAMED) {
        returnOperator = PUNCTUATION_PERCENT;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_XOR_NAMED) {
        returnOperator = PUNCTUATION_CARET;
      }

      if (statementKind == STATEMENT_RETURN_LOCAL_AND_NAMED) {
        returnOperator = PUNCTUATION_AMPERSAND;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, returnOperator) == false
      ) {
        return -1;
      }

      long returnOperandWidth = signedNumberWidth(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 3
      );
      if (returnOperandWidth < 1) {
        return -1;
      }

      if (
        signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 3) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 3 + returnOperandWidth,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return returnOperandWidth + 4;
      }

      return -1;
    }

    boolean zeroArgumentCall = statementKind == STATEMENT_LOCAL_CALL_NAMED;
    if (statementKind == STATEMENT_LOCAL_BOOLEAN_CALL_NAMED) {
      zeroArgumentCall = true;
    }

    if (zeroArgumentCall) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 6,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 7;
      }
    }

    if (twoArgumentCallStatement(statementKind)) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      boolean booleanTwoArgumentCall = twoArgumentBooleanCall(statementKind);
      long firstArgumentWidth = 1;
      if (twoArgumentCallFirstNamed(statementKind)) {
        if (tokenKinds[statementStart + 5] == 1) {} else {
          return -1;
        }
      } else {
        if (booleanTwoArgumentCall) {
          long firstArgumentHash = tokenHash(
            source,
            tokenStarts,
            tokenLengths,
            statementStart + 5
          );
          if (booleanTokenHash(firstArgumentHash) == false) {
            return -1;
          }
        } else {
          firstArgumentWidth = signedNumberWidth(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 5
          );
          if (firstArgumentWidth < 1) {
            return -1;
          }

          if (
            signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5) == false
          ) {
            return -1;
          }
        }
      }

      long commaToken = statementStart + 5 + firstArgumentWidth;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, commaToken, PUNCTUATION_COMMA) == false
      ) {
        return -1;
      }

      long secondArgumentWidth = 1;
      if (twoArgumentCallSecondNamed(statementKind)) {
        if (tokenKinds[commaToken + 1] == 1) {} else {
          return -1;
        }
      } else {
        if (booleanTwoArgumentCall) {
          long secondArgumentHash = tokenHash(source, tokenStarts, tokenLengths, commaToken + 1);
          if (booleanTokenHash(secondArgumentHash) == false) {
            return -1;
          }
        } else {
          secondArgumentWidth = signedNumberWidth(
            source,
            tokenKinds,
            tokenStarts,
            commaToken + 1
          );
          if (secondArgumentWidth < 1) {
            return -1;
          }

          if (
            signedNumberValid(source, tokenStarts, tokenLengths, commaToken + 1) == false
          ) {
            return -1;
          }
        }
      }

      long closeToken = commaToken + 1 + secondArgumentWidth;
      if (
        punctuationAt(source, tokenKinds, tokenStarts, closeToken, PUNCTUATION_CLOSE_PAREN) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, closeToken + 1, PUNCTUATION_SEMICOLON)
      ) {
        return firstArgumentWidth + secondArgumentWidth + 8;
      }

      return -1;
    }

    if (oneArgumentCallNamed(statementKind)) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 5] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 6,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 7,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return 8;
      }

      return -1;
    }

    boolean literalOneArgumentCall = statementKind == STATEMENT_LOCAL_CALL_ARGUMENT_NAMED;
    if (statementKind == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
      literalOneArgumentCall = true;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_CALL_SIGNED_ARGUMENT_NAMED) {
      literalOneArgumentCall = true;
    }

    if (literalOneArgumentCall) {
      if (tokenKinds[statementStart + 1] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
          == false
      ) {
        return -1;
      }

      if (tokenKinds[statementStart + 3] == 1) {} else {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 4,
          PUNCTUATION_OPEN_PAREN
        ) == false
      ) {
        return -1;
      }

      long argumentWidth = 1;
      if (statementKind == STATEMENT_LOCAL_BOOLEAN_CALL_ARGUMENT_NAMED) {
        long argumentHash = tokenHash(source, tokenStarts, tokenLengths, statementStart + 5);
        if (booleanTokenHash(argumentHash) == false) {
          return -1;
        }
      } else {
        argumentWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 5);
        if (argumentWidth < 1) {
          return -1;
        }

        if (
          signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5) == false
        ) {
          return -1;
        }
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 5 + argumentWidth,
          PUNCTUATION_CLOSE_PAREN
        ) == false
      ) {
        return -1;
      }

      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 6 + argumentWidth,
          PUNCTUATION_SEMICOLON
        )
      ) {
        return argumentWidth + 7;
      }
    }

    return -1;
  }

  /// Validates and sizes one equality assertion over two signed literals.
  public long literalEqualityStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        statementStart + 1,
        PUNCTUATION_OPEN_PAREN
      ) == false
    ) {
      return -1;
    }

    long leftWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 2);
    if (leftWidth < 1) {
      return -1;
    }

    if (
      signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 2) == false
    ) {
      return -1;
    }

    long equalityStart = statementStart + 2 + leftWidth;
    if (
      punctuationAt(source, tokenKinds, tokenStarts, equalityStart, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, equalityStart + 1, PUNCTUATION_ASSIGN) == false
    ) {
      return -1;
    }

    long rightStart = equalityStart + 2;
    long rightWidth = signedNumberWidth(source, tokenKinds, tokenStarts, rightStart);
    if (rightWidth < 1) {
      return -1;
    }

    if (signedNumberValid(source, tokenStarts, tokenLengths, rightStart) == false) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightStart + rightWidth,
        PUNCTUATION_CLOSE_PAREN
      ) == false
    ) {
      return -1;
    }

    if (
      punctuationAt(
        source,
        tokenKinds,
        tokenStarts,
        rightStart + rightWidth + 1,
        PUNCTUATION_SEMICOLON
      )
    ) {
      return rightStart + rightWidth + 2 - statementStart;
    }

    return -1;
  }

}
