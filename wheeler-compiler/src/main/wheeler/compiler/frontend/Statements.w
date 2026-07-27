//! Parses and sizes bounded bootstrap statements.

module wheeler.compiler.statements;

import wheeler.compiler.ir;
import wheeler.compiler.tokens;

classical class Statements {
  private boolean namedLongBinary(long opcode) {
    if (opcode == STATEMENT_LOCAL_LONG_ADD_NAMED) {
      return true;
    }

    if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_LONG_XOR_NAMED;
  }

  private boolean declarationMatches(long opcode, boolean signed) {
    if (signed) {
      if (opcode == STATEMENT_LOCAL_LONG) {
        return true;
      }

      if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
        return true;
      }

      return namedLongBinary(opcode);
    }

    if (opcode == STATEMENT_LOCAL_BOOLEAN) {
      return true;
    }

    return opcode == STATEMENT_LOCAL_BOOLEAN_NOT;
  }

  private long resolvePriorDeclaration(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words previousStarts,
    long previousCount,
    long assertedName,
    boolean signed
  ) {
    if (previousCount < 0) {
      return -1;
    }

    if (MAX_MINIMAL_STATEMENTS < previousCount) {
      return -1;
    }

    long localBase = 0;
    long matchedLocal = -1;
    long matchCount = 0;
    long previous = 0;
    while (previous < previousCount) limit MAX_MINIMAL_STATEMENTS {
      long previousStart = previousStarts[previous];
      if (0 < previousStart) {
        long previousOpcode = statementOpcode(source, tokenStarts, tokenLengths, previousStart);
        if (declarationMatches(previousOpcode, signed)) {
          if (
            sameTokenText(source, tokenStarts, tokenLengths, previousStart + 1, assertedName)
          ) {
            matchedLocal = statementResultLocal(previousOpcode, localBase);
            matchCount += 1;
          }
        }

        localBase += statementLocalCount(previousOpcode);
      }

      previous += 1;
    }

    if (matchCount == 1) {
      return matchedLocal;
    }

    return -1;
  }

  /// Checks whether an opcode carries one resolved signed-local identity.
  public boolean resolvedLocalLongAssertion(long opcode) {
    if (opcode < STATEMENT_ASSERT_LOCAL_LONG_BASE) {
      return false;
    }

    return opcode < STATEMENT_ASSERT_LOCAL_LONG_BASE + 256;
  }

  /// Checks whether an opcode carries one resolved signed-local copy source.
  public boolean resolvedLocalLongCopy(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_COPY_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_COPY_BASE + 256;
  }

  /// Checks whether an opcode carries a resolved signed-local binary source.
  public boolean resolvedLocalLongBinary(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_ADD_BASE) {
      return false;
    }

    return opcode < STATEMENT_LOCAL_LONG_XOR_BASE + 256;
  }

  /// Returns the source local carried by a resolved signed binary opcode.
  public long resolvedLocalLongBinarySource(long opcode) {
    if (opcode < STATEMENT_LOCAL_LONG_SUB_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_ADD_BASE;
    }

    if (opcode < STATEMENT_LOCAL_LONG_XOR_BASE) {
      return opcode - STATEMENT_LOCAL_LONG_SUB_BASE;
    }

    return opcode - STATEMENT_LOCAL_LONG_XOR_BASE;
  }

  /// Resolves named signed operations into opcodes carrying local indices.
  public long sequenceStatementOpcode(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      long local = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        true
      );
      if (-1 < local) {
        return STATEMENT_ASSERT_LOCAL_LONG_BASE + local;
      }

      return -1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      long sourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < sourceLocal) {
        return STATEMENT_LOCAL_LONG_COPY_BASE + sourceLocal;
      }

      return -1;
    }

    if (namedLongBinary(opcode)) {
      long binarySourceLocal = resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 3,
        true
      );
      if (-1 < binarySourceLocal) {
        long base = STATEMENT_LOCAL_LONG_ADD_BASE;
        if (opcode == STATEMENT_LOCAL_LONG_SUB_NAMED) {
          base = STATEMENT_LOCAL_LONG_SUB_BASE;
        }

        if (opcode == STATEMENT_LOCAL_LONG_XOR_NAMED) {
          base = STATEMENT_LOCAL_LONG_XOR_BASE;
        }

        return base + binarySourceLocal;
      }

      return -1;
    }

    return opcode;
  }

  /// Checks whether a resolved statement operand names a valid prior local.
  public boolean sequenceOperandValid(long opcode, long operand) {
    if (opcode < 0) {
      return false;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return -1 < operand;
    }

    return true;
  }

  /// Resolves one statement operand against a bounded prior-declaration table.
  public long sequenceStatementOperand(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long statementStart,
    borrow mut words previousStarts,
    long previousCount
  ) {
    long opcode = statementOpcode(source, tokenStarts, tokenLengths, statementStart);
    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return 0;
    }

    if (opcode == STATEMENT_ASSERT_LOCAL_BOOLEAN) {
      return resolvePriorDeclaration(
        source,
        tokenStarts,
        tokenLengths,
        previousStarts,
        previousCount,
        statementStart + 2,
        false
      );
    }

    return statementOperand(source, tokenStarts, tokenLengths, statementStart);
  }

  /// Returns the typed-local width required by one parsed statement.
  public long statementLocalCount(long opcode) {
    if (resolvedLocalLongAssertion(opcode)) {
      return 3;
    }

    if (resolvedLocalLongCopy(opcode)) {
      return 2;
    }

    if (resolvedLocalLongBinary(opcode)) {
      return 4;
    }

    if (namedLongBinary(opcode)) {
      return 4;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return 2;
    }

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return 3;
    }

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
    if (opcode == STATEMENT_LOCAL_LONG) {
      return localBase + 1;
    }

    if (opcode == STATEMENT_LOCAL_LONG_NAMED) {
      return localBase + 1;
    }

    if (namedLongBinary(opcode)) {
      return localBase + 3;
    }

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
    boolean signedAssertion = statementKind == STATEMENT_ASSERT_EQ;
    if (statementKind == STATEMENT_ASSERT_NAMED_LONG) {
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
          if (
            sameTokenText(source, tokenStarts, tokenLengths, 6, statementStart + 2)
          ) {
            acceptedName = true;
          }

          if (acceptedName) {
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

    if (statementKind == STATEMENT_LOCAL_BOOLEAN) {
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

    if (statementKind == STATEMENT_LOCAL_BOOLEAN_NOT) {
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

    if (opcode == STATEMENT_ASSERT_NAMED_LONG) {
      return statementStart + 5;
    }

    if (namedLongBinary(opcode)) {
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
