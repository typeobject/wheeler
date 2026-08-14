//! Resolves direct loop-body declarations and updates against callable values.

module wheeler.compiler.closure.resolved_loop_body_products;

import wheeler.compiler.boolean_tokens;
import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.loop_buffer_operands;
import wheeler.compiler.closure.loop_nested_conditions;
import wheeler.compiler.closure.resolved_loop_buffer_products;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.loop_body_opcodes;
import wheeler.compiler.resolved_statements;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class ResolvedLoopBodyProducts {
  private const long MAX_STATEMENTS = 4096;
  private const long OPERAND_LITERAL = 0;
  private const long OPERAND_LOCAL = 1;

  /// Reports one complete direct body-statement resolution pass.
  public record ResolvedLoopBodyPlan(long bodyCount, long nestedCount, boolean valid) {}

  /// Publishes resolved declaration and update rows only after every body statement validates.
  public ResolvedLoopBodyPlan materializeResolvedLoopBodyProducts(
    borrow utf8 source,
    long statementCount,
    borrow mut words statementRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words bodyRows,
    borrow mut words nestedRows
  ) {
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == LOOP_STATEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < LOOP_VALUE_COUNT_LIMIT + 1);
    assert(bufferLength(valueRows) == LOOP_VALUE_ROWS);
    assert(bufferLength(bodyRows) == BODY_ROWS);
    assert(bufferLength(nestedRows) == NESTED_ROWS);

    region staging = new region(
      /* bytes= */ LOOP_BODY_RESOLUTION_ARENA_BYTES,
      /* allocations= */ 6
    );
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedRows = allocate(staging, BODY_ROWS);
    words stagedNestedRows = allocate(staging, NESTED_ROWS);
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
    long nestedCount = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      long childCount = statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement];
      if (0 < statementRows[4096 + statement]) {
        if (childCount == 0) {
          long owner = statementRows[statement];
          long ordinal = statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement];
          long start = statementRows[LOOP_STATEMENT_START_ROW + statement];
          long length = statementRows[LOOP_STATEMENT_LENGTH_ROW + statement];
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
                            punctuationAt(
                              source,
                              tokenKinds,
                              tokenStarts,
                              sourceToken + 3,
                              PUNCTUATION_CLOSE_SQUARE
                            )
                          ) {
                            LoopBufferOperand read = resolveLoopBufferReadOperand(
                              source,
                              owner,
                              sourceValue.local,
                              indexValue.local,
                              valueCount,
                              valueRows,
                              semanticCount,
                              tokenStarts,
                              tokenLengths
                            );
                            if (read.valid) {
                              localBase = localBase - 1;
                              if (0 < read.operand / 65536) {
                                localBase -= 1;
                              }

                              opcode = BODY_WORDS_GET;
                              operand = read.operand;
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
                          signedLoopBodyLocal(
                            source,
                            owner,
                            sourceValue.local,
                            valueCount,
                            valueRows,
                            semanticCount,
                            tokenStarts,
                            tokenLengths
                          )
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
                  ResolvedLoopBufferProduct buffer = resolveLoopBufferProduct(
                    source,
                    owner,
                    ordinal,
                    token,
                    valueCount,
                    valueRows,
                    semanticCount,
                    tokenKinds,
                    tokenStarts,
                    tokenLengths
                  );
                  if (buffer.valid) {
                    opcode = buffer.opcode;
                    operand = buffer.operand;
                  } else {
                    statementValid = false;
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
                        targetBoolean = booleanLoopBodyLocal(
                          source,
                          owner,
                          target.local,
                          valueCount,
                          valueRows,
                          semanticCount,
                          tokenStarts,
                          tokenLengths
                        );
                        targetSigned = signedLoopBodyLocal(
                          source,
                          owner,
                          target.local,
                          valueCount,
                          valueRows,
                          semanticCount,
                          tokenStarts,
                          tokenLengths
                        );
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
                                  booleanLoopBodyLocal(
                                    source,
                                    owner,
                                    booleanSource.local,
                                    valueCount,
                                    valueRows,
                                    semanticCount,
                                    tokenStarts,
                                    tokenLengths
                                  )
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
                              signedLoopBodyLocal(
                                source,
                                owner,
                                assignmentSource.local,
                                valueCount,
                                valueRows,
                                semanticCount,
                                tokenStarts,
                                tokenLengths
                              )
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
            long localCount = loopBodyLocalCount(opcode, operand);
            if (localCount < 0) {
              valid = false;
            } else {
              set(nextBodyLocals, owner, localBase + localCount);
              bodyCount += 1;
            }
          } else {
            valid = false;
          }
        } else {
          long controlOwner = statementRows[statement];
          long controlOrdinal = statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement];
          long controlStart = statementRows[LOOP_STATEMENT_START_ROW + statement];
          long controlToken = tokenAtStart(controlStart, semanticCount, tokenStarts);
          if (controlToken < 0) {
            valid = false;
          } else {
            if (
              tokenHash(source, tokenStarts, tokenLengths, controlToken) != TOKEN_IF
            ) {
              valid = false;
            } else {
              LoopNestedCondition control = resolveLoopNestedCondition(
                source,
                controlOwner,
                controlOrdinal,
                controlToken,
                valueCount,
                valueRows,
                semanticCount,
                tokenKinds,
                tokenStarts,
                tokenLengths
              );
              if (control.valid == false) {
                valid = false;
              }

              long controlLocalBase = localBaseAtOrdinal(
                controlOwner,
                controlOrdinal,
                valueCount,
                valueRows
              );
              if (controlLocalBase < nextBodyLocals[controlOwner]) {
                controlLocalBase = nextBodyLocals[controlOwner];
              }

              if (255 < controlLocalBase + control.localCount) {
                valid = false;
              } else {
                set(nextBodyLocals, controlOwner, controlLocalBase + control.localCount);
                set(stagedNestedRows, nestedCount, statement);
                set(stagedNestedRows, NESTED_KIND_ROW + nestedCount, control.kind);
                set(stagedNestedRows, NESTED_CONDITION_LOCAL_ROW + nestedCount, control.local);
                set(
                  stagedNestedRows,
                  NESTED_CONDITION_LITERAL_ROW + nestedCount,
                  control.literal
                );
                set(stagedNestedRows, NESTED_LOCAL_BASE_ROW + nestedCount, controlLocalBase);
                nestedCount += 1;
              }
            }
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

      row = 0;
      while (row < NESTED_ROWS) limit NESTED_ROWS {
        set(nestedRows, row, stagedNestedRows[row]);
        row += 1;
      }
    }

    drop(nextBodyLocals);
    drop(stagedNestedRows);
    drop(stagedRows);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new ResolvedLoopBodyPlan(0, 0, false);
    }

    return new ResolvedLoopBodyPlan(bodyCount, nestedCount, true);
  }
}
