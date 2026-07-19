//! Parses and sizes bounded bootstrap statements.

module wheeler.compiler.statements;

import wheeler.compiler.tokens;

classical class Statements {
  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
    if (opcode == STATEMENT_ASSERT_EQ) {
      return 0;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return 2;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return 4;
    }

    if (opcode == STATEMENT_ASSIGN) {
      return 1;
    }

    if (opcode == STATEMENT_UPDATE_ADD) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_SUB) {
      return 2;
    }

    if (opcode == STATEMENT_UPDATE_XOR) {
      return 2;
    }

    return 0;
  }

  /// Returns the initialized result local for a declaration statement.
  public long statementResultLocal(long opcode, long localBase) {
    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return localBase + 3;
    }

    return -1;
  }

  /// Returns the token width of one bounded source statement.
  public long statementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long statementKind = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (statementKind == STATEMENT_ASSERT_EQ) {
      if (punctuationAt(source, tokenKinds, tokenStarts, statementStart + 1, 40)) {
        if (tokenKinds[statementStart + 2] == 1) {
          if (
            sameTokenText(source, tokenStarts, tokenLengths, 6, statementStart + 2)
          ) {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, statementStart + 3, 61)
            ) {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, 61)
              ) {
                long assertWidth = signedNumberWidth(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 5
                );
                if (0 < assertWidth) {
                  if (
                    signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5)
                  ) {
                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 5 + assertWidth,
                        41
                      )
                    ) {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          statementStart + 6 + assertWidth,
                          59
                        )
                      ) {
                        return 7 + assertWidth;
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_ASSERT_BOOLEAN) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1,
          PUNCTUATION_OPEN_PAREN
        )
      ) {
        long assertBooleanHash = tokenHash(
          source,
          tokenStarts,
          tokenLengths,
          statementStart + 2
        );
        boolean acceptedBoolean = assertBooleanHash == TOKEN_TRUE;
        if (assertBooleanHash == TOKEN_FALSE) {
          acceptedBoolean = true;
        }

        if (acceptedBoolean) {
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
          }
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_ASSERT_BOOLEAN_NOT) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1,
          PUNCTUATION_OPEN_PAREN
        )
      ) {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_BANG)
        ) {
          long assertNegatedHash = tokenHash(
            source,
            tokenStarts,
            tokenLengths,
            statementStart + 3
          );
          boolean acceptedNegated = assertNegatedHash == TOKEN_TRUE;
          if (assertNegatedHash == TOKEN_FALSE) {
            acceptedNegated = true;
          }

          if (acceptedNegated) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 4,
                PUNCTUATION_CLOSE_PAREN
              )
            ) {
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
            }
          }
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      if (
        punctuationAt(
          source,
          tokenKinds,
          tokenStarts,
          statementStart + 1,
          PUNCTUATION_OPEN_PAREN
        )
      ) {
        if (tokenKinds[statementStart + 2] == 1) {
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
          }
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_LOCAL_LONG) {
      if (tokenKinds[statementStart + 1] == 1) {
        if (punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, 61)) {
          long localWidth = signedNumberWidth(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 3
          );
          if (0 < localWidth) {
            if (
              signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 3)
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 3 + localWidth,
                  59
                )
              ) {
                return 4 + localWidth;
              }
            }
          }
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN) {
      if (tokenKinds[statementStart + 1] == 1) {
        if (punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, 61)) {
          // `true` and `false` use the same stable token hash as every keyword.
          long booleanLiteralHash = tokenHash(
            source,
            tokenStarts,
            tokenLengths,
            statementStart + 3
          );
          if (booleanLiteralHash == TOKEN_TRUE) {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, 59)
            ) {
              return 5;
            }
          }

          if (booleanLiteralHash == TOKEN_FALSE) {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, statementStart + 4, 59)
            ) {
              return 5;
            }
          }
        }
      }

      return -1;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_NOT) {
      if (tokenKinds[statementStart + 1] == 1) {
        if (punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, 61)) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              statementStart + 3,
              PUNCTUATION_BANG
            )
          ) {
            long negatedLiteralHash = tokenHash(
              source,
              tokenStarts,
              tokenLengths,
              statementStart + 4
            );
            if (negatedLiteralHash == TOKEN_TRUE) {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, statementStart + 5, 59)
              ) {
                return 6;
              }
            }

            if (negatedLiteralHash == TOKEN_FALSE) {
              if (
                punctuationAt(source, tokenKinds, tokenStarts, statementStart + 5, 59)
              ) {
                return 6;
              }
            }
          }
        }
      }

      return -1;
    }

    if (tokenKinds[statementStart] == 1) {
      if (sameTokenText(source, tokenStarts, tokenLengths, 6, statementStart)) {
        long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
        if (opcode == 0) {
          long operandWidth = signedNumberWidth(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 2
          );
          if (0 < operandWidth) {
            if (
              signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 2)
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 2 + operandWidth,
                  59
                )
              ) {
                return 3 + operandWidth;
              }
            }
          }
        }

        if (0 < opcode) {
          if (punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, 61)) {
            long updateOperandWidth = signedNumberWidth(
              source,
              tokenKinds,
              tokenStarts,
              statementStart + 3
            );
            if (0 < updateOperandWidth) {
              if (
                signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 3)
              ) {
                if (
                  punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    statementStart + 3 + updateOperandWidth,
                    59
                  )
                ) {
                  return 4 + updateOperandWidth;
                }
              }
            }
          }
        }
      }
    }

    return -1;
  }

  /// Decodes the canonical operand carried by one validated statement.
  public long statementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    long operandToken = statementOperandToken(source, tokenStarts, tokenLengths, statementStart);
    boolean booleanLiteral = opcode == STATEMENT_LOCAL_BOOLEAN;
    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      booleanLiteral = true;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      booleanLiteral = true;
    }

    if (booleanLiteral) {
      long literal = tokenHash(source, tokenStarts, tokenLengths, operandToken);
      if (literal == TOKEN_TRUE) {
        return 1;
      }

      return 0;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return -1;
    }

    return parsedSignedNumber(source, tokenStarts, tokenLengths, operandToken);
  }

  /// Returns the operand-token offset for one bounded statement.
  public long statementOperandToken(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_ASSIGN) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_ASSERT_EQ) {
      return statementStart + 5;
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN_NOT) {
      return statementStart + 4;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN) {
      return statementStart + 2;
    }

    if (opcode == STATEMENT_ASSERT_BOOLEAN_NOT) {
      return statementStart + 3;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return statementStart + 2;
    }

    return statementStart + 3;
  }
}
