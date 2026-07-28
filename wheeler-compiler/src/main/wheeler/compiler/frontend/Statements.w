//! Parses and sizes bounded bootstrap statements.

module wheeler.compiler.statements;

import wheeler.compiler.conditionals;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.tokens;

classical class Statements {
  /// Returns the token width of one bounded source statement.
  public long statementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart
  ) {
    long statementKind = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (statementKind == STATEMENT_RETURN_LONG) {
      return helperValueStatementWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart,
        statementKind
      );
    }

    if (statementKind == STATEMENT_LOCAL_CALL_NAMED) {
      return helperValueStatementWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart,
        statementKind
      );
    }

    if (namedLiteralComparisonConditional(statementKind)) {
      return literalComparisonConditionalWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart,
        statementKind
      );
    }

    if (namedLocalConditional(statementKind)) {
      return conditionalStatementWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart,
        statementKind
      );
    }

    if (statementKind == STATEMENT_ASSERT_LITERAL_EQ) {
      return literalEqualityStatementWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart
      );
    }

    boolean signedAssertion = statementKind == STATEMENT_ASSERT_EQ;
    if (statementKind == STATEMENT_ASSERT_NAMED_LONG) {
      signedAssertion = true;
    }

    if (statementKind == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
      signedAssertion = true;
    }

    if (statementKind == STATEMENT_ASSERT_LONG_LT_NAMED) {
      signedAssertion = true;
    }

    if (signedAssertion) {
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
          boolean acceptedName = statementKind == STATEMENT_ASSERT_NAMED_LONG;
          if (statementKind == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
            acceptedName = true;
          }

          if (statementKind == STATEMENT_ASSERT_LONG_LT_NAMED) {
            acceptedName = true;
          }

          if (
            sameTokenText(source, tokenStarts, tokenLengths, 6, statementStart + 2)
          ) {
            acceptedName = true;
          }

          if (acceptedName) {
            if (statementKind == STATEMENT_ASSERT_LONG_LT_NAMED) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 3,
                  PUNCTUATION_LESS_THAN
                )
              ) {
                if (tokenKinds[statementStart + 4] == 1) {
                  if (
                    punctuationAt(
                      source,
                      tokenKinds,
                      tokenStarts,
                      statementStart + 5,
                      PUNCTUATION_CLOSE_PAREN
                    )
                  ) {
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
                }
              }

              return -1;
            }

            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 3,
                PUNCTUATION_ASSIGN
              )
            ) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 4,
                  PUNCTUATION_ASSIGN
                )
              ) {
                if (statementKind == STATEMENT_ASSERT_LOCAL_PAIR_NAMED) {
                  if (tokenKinds[statementStart + 5] == 1) {
                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 6,
                        PUNCTUATION_CLOSE_PAREN
                      )
                    ) {
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
                    }
                  }

                  return -1;
                }

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
                        PUNCTUATION_CLOSE_PAREN
                      )
                    ) {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          statementStart + 6 + assertWidth,
                          PUNCTUATION_SEMICOLON
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

    boolean signedDeclaration = statementKind == STATEMENT_LOCAL_LONG;
    if (statementKind == STATEMENT_LOCAL_LONG_NAMED) {
      signedDeclaration = true;
    }

    if (namedLongBinary(statementKind)) {
      signedDeclaration = true;
    }

    if (namedLongPair(statementKind)) {
      signedDeclaration = true;
    }

    if (signedDeclaration) {
      if (tokenKinds[statementStart + 1] == 1) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 2,
            PUNCTUATION_ASSIGN
          )
        ) {
          if (statementKind == STATEMENT_LOCAL_LONG_NAMED) {
            if (tokenKinds[statementStart + 3] == 1) {
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

            return -1;
          }

          if (namedLongPair(statementKind)) {
            if (tokenKinds[statementStart + 3] == 1) {
              if (tokenKinds[statementStart + 5] == 1) {
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
            }

            return -1;
          }

          if (namedLongBinary(statementKind)) {
            if (tokenKinds[statementStart + 3] == 1) {
              long binaryWidth = signedNumberWidth(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 5
              );
              if (0 < binaryWidth) {
                if (
                  signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5)
                ) {
                  if (
                    punctuationAt(
                      source,
                      tokenKinds,
                      tokenStarts,
                      statementStart + 5 + binaryWidth,
                      PUNCTUATION_SEMICOLON
                    )
                  ) {
                    return 6 + binaryWidth;
                  }
                }
              }
            }

            return -1;
          }

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
                  PUNCTUATION_SEMICOLON
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

    boolean booleanDeclaration = statementKind == STATEMENT_LOCAL_BOOLEAN;
    if (statementKind == STATEMENT_LOCAL_BOOLEAN_NAMED) {
      booleanDeclaration = true;
    }

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
      booleanDeclaration = true;
    }

    if (statementKind == STATEMENT_LOCAL_LONG_LT_NAMED) {
      booleanDeclaration = true;
    }

    if (statementKind == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
      booleanDeclaration = true;
    }

    if (statementKind == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
      booleanDeclaration = true;
    }

    if (booleanDeclaration) {
      if (tokenKinds[statementStart + 1] == 1) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 2,
            PUNCTUATION_ASSIGN
          )
        ) {
          if (statementKind == STATEMENT_LOCAL_LONG_LT_LITERAL_NAMED) {
            if (tokenKinds[statementStart + 3] == 1) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 4,
                  PUNCTUATION_LESS_THAN
                )
              ) {
                long lessThanWidth = signedNumberWidth(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 5
                );
                if (0 < lessThanWidth) {
                  if (
                    signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 5)
                  ) {
                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        statementStart + 5 + lessThanWidth,
                        PUNCTUATION_SEMICOLON
                      )
                    ) {
                      return 6 + lessThanWidth;
                    }
                  }
                }
              }
            }

            return -1;
          }

          if (statementKind == STATEMENT_LOCAL_LONG_LT_NAMED) {
            if (tokenKinds[statementStart + 3] == 1) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 4,
                  PUNCTUATION_LESS_THAN
                )
              ) {
                if (tokenKinds[statementStart + 5] == 1) {
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
              }
            }

            return -1;
          }

          if (statementKind == STATEMENT_LOCAL_LONG_EQ_LITERAL_NAMED) {
            if (tokenKinds[statementStart + 3] == 1) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 4,
                  PUNCTUATION_ASSIGN
                )
              ) {
                if (
                  punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    statementStart + 5,
                    PUNCTUATION_ASSIGN
                  )
                ) {
                  long equalityWidth = signedNumberWidth(
                    source,
                    tokenKinds,
                    tokenStarts,
                    statementStart + 6
                  );
                  if (0 < equalityWidth) {
                    if (
                      signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 6)
                    ) {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          statementStart + 6 + equalityWidth,
                          PUNCTUATION_SEMICOLON
                        )
                      ) {
                        return 7 + equalityWidth;
                      }
                    }
                  }
                }
              }
            }

            return -1;
          }

          if (statementKind == STATEMENT_LOCAL_BOOLEAN_EQ_NAMED) {
            if (tokenKinds[statementStart + 3] == 1) {
              if (
                punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementStart + 4,
                  PUNCTUATION_ASSIGN
                )
              ) {
                if (
                  punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    statementStart + 5,
                    PUNCTUATION_ASSIGN
                  )
                ) {
                  if (tokenKinds[statementStart + 6] == 1) {
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
                  }
                }
              }
            }

            return -1;
          }

          if (statementKind == STATEMENT_LOCAL_BOOLEAN_NAMED) {
            if (tokenKinds[statementStart + 3] == 1) {
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

            return -1;
          }

          // `true` and `false` use the same stable token hash as every keyword.
          long booleanLiteralHash = tokenHash(
            source,
            tokenStarts,
            tokenLengths,
            statementStart + 3
          );
          if (booleanLiteralHash == TOKEN_TRUE) {
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

          if (booleanLiteralHash == TOKEN_FALSE) {
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

    boolean negatedBooleanDeclaration = statementKind == STATEMENT_LOCAL_BOOLEAN_NOT;
    if (statementKind == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
      negatedBooleanDeclaration = true;
    }

    if (negatedBooleanDeclaration) {
      if (tokenKinds[statementStart + 1] == 1) {
        if (
          punctuationAt(
            source,
            tokenKinds,
            tokenStarts,
            statementStart + 2,
            PUNCTUATION_ASSIGN
          )
        ) {
          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              statementStart + 3,
              PUNCTUATION_BANG
            )
          ) {
            if (statementKind == STATEMENT_LOCAL_BOOLEAN_NOT_NAMED) {
              if (tokenKinds[statementStart + 4] == 1) {
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

              return -1;
            }

            long negatedLiteralHash = tokenHash(
              source,
              tokenStarts,
              tokenLengths,
              statementStart + 4
            );
            if (negatedLiteralHash == TOKEN_TRUE) {
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

            if (negatedLiteralHash == TOKEN_FALSE) {
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

    if (tokenKinds[statementStart] == 1) {
      if (sameTokenText(source, tokenStarts, tokenLengths, 6, statementStart)) {
        long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
        if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
          if (tokenKinds[statementStart + 2] == 1) {
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
          }

          return -1;
        }

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
                  PUNCTUATION_SEMICOLON
                )
              ) {
                return 3 + operandWidth;
              }
            }
          }
        }

        if (0 < opcode) {
          if (namedGlobalUpdate(opcode)) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                statementStart + 2,
                PUNCTUATION_ASSIGN
              )
            ) {
              if (tokenKinds[statementStart + 3] == 1) {
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

            return -1;
          }

          if (
            punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              statementStart + 2,
              PUNCTUATION_ASSIGN
            )
          ) {
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
                    PUNCTUATION_SEMICOLON
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

}
