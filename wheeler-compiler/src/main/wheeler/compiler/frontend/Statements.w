//! Parses and sizes bounded bootstrap statements.

module wheeler.compiler.statements;

import wheeler.compiler.boolean_declaration_kinds;
import wheeler.compiler.boolean_declaration_widths;
import wheeler.compiler.conditionals;
import wheeler.compiler.early_return_forms;
import wheeler.compiler.early_return_kinds;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.loop_forms;
import wheeler.compiler.named_literal_comparison_kinds;
import wheeler.compiler.named_local_assignment_kinds;
import wheeler.compiler.named_local_conditional_kinds;
import wheeler.compiler.named_local_update_kinds;
import wheeler.compiler.named_long_operations;
import wheeler.compiler.statement_forms;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.structure;
import wheeler.compiler.tokens;

classical class Statements {
  private long localAssignmentWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 1, PUNCTUATION_ASSIGN)
        == false
    ) {
      return -1;
    }

    if (opcode == STATEMENT_ASSIGN_LOCAL_NAMED) {
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

    long operandWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 2);
    if (operandWidth < 1) {
      return -1;
    }

    if (
      signedNumberValid(source, tokenStarts, tokenLengths, statementStart + 2) == false
    ) {
      return -1;
    }

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

    return -1;
  }

  private long localUpdateWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    long opcode
  ) {
    if (
      punctuationAt(source, tokenKinds, tokenStarts, statementStart + 2, PUNCTUATION_ASSIGN)
        == false
    ) {
      return -1;
    }

    if (namedGlobalUpdate(opcode)) {
      if (tokenKinds[statementStart + 3] == 1) {} else {
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

    long operandWidth = signedNumberWidth(source, tokenKinds, tokenStarts, statementStart + 3);
    if (operandWidth < 1) {
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
        statementStart + 3 + operandWidth,
        PUNCTUATION_SEMICOLON
      )
    ) {
      return 4 + operandWidth;
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
    boolean helperGuard = statementKind == STATEMENT_IF_HELPER_CALL_RETURN_TRUE_NAMED;
    if (statementKind == STATEMENT_IF_HELPER_CALL_RETURN_FALSE_NAMED) {
      helperGuard = true;
    }

    if (statementKind == STATEMENT_IF_HELPER_CALL_RETURN_LONG_NAMED) {
      helperGuard = true;
    }

    if (helperGuard) {
      return earlyHelperReturnWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart
      );
    }

    if (earlyReturnStatement(statementKind)) {
      return earlyComparisonReturnWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart
      );
    }

    if (statementKind == STATEMENT_WHILE_LOCAL_LT_UPDATE_NAMED) {
      return whileStatementWidth(source, tokenKinds, tokenStarts, tokenLengths, statementStart);
    }

    if (helperValueStatement(statementKind)) {
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
            sameTokenText(
              source,
              tokenStarts,
              tokenLengths,
              COMPILER_GLOBAL_NAME_TOKEN,
              statementStart + 2
            )
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
                boolean assertValueValid = false;
                if (0 < assertWidth) {
                  assertValueValid = signedNumberValid(
                    source,
                    tokenStarts,
                    tokenLengths,
                    statementStart + 5
                  );
                }

                if (statementKind == STATEMENT_ASSERT_EQ) {
                  if (tokenKinds[statementStart + 5] == 1) {
                    assertWidth = 1;
                    assertValueValid = true;
                  }
                }

                if (assertValueValid) {
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

    if (booleanDeclarationStatement(statementKind)) {
      return booleanDeclarationWidth(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        statementStart,
        statementKind
      );
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
      long targetOpcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
      if (
        sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          COMPILER_GLOBAL_NAME_TOKEN,
          statementStart
        ) == false
      ) {
        if (localAssignmentSourceStatement(targetOpcode)) {
          return localAssignmentWidth(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            statementStart,
            targetOpcode
          );
        }

        if (localUpdateSourceStatement(targetOpcode)) {
          return localUpdateWidth(
            source,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            statementStart,
            targetOpcode
          );
        }
      }

      if (
        sameTokenText(
          source,
          tokenStarts,
          tokenLengths,
          COMPILER_GLOBAL_NAME_TOKEN,
          statementStart
        )
      ) {
        long opcode = targetOpcode;
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
