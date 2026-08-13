//! Resolves direct loop-body declarations and updates against callable values.

module wheeler.compiler.closure.resolved_loop_body_products;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ResolvedLoopBodyProducts {
  private const long BODY_ROWS = 20480;
  private const long BODY_LOCAL_BASE_ROW = 4096;
  private const long BODY_OPCODE_ROW = 8192;
  private const long BODY_ASSERT_EQ_LITERAL_BASE = 32768;
  private const long BODY_ASSERT_LT_LITERAL_BASE = 33024;
  private const long BODY_BOOLEAN_LITERAL = 33280;
  private const long BODY_ASSERT_BOOLEAN = 33281;
  private const long BODY_ASSIGN_BOOLEAN_LITERAL_BASE = 33536;
  private const long BODY_ASSIGN_BOOLEAN_LOCAL_BASE = 33792;
  private const long BODY_WORDS_GET = 34048;
  private const long BODY_WORDS_SET = 34049;
  private const long BODY_OPERAND_KIND_ROW = 12288;
  private const long BODY_OPERAND_ROW = 16384;
  private const long MAX_LOCALS = 256;
  private const long MAX_STATEMENTS = 4096;
  private const long OPERAND_LITERAL = 0;
  private const long OPERAND_LOCAL = 1;
  private const long RESOLUTION_ARENA_BYTES = 460288;
  private const long STATEMENT_ROWS = 28672;
  private const long STATEMENT_ORDINAL_ROW = 8192;
  private const long STATEMENT_START_ROW = 12288;
  private const long STATEMENT_LENGTH_ROW = 16384;
  private const long STATEMENT_CHILD_COUNT_ROW = 24576;
  private const long VALUE_COUNT_LIMIT = 1024;
  private const long VALUE_ROWS = 7168;

  /// Reports one complete direct body-statement resolution pass.
  public record ResolvedLoopBodyPlan(long bodyCount, boolean valid) {}

  /// Publishes resolved declaration and update rows only after every body statement validates.
  public ResolvedLoopBodyPlan materializeResolvedLoopBodyProducts(
    borrow utf8 source,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words bodyRows
  ) {
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(bodyRows) == BODY_ROWS);

    region staging = new region(/* bytes= */ RESOLUTION_ARENA_BYTES, /* allocations= */ 5);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, BODY_ROWS);
    words nextBodyLocals = allocate(staging, 64);
    boolean valid = true;
    long tokenCount = 0;
    ScanResult scanned = scan(source, tokenKinds, tokenStarts, tokenLengths);
    match (scanned) {
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        valid = false;
        tokenCount = diagnostic.offset - diagnostic.offset;
      }
      case ScanResult.Value(long scannedCount) {
        tokenCount = scannedCount;
      }
    }

    long semanticCount = compactLoopBodyTokens(
      tokenCount,
      tokenKinds,
      tokenStarts,
      tokenLengths
    );

    long bodyCount = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      long childCount = statementRows[STATEMENT_CHILD_COUNT_ROW + statement];
      if (0 < statementRows[4096 + statement]) {
        if (childCount != 0) {
          valid = false;
        } else {
          long owner = statementRows[statement];
          long ordinal = statementRows[STATEMENT_ORDINAL_ROW + statement];
          long start = statementRows[STATEMENT_START_ROW + statement];
          long length = statementRows[STATEMENT_LENGTH_ROW + statement];
          long token = tokenAtStart(start, semanticCount, tokenStarts);
          boolean statementValid = -1 < token;
          if (length < 2) {
            statementValid = false;
          }

          long localBase = localBaseAtOrdinal(owner, ordinal, valueCount, valueRows);
          if (localBase < nextBodyLocals[owner]) {
            localBase = nextBodyLocals[owner];
          }

          long opcode = -1;
          long operandKind = OPERAND_LITERAL;
          long operand = 0;
          if (statementValid) {
            long statementHash = tokenHash(source, tokenStarts, tokenLengths, token);
            if (statementHash == TOKEN_BOOLEAN) {
              if (tokenKinds[token + 1] != 1) {
                statementValid = false;
              }

              if (
                punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN)
                  == false
              ) {
                statementValid = false;
              }

              if (statementValid) {
                LoopBodyValue booleanDeclaration = resolveLoopBodyValue(
                  source,
                  tokenStarts[token + 1],
                  tokenLengths[token + 1],
                  owner,
                  ordinal + 1,
                  valueCount,
                  valueRows
                );
                if (booleanDeclaration.valid) {
                  localBase = booleanDeclaration.local - 1;
                } else {
                  statementValid = false;
                }

                long literal = tokenHash(source, tokenStarts, tokenLengths, token + 3);
                if (literal == TOKEN_TRUE) {
                  opcode = BODY_BOOLEAN_LITERAL;
                  operand = 1;
                } else {
                  if (literal == TOKEN_FALSE) {
                    opcode = BODY_BOOLEAN_LITERAL;
                    operand = 0;
                  } else {
                    statementValid = false;
                  }
                }
              }
            } else {
              if (statementHash == TOKEN_LONG) {
                if (tokenKinds[token + 1] != 1) {
                  statementValid = false;
                }

                if (
                  punctuationAt(source, tokenKinds, tokenStarts, token + 2, PUNCTUATION_ASSIGN)
                    == false
                ) {
                  statementValid = false;
                }

                if (statementValid) {
                  LoopBodyValue declaration = resolveLoopBodyValue(
                    source,
                    tokenStarts[token + 1],
                    tokenLengths[token + 1],
                    owner,
                    ordinal + 1,
                    valueCount,
                    valueRows
                  );
                  if (declaration.valid) {
                    localBase = declaration.local - 1;
                  } else {
                    statementValid = false;
                  }

                  long sourceToken = token + 3;
                  if (tokenKinds[sourceToken] == 1) {
                    LoopBodyValue sourceValue = resolveLoopBodyValue(
                      source,
                      tokenStarts[sourceToken],
                      tokenLengths[sourceToken],
                      owner,
                      ordinal,
                      valueCount,
                      valueRows
                    );
                    if (sourceValue.valid) {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          sourceToken + 1,
                          PUNCTUATION_OPEN_SQUARE
                        )
                      ) {
                        LoopBodyValue indexValue = resolveLoopBodyValue(
                          source,
                          tokenStarts[sourceToken + 2],
                          tokenLengths[sourceToken + 2],
                          owner,
                          ordinal,
                          valueCount,
                          valueRows
                        );
                        if (indexValue.valid) {
                          if (
                            loopBodyValueType(
                              source,
                              owner,
                              sourceValue.local,
                              valueCount,
                              valueRows,
                              semanticCount,
                              tokenStarts,
                              tokenLengths
                            ) == TOKEN_WORDS
                          ) {
                            if (
                              loopBodyValueType(
                                source,
                                owner,
                                indexValue.local,
                                valueCount,
                                valueRows,
                                semanticCount,
                                tokenStarts,
                                tokenLengths
                              ) == TOKEN_LONG
                            ) {
                              if (
                                punctuationAt(
                                  source,
                                  tokenKinds,
                                  tokenStarts,
                                  sourceToken + 3,
                                  PUNCTUATION_CLOSE_SQUARE
                                )
                              ) {
                                localBase = localBase - 1;
                                opcode = BODY_WORDS_GET;
                                operand = sourceValue.local * 256 + indexValue.local;
                              } else {
                                statementValid = false;
                              }
                            } else {
                              statementValid = false;
                            }
                          } else {
                            statementValid = false;
                          }
                        } else {
                          statementValid = false;
                        }
                      } else {
                        if (
                          loopBodyValueType(
                            source,
                            owner,
                            sourceValue.local,
                            valueCount,
                            valueRows,
                            semanticCount,
                            tokenStarts,
                            tokenLengths
                          ) == TOKEN_LONG
                        ) {
                          opcode = STATEMENT_LOCAL_LONG_COPY_BASE + sourceValue.local;
                          operandKind = OPERAND_LOCAL;
                          operand = sourceValue.local;
                        } else {
                          statementValid = false;
                        }
                      }
                    } else {
                      statementValid = false;
                    }
                  } else {
                    if (
                      signedNumberWidth(source, tokenKinds, tokenStarts, sourceToken) != 1
                    ) {
                      statementValid = false;
                    } else {
                      if (
                        signedNumberValid(source, tokenStarts, tokenLengths, sourceToken)
                      ) {
                        opcode = STATEMENT_LOCAL_LONG;
                        operand = parsedSignedNumber(
                          source,
                          tokenStarts,
                          tokenLengths,
                          sourceToken
                        );
                      } else {
                        statementValid = false;
                      }
                    }
                  }
                }
              } else {
                if (tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_SET) {
                  LoopBodyValue writeOwner = resolveLoopBodyValue(
                    source,
                    tokenStarts[token + 2],
                    tokenLengths[token + 2],
                    owner,
                    ordinal,
                    valueCount,
                    valueRows
                  );
                  LoopBodyValue writeIndex = resolveLoopBodyValue(
                    source,
                    tokenStarts[token + 4],
                    tokenLengths[token + 4],
                    owner,
                    ordinal,
                    valueCount,
                    valueRows
                  );
                  LoopBodyValue writeValue = resolveLoopBodyValue(
                    source,
                    tokenStarts[token + 6],
                    tokenLengths[token + 6],
                    owner,
                    ordinal,
                    valueCount,
                    valueRows
                  );
                  if (writeOwner.valid == false) {
                    statementValid = false;
                  }

                  if (writeIndex.valid == false) {
                    statementValid = false;
                  }

                  if (writeValue.valid == false) {
                    statementValid = false;
                  }

                  if (statementValid) {
                    if (
                      loopBodyValueType(
                        source,
                        owner,
                        writeOwner.local,
                        valueCount,
                        valueRows,
                        semanticCount,
                        tokenStarts,
                        tokenLengths
                      ) == TOKEN_WORDS == false
                    ) {
                      statementValid = false;
                    }

                    if (
                      loopBodyValueType(
                        source,
                        owner,
                        writeIndex.local,
                        valueCount,
                        valueRows,
                        semanticCount,
                        tokenStarts,
                        tokenLengths
                      ) == TOKEN_LONG == false
                    ) {
                      statementValid = false;
                    }

                    if (
                      loopBodyValueType(
                        source,
                        owner,
                        writeValue.local,
                        valueCount,
                        valueRows,
                        semanticCount,
                        tokenStarts,
                        tokenLengths
                      ) == TOKEN_LONG == false
                    ) {
                      statementValid = false;
                    }
                  }

                  if (statementValid) {
                    opcode = BODY_WORDS_SET;
                    operand = writeOwner.local * 65536 + writeIndex.local * 256 + writeValue.local;
                  }
                } else {
                  if (
                    tokenHash(source, tokenStarts, tokenLengths, token) == TOKEN_ASSERT
                  ) {
                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        token + 1,
                        PUNCTUATION_OPEN_PAREN
                      ) == false
                    ) {
                      statementValid = false;
                    }

                    long assertionLeftToken = token + 2;
                    if (tokenKinds[assertionLeftToken] != 1) {
                      statementValid = false;
                    }

                    LoopBodyValue assertionLeft = resolveLoopBodyValue(
                      source,
                      tokenStarts[assertionLeftToken],
                      tokenLengths[assertionLeftToken],
                      owner,
                      ordinal,
                      valueCount,
                      valueRows
                    );
                    if (assertionLeft.valid == false) {
                      statementValid = false;
                    }

                    long comparisonToken = assertionLeftToken + 1;
                    long assertionSourceToken = comparisonToken + 1;
                    long assertionBase = -1;
                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        comparisonToken,
                        PUNCTUATION_CLOSE_PAREN
                      )
                    ) {
                      opcode = BODY_ASSERT_BOOLEAN;
                      operandKind = OPERAND_LOCAL;
                      operand = assertionLeft.local;
                      assertionBase = BODY_ASSERT_BOOLEAN;
                    }

                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        comparisonToken,
                        PUNCTUATION_LESS_THAN
                      )
                    ) {
                      assertionBase = BODY_ASSERT_LT_LITERAL_BASE;
                    } else {
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          comparisonToken,
                          PUNCTUATION_ASSIGN
                        )
                      ) {
                        if (
                          punctuationAt(
                            source,
                            tokenKinds,
                            tokenStarts,
                            comparisonToken + 1,
                            PUNCTUATION_ASSIGN
                          )
                        ) {
                          assertionBase = BODY_ASSERT_EQ_LITERAL_BASE;
                          assertionSourceToken += 1;
                        }
                      }
                    }

                    if (assertionBase < 0) {
                      statementValid = false;
                    } else {
                      if (assertionBase != BODY_ASSERT_BOOLEAN) {
                        if (
                          signedNumberWidth(
                            source,
                            tokenKinds,
                            tokenStarts,
                            assertionSourceToken
                          ) != 1
                        ) {
                          statementValid = false;
                        } else {
                          if (
                            signedNumberValid(
                              source,
                              tokenStarts,
                              tokenLengths,
                              assertionSourceToken
                            )
                          ) {
                            opcode = assertionBase + assertionLeft.local;
                            operand = parsedSignedNumber(
                              source,
                              tokenStarts,
                              tokenLengths,
                              assertionSourceToken
                            );
                          } else {
                            statementValid = false;
                          }
                        }
                      }
                    }
                  } else {
                    LoopBodyValue target = resolveLoopBodyValue(
                      source,
                      tokenStarts[token],
                      tokenLengths[token],
                      owner,
                      ordinal,
                      valueCount,
                      valueRows
                    );
                    if (target.valid == false) {
                      statementValid = false;
                    }

                    if (
                      punctuationAt(
                        source,
                        tokenKinds,
                        tokenStarts,
                        token + 1,
                        PUNCTUATION_ASSIGN
                      )
                    ) {
                      boolean targetBoolean = false;
                      boolean targetSigned = false;
                      if (target.valid) {
                        targetBoolean = loopBodyValueType(
                          source,
                          owner,
                          target.local,
                          valueCount,
                          valueRows,
                          semanticCount,
                          tokenStarts,
                          tokenLengths
                        ) == TOKEN_BOOLEAN;
                        targetSigned = loopBodyValueType(
                          source,
                          owner,
                          target.local,
                          valueCount,
                          valueRows,
                          semanticCount,
                          tokenStarts,
                          tokenLengths
                        ) == TOKEN_LONG;
                        if (targetBoolean == false) {
                          if (targetSigned == false) {
                            statementValid = false;
                          }
                        }
                      }

                      long assignmentSourceToken = token + 2;
                      if (tokenKinds[assignmentSourceToken] == 1) {
                        long assignmentHash = tokenHash(
                          source,
                          tokenStarts,
                          tokenLengths,
                          assignmentSourceToken
                        );
                        if (targetBoolean) {
                          if (assignmentHash == TOKEN_TRUE) {
                            opcode = BODY_ASSIGN_BOOLEAN_LITERAL_BASE + target.local;
                            operand = 1;
                          } else {
                            if (assignmentHash == TOKEN_FALSE) {
                              opcode = BODY_ASSIGN_BOOLEAN_LITERAL_BASE + target.local;
                              operand = 0;
                            } else {
                              LoopBodyValue booleanSource = resolveLoopBodyValue(
                                source,
                                tokenStarts[assignmentSourceToken],
                                tokenLengths[assignmentSourceToken],
                                owner,
                                ordinal,
                                valueCount,
                                valueRows
                              );
                              if (booleanSource.valid) {
                                if (
                                  loopBodyValueType(
                                    source,
                                    owner,
                                    booleanSource.local,
                                    valueCount,
                                    valueRows,
                                    semanticCount,
                                    tokenStarts,
                                    tokenLengths
                                  ) == TOKEN_BOOLEAN
                                ) {
                                  opcode = BODY_ASSIGN_BOOLEAN_LOCAL_BASE + target.local;
                                  operandKind = OPERAND_LOCAL;
                                  operand = booleanSource.local;
                                } else {
                                  statementValid = false;
                                }
                              } else {
                                statementValid = false;
                              }
                            }
                          }
                        } else {
                          LoopBodyValue assignmentSource = resolveLoopBodyValue(
                            source,
                            tokenStarts[assignmentSourceToken],
                            tokenLengths[assignmentSourceToken],
                            owner,
                            ordinal,
                            valueCount,
                            valueRows
                          );
                          if (assignmentSource.valid) {
                            if (
                              loopBodyValueType(
                                source,
                                owner,
                                assignmentSource.local,
                                valueCount,
                                valueRows,
                                semanticCount,
                                tokenStarts,
                                tokenLengths
                              ) == TOKEN_BOOLEAN == false
                            ) {
                              opcode = STATEMENT_LOCAL_ASSIGN_SIGNED_LOCAL_BASE + target.local;
                              operandKind = OPERAND_LOCAL;
                              operand = assignmentSource.local;
                            } else {
                              statementValid = false;
                            }
                          } else {
                            statementValid = false;
                          }
                        }
                      } else {
                        if (targetBoolean) {
                          statementValid = false;
                        } else {
                          if (
                            signedNumberWidth(
                              source,
                              tokenKinds,
                              tokenStarts,
                              assignmentSourceToken
                            ) != 1
                          ) {
                            statementValid = false;
                          } else {
                            if (
                              signedNumberValid(
                                source,
                                tokenStarts,
                                tokenLengths,
                                assignmentSourceToken
                              )
                            ) {
                              opcode = STATEMENT_LOCAL_ASSIGN_SIGNED_LITERAL_BASE + target.local;
                              operand = parsedSignedNumber(
                                source,
                                tokenStarts,
                                tokenLengths,
                                assignmentSourceToken
                              );
                            } else {
                              statementValid = false;
                            }
                          }
                        }
                      }
                    } else {
                      long operation = 0;
                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          token + 1,
                          PUNCTUATION_PLUS
                        )
                      ) {
                        operation = STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE;
                      }

                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          token + 1,
                          PUNCTUATION_MINUS
                        )
                      ) {
                        operation = STATEMENT_LOCAL_UPDATE_SUB_LITERAL_BASE;
                      }

                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          token + 1,
                          PUNCTUATION_CARET
                        )
                      ) {
                        operation = STATEMENT_LOCAL_UPDATE_XOR_LITERAL_BASE;
                      }

                      if (operation == 0) {
                        statementValid = false;
                      }

                      if (
                        punctuationAt(
                          source,
                          tokenKinds,
                          tokenStarts,
                          token + 2,
                          PUNCTUATION_ASSIGN
                        ) == false
                      ) {
                        statementValid = false;
                      }

                      if (statementValid) {
                        long updateSourceToken = token + 3;
                        if (tokenKinds[updateSourceToken] == 1) {
                          LoopBodyValue updateSourceValue = resolveLoopBodyValue(
                            source,
                            tokenStarts[updateSourceToken],
                            tokenLengths[updateSourceToken],
                            owner,
                            ordinal,
                            valueCount,
                            valueRows
                          );
                          if (updateSourceValue.valid) {
                            opcode = operation + 256 + target.local;
                            operandKind = OPERAND_LOCAL;
                            operand = updateSourceValue.local;
                          } else {
                            statementValid = false;
                          }
                        } else {
                          if (
                            signedNumberWidth(
                              source,
                              tokenKinds,
                              tokenStarts,
                              updateSourceToken
                            ) != 1
                          ) {
                            statementValid = false;
                          } else {
                            if (
                              signedNumberValid(
                                source,
                                tokenStarts,
                                tokenLengths,
                                updateSourceToken
                              )
                            ) {
                              opcode = operation + target.local;
                              operand = parsedSignedNumber(
                                source,
                                tokenStarts,
                                tokenLengths,
                                updateSourceToken
                              );
                            } else {
                              statementValid = false;
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          if (statementValid) {
            set(stagedRows, bodyCount, statement);
            set(stagedRows, BODY_LOCAL_BASE_ROW + bodyCount, localBase);
            set(stagedRows, BODY_OPCODE_ROW + bodyCount, opcode);
            set(stagedRows, BODY_OPERAND_KIND_ROW + bodyCount, operandKind);
            set(stagedRows, BODY_OPERAND_ROW + bodyCount, operand);
            long localCount = 1;
            if (BODY_ASSERT_EQ_LITERAL_BASE - 1 < opcode) {
              if (opcode < BODY_BOOLEAN_LITERAL) {
                localCount = 3;
              }
            }

            if (opcode == STATEMENT_LOCAL_LONG) {
              localCount = 2;
            }

            if (opcode == BODY_BOOLEAN_LITERAL) {
              localCount = 2;
            }

            if (opcode == BODY_WORDS_GET) {
              localCount = 3;
            }

            if (opcode == BODY_WORDS_SET) {
              localCount = 2;
            }

            if (STATEMENT_LOCAL_LONG_COPY_BASE - 1 < opcode) {
              if (opcode < STATEMENT_LOCAL_UPDATE_ADD_LITERAL_BASE) {
                localCount = 2;
              }
            }

            set(nextBodyLocals, owner, localBase + localCount);
            bodyCount += 1;
          } else {
            valid = false;
          }
        }
      }

      statement += 1;
    }

    if (valid) {
      long row = 0;
      while (row < BODY_ROWS) limit BODY_ROWS {
        set(bodyRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(nextBodyLocals);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new ResolvedLoopBodyPlan(0, false);
    }

    return new ResolvedLoopBodyPlan(bodyCount, true);
  }
}
