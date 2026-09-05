//! Publishes callable value coordinates from source statement products.

module wheeler.compiler.closure.source_value_products;

import wheeler.compiler.closure.direct_statement_coordinates;
import wheeler.compiler.closure.loop_body_instruction_encoding;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.source_call_argument_layouts;
import wheeler.compiler.closure.source_reversible_result_relations;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.source_scalars;
import wheeler.compiler.statement_kinds;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;
import wheeler.lexer.scanner;

classical class SourceValueProducts {
  private const long FUNCTION_LOCAL_ROWS = 64;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_LOCAL_CALLABLES = 64;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_VALUES = 1024;
  private const long SOURCE_STATEMENT_ROWS = 24576;
  private const long VALUE_ROWS = 7168;

  /// Reports named values or the first bounded failure coordinate.
  public record SourceValueProductPlan(
    long valueCount,
    long failureFunction,
    long failureStatement,
    long failureCode,
    boolean valid
  ) {}

  /// Publishes named locals for one source product that contains no calls.
  public SourceValueProductPlan materializeSourceValueProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    long reversibleCallableCount,
    borrow mut words bodyStarts,
    long statementCount,
    borrow mut words statementRows,
    long statementStartRow,
    long statementLengthRow,
    borrow mut words valueRows,
    borrow mut words functionLocalCounts,
    borrow mut words statementLocalRows
  ) {
    region noCalls = new region(/* bytes= */ 10240, /* allocations= */ 2);
    words callRows = allocate(noCalls, /* length= */ 1024);
    words callStatements = allocate(noCalls, /* length= */ 256);
    SourceValueProductPlan plan = materializeSourceValueProductsWithCalls(
      source,
      archiveSourceStart,
      firstCallable,
      callableCount,
      reversibleCallableCount,
      bodyStarts,
      statementCount,
      statementRows,
      statementStartRow,
      statementLengthRow,
      /* callCount= */ 0,
      callRows,
      callStatements,
      valueRows,
      functionLocalCounts,
      statementLocalRows
    );
    drop(callStatements);
    drop(callRows);
    drop(noCalls);
    return plan;
  }

  /// Publishes named locals from statement and exact source-call products.
  public SourceValueProductPlan materializeSourceValueProductsWithCalls(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    long reversibleCallableCount,
    borrow mut words bodyStarts,
    long statementCount,
    borrow mut words statementRows,
    long statementStartRow,
    long statementLengthRow,
    long callCount,
    borrow mut words callRows,
    borrow mut words callStatements,
    borrow mut words valueRows,
    borrow mut words functionLocalCounts,
    borrow mut words statementLocalRows
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < firstCallable);
    assert(firstCallable < MAX_CALLABLES + 1);
    assert(-1 < callableCount);
    assert(callableCount < MAX_LOCAL_CALLABLES + 1);
    assert(callableCount < MAX_CALLABLES - firstCallable + 1);
    assert(-1 < reversibleCallableCount);
    assert(reversibleCallableCount < callableCount + 1);
    if (0 < reversibleCallableCount) {
      assert(reversibleCallableCount == callableCount);
    }

    assert(bufferLength(bodyStarts) == MAX_CALLABLES);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    boolean statementRowsValid = bufferLength(statementRows) == SOURCE_STATEMENT_ROWS;
    if (bufferLength(statementRows) == LOOP_STATEMENT_ROWS) {
      statementRowsValid = true;
    }

    assert(statementRowsValid);
    assert(-1 < statementStartRow);
    assert(-1 < statementLengthRow);
    assert(statementStartRow < bufferLength(statementRows));
    assert(statementLengthRow < bufferLength(statementRows));
    assert(-1 < callCount);
    assert(callCount < 257);
    assert(bufferLength(callRows) == 1024);
    assert(bufferLength(callStatements) == 256);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(functionLocalCounts) == FUNCTION_LOCAL_ROWS);
    assert(bufferLength(statementLocalRows) == 8192);

    region staging = new region(/* bytes= */ 221696, /* allocations= */ 6);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedValues = allocate(staging, VALUE_ROWS);
    words stagedLocalCounts = allocate(staging, FUNCTION_LOCAL_ROWS);
    words stagedStatementLocals = allocate(staging, /* length= */ 8192);
    boolean valid = true;
    long failureFunction = -1;
    long failureStatement = -1;
    long failureCode = 0;
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

    long readToken = 0;
    long semanticCount = 0;
    while (readToken < tokenCount) limit MAX_COMPILER_TOKENS {
      long kind = tokenKinds[readToken];
      if (kind != 4) {
        if (kind != 5) {
          set(tokenKinds, semanticCount, kind);
          set(tokenStarts, semanticCount, tokenStarts[readToken]);
          set(tokenLengths, semanticCount, tokenLengths[readToken]);
          semanticCount += 1;
        }
      }

      readToken += 1;
    }

    long valueCount = 0;
    long localFunction = 0;
    while (localFunction < callableCount) limit MAX_LOCAL_CALLABLES {
      long callable = firstCallable + localFunction;
      long functionRootBlock = loopBodyRootBlockForOwner(
        localFunction,
        statementCount,
        statementRows
      );
      long bodyStart = bodyStarts[callable] - archiveSourceStart;
      long openBody = -1;
      long bodyMatches = 0;
      long token = 0;
      while (token < semanticCount) limit MAX_COMPILER_TOKENS {
        if (tokenStarts[token] == bodyStart) {
          if (punctuationAt(source, tokenKinds, tokenStarts, token, 123)) {
            openBody = token;
            bodyMatches += 1;
          }
        }

        token += 1;
      }

      if (bodyMatches != 1) {
        valid = false;
      }

      long closeParameters = openBody - 1;
      if (closeParameters < 0) {
        valid = false;
      } else {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, closeParameters, 41) == false
        ) {
          valid = false;
        }
      }

      long openParameters = -1;
      long parameterDepth = 0;
      long reverseToken = closeParameters;
      while (-1 < reverseToken) limit MAX_COMPILER_TOKENS {
        if (punctuationAt(source, tokenKinds, tokenStarts, reverseToken, 41)) {
          parameterDepth += 1;
        }

        if (punctuationAt(source, tokenKinds, tokenStarts, reverseToken, 40)) {
          parameterDepth -= 1;
          if (parameterDepth == 0) {
            openParameters = reverseToken;
            reverseToken = -1;
          }
        }

        if (-1 < reverseToken) {
          reverseToken -= 1;
        }
      }

      if (openParameters < 0) {
        valid = false;
      }

      if (valid == false) {
        if (failureCode == 0) {
          failureFunction = localFunction;
          failureCode = 1;
        }
      }

      long parameterCount = 0;
      long parameterToken = openParameters + 1;
      while (parameterToken < closeParameters) limit 256 {
        if (tokenKinds[parameterToken] == 1) {
          boolean parameterName = parameterToken + 1 == closeParameters;
          if (parameterToken + 1 < closeParameters) {
            parameterName = punctuationAt(
              source,
              tokenKinds,
              tokenStarts,
              parameterToken + 1,
              44
            );
          }

          if (parameterName) {
            if (MAX_VALUES < valueCount + 1) {
              valid = false;
            } else {
              set(stagedValues, valueCount, localFunction);
              set(stagedValues, 1024 + valueCount, tokenStarts[parameterToken]);
              set(stagedValues, 2048 + valueCount, tokenLengths[parameterToken]);
              set(stagedValues, 3072 + valueCount, parameterCount);
              set(stagedValues, 4096 + valueCount, 0);
              set(stagedValues, 5120 + valueCount, tokenStarts[parameterToken]);
              set(stagedValues, 6144 + valueCount, tokenLengths[parameterToken]);
              valueCount += 1;
              parameterCount += 1;
            }
          }
        }

        parameterToken += 1;
      }

      long localBase = parameterCount;
      long priorStatementOrdinal = -1;
      boolean selectingStatement = true;
      while (selectingStatement) limit MAX_STATEMENTS {
        long statement = -1;
        long selectedStatementOrdinal = MAX_STATEMENTS + 1;
        long statementCandidate = 0;
        while (statementCandidate < statementCount) limit MAX_STATEMENTS {
          if (statementRows[statementCandidate] == localFunction) {
            long candidateOrdinal = statementRows[8192 + statementCandidate];
            if (priorStatementOrdinal < candidateOrdinal) {
              if (candidateOrdinal < selectedStatementOrdinal) {
                statement = statementCandidate;
                selectedStatementOrdinal = candidateOrdinal;
              }
            }
          }

          statementCandidate += 1;
        }

        if (statement < 0) {
          selectingStatement = false;
        } else {
          priorStatementOrdinal = selectedStatementOrdinal;
          long statementStart = statementRows[statementStartRow + statement];
          long statementToken = -1;
          long statementTokenMatches = 0;
          token = 0;
          while (token < semanticCount) limit MAX_COMPILER_TOKENS {
            if (tokenStarts[token] == statementStart) {
              statementToken = token;
              statementTokenMatches += 1;
            }

            token += 1;
          }

          if (statementTokenMatches != 1) {
            valid = false;
          }

          long opcode = -1;
          long localWidth = 0;
          long resultLocal = -1;
          long statementCall = -1;
          long statementCallMatches = 0;
          long candidateCall = 0;
          while (candidateCall < callCount) limit 256 {
            if (callStatements[candidateCall] == statement) {
              statementCall = candidateCall;
              statementCallMatches += 1;
            }

            candidateCall += 1;
          }

          if (1 < statementCallMatches) {
            valid = false;
          }

          if (-1 < statementToken) {
            opcode = statementOpcode(source, tokenStarts, tokenLengths, statementToken);
            if (-1 < opcode) {
              localWidth = statementLocalCount(opcode);
              resultLocal = statementResultLocal(opcode, localBase);
              if (
                punctuationAt(source, tokenKinds, tokenStarts, statementToken + 4, 91)
              ) {
                if (tokenKinds[statementToken + 5] != 1) {
                  if (tokenKinds[statementToken + 7] == 1) {
                    localWidth += 2;
                    resultLocal += 2;
                  }
                }
              }

              long statementHash = tokenHash(source, tokenStarts, tokenLengths, statementToken);
              boolean indexedBufferCopy = loopBufferSetToken(statementHash);

              if (indexedBufferCopy) {
                indexedBufferCopy = punctuationAt(
                  source,
                  tokenKinds,
                  tokenStarts,
                  statementToken + 7,
                  91
                );
              }

              if (indexedBufferCopy) {
                LoopBodyValue indexedWriteOwner = resolveLoopBodyValue(
                  source,
                  tokenStarts[statementToken + 2],
                  tokenLengths[statementToken + 2],
                  localFunction,
                  statementRows[8192 + statement],
                  valueCount,
                  stagedValues
                );
                LoopBodyValue indexedReadOwner = resolveLoopBodyValue(
                  source,
                  tokenStarts[statementToken + 6],
                  tokenLengths[statementToken + 6],
                  localFunction,
                  statementRows[8192 + statement],
                  valueCount,
                  stagedValues
                );
                if (indexedWriteOwner.valid) {
                  if (indexedReadOwner.valid) {
                    localWidth = 3;
                    if (
                      borrowedLoopBodyLocal(
                        source,
                        localFunction,
                        indexedWriteOwner.local,
                        valueCount,
                        stagedValues,
                        semanticCount,
                        tokenStarts,
                        tokenLengths
                      )
                    ) {
                      localWidth += 1;
                    }

                    if (
                      borrowedLoopBodyLocal(
                        source,
                        localFunction,
                        indexedReadOwner.local,
                        valueCount,
                        stagedValues,
                        semanticCount,
                        tokenStarts,
                        tokenLengths
                      )
                    ) {
                      localWidth += 1;
                    }

                    if (
                      punctuationAt(source, tokenKinds, tokenStarts, statementToken + 9, 43)
                    ) {
                      localWidth += 2;
                    }
                  } else {
                    valid = false;
                  }
                } else {
                  valid = false;
                }
              }
            } else {
              if (tokenKinds[statementToken] == 1) {
                if (tokenKinds[statementToken + 1] == 1) {
                  localWidth = 2;
                  resultLocal = localBase + 1;
                  if (
                    punctuationAt(source, tokenKinds, tokenStarts, statementToken + 4, 91)
                  ) {
                    LoopBodyValue readOwner = resolveLoopBodyValue(
                      source,
                      tokenStarts[statementToken + 3],
                      tokenLengths[statementToken + 3],
                      localFunction,
                      statementRows[8192 + statement],
                      valueCount,
                      stagedValues
                    );
                    if (readOwner.valid) {
                      localWidth = 3;
                      long readType = directBufferLocalType(
                        source,
                        localFunction,
                        readOwner.local,
                        valueCount,
                        stagedValues,
                        semanticCount,
                        tokenStarts,
                        tokenLengths
                      );
                      boolean byteRead = readType == TYPE_BYTE_VIEW;
                      if (readType == TYPE_BYTES) {
                        byteRead = true;
                      }

                      if (readType == TYPE_BYTES_BORROW) {
                        byteRead = true;
                      }

                      if (byteRead) {
                        localWidth = 4;
                      } else {
                        if (
                          borrowedWordsLoopBodyLocal(
                            source,
                            localFunction,
                            readOwner.local,
                            valueCount,
                            stagedValues,
                            semanticCount,
                            tokenStarts,
                            tokenLengths
                          )
                        ) {
                          localWidth += 1;
                        }

                        if (tokenKinds[statementToken + 5] != 1) {
                          if (tokenKinds[statementToken + 7] == 1) {
                            localWidth += 2;
                          }
                        }
                      }

                      resultLocal = localBase + localWidth - 1;
                    } else {
                      valid = false;
                    }
                  }
                }
              }
            }
          }

          if (-1 < statementToken) {
            long valueHash = tokenHash(source, tokenStarts, tokenLengths, statementToken);
            if (valueHash == TOKEN_IF) {
              if (statementRows[4096 + statement] == functionRootBlock) {
                if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement] == 1) {
                  localWidth = 3;
                  if (-1 < statementCall) {
                    localWidth = callRows[512 + statementCall] * 2 + 1;
                  }

                  resultLocal = -1;
                }
              }
            }

            if (valueHash == TOKEN_LONG) {
              SourceReversibleResultRelation initializerRelation = sourceScalarRelation(
                source,
                statementToken + 3,
                semanticCount,
                tokenKinds,
                tokenStarts,
                tokenLengths
              );
              if (initializerRelation.valid) {
                if (initializerRelation.kind != RESULT_RELATION_SOURCE) {
                  localWidth = 4;
                  resultLocal = localBase + 3;
                }
              }

              if (-1 < statementCall) {
                localWidth = callRows[512 + statementCall] * 2 + 2;
                resultLocal = localBase + localWidth - 1;
              }
            }

            if (valueHash == TOKEN_BOOLEAN) {
              if (-1 < statementCall) {
                localWidth = callRows[512 + statementCall] * 2 + 2;
                resultLocal = localBase + localWidth - 1;
              }
            }

            if (valueHash == TOKEN_ASSERT) {
              LoopAssertion assertion = resolveLoopAssertion(
                source,
                statementToken,
                localFunction,
                statementRows[8192 + statement],
                valueCount,
                stagedValues,
                semanticCount,
                tokenKinds,
                tokenStarts,
                tokenLengths
              );
              if (assertion.valid) {
                localWidth = loopBodyLocalCount(assertion.opcode, assertion.operand);
                resultLocal = -1;
              } else {
                valid = false;
              }
            }

            if (valueHash == TOKEN_RETURN) {
              if (opcode == STATEMENT_RETURN_HELPER_CALL_NAMED) {
                long returnArity = -1;
                long returnCallMatches = 0;
                long returnCall = 0;
                while (returnCall < callCount) limit 256 {
                  if (callStatements[returnCall] == statement) {
                    returnArity = callRows[512 + returnCall];
                    returnCallMatches += 1;
                  }

                  returnCall += 1;
                }

                if (returnCallMatches != 1) {
                  valid = false;
                } else {
                  if (returnArity < 0) {
                    valid = false;
                  } else {
                    if (SOURCE_CALL_ARITY_LIMIT < returnArity) {
                      valid = false;
                    } else {
                      localWidth = returnArity * 2 + 1;
                    }
                  }
                }

                resultLocal = -1;
              } else {
                if (
                  punctuationAt(
                    source,
                    tokenKinds,
                    tokenStarts,
                    statementToken + 1,
                    PUNCTUATION_SEMICOLON
                  )
                ) {
                  localWidth = 0;
                  resultLocal = -1;
                } else {
                  if (tokenKinds[statementToken + 1] != 1) {
                    localWidth = 1;
                    resultLocal = -1;
                  } else {
                    SourceReversibleResultRelation relation = sourceReversibleResultRelation(
                      source,
                      statementToken,
                      semanticCount,
                      tokenKinds,
                      tokenStarts,
                      tokenLengths
                    );
                    if (relation.valid == false) {
                      valid = false;
                    } else {
                      if (reversibleCallableCount == 0) {
                        localWidth = 1;
                        if (relation.kind != RESULT_RELATION_SOURCE) {
                          localWidth = 3;
                        }
                      }

                      resultLocal = -1;
                    }
                  }
                }
              }
            }
          }

          if (-1 < statementCall) {
            if (callRows[statementCall] == statementStart) {
              long callArity = callRows[512 + statementCall];
              if (callArity < 0) {
                valid = false;
              } else {
                if (SOURCE_CALL_ARITY_LIMIT < callArity) {
                  valid = false;
                } else {
                  localWidth = callArity * 2;
                  resultLocal = -1;
                }
              }
            }
          }

          if (localWidth < 0) {
            valid = false;
          }

          if (MAX_LOCAL_CALLABLES * 4 < localBase + localWidth) {
            valid = false;
          }

          if (-1 < resultLocal) {
            if (MAX_VALUES < valueCount + 1) {
              valid = false;
            } else {
              long nameToken = statementToken + 1;
              if (tokenKinds[nameToken] != 1) {
                valid = false;
              }

              set(stagedValues, valueCount, localFunction);
              set(stagedValues, 1024 + valueCount, tokenStarts[nameToken]);
              set(stagedValues, 2048 + valueCount, tokenLengths[nameToken]);
              set(stagedValues, 3072 + valueCount, resultLocal);
              set(stagedValues, 4096 + valueCount, statementRows[8192 + statement]);
              set(stagedValues, 5120 + valueCount, statementStart);
              set(
                stagedValues,
                6144 + valueCount,
                statementRows[statementLengthRow + statement]
              );
              valueCount += 1;
            }
          }

          if (valid == false) {
            if (failureCode == 0) {
              failureFunction = localFunction;
              failureStatement = statement;
              failureCode = 2;
            }
          }

          set(stagedStatementLocals, statement, localBase);
          set(stagedStatementLocals, 4096 + statement, localWidth);
          localBase += localWidth;
        }
      }

      if (255 < localBase) {
        valid = false;
        if (failureCode == 0) {
          failureFunction = localFunction;
          failureCode = 3;
        }
      }

      set(stagedLocalCounts, localFunction, localBase);
      localFunction += 1;
    }

    if (valid) {
      long column = 0;
      while (column < 7) limit 7 {
        long valueRow = 0;
        while (valueRow < valueCount) limit MAX_VALUES {
          set(
            valueRows,
            column * MAX_VALUES + valueRow,
            stagedValues[column * MAX_VALUES + valueRow]
          );
          valueRow += 1;
        }

        column += 1;
      }

      long row = 0;
      while (row < callableCount) limit MAX_LOCAL_CALLABLES {
        set(functionLocalCounts, row, stagedLocalCounts[row]);
        row += 1;
      }

      column = 0;
      while (column < 2) limit 2 {
        long statementRow = 0;
        while (statementRow < statementCount) limit MAX_STATEMENTS {
          set(
            statementLocalRows,
            column * MAX_STATEMENTS + statementRow,
            stagedStatementLocals[column * MAX_STATEMENTS + statementRow]
          );
          statementRow += 1;
        }

        column += 1;
      }
    }

    drop(stagedStatementLocals);
    drop(stagedLocalCounts);
    drop(stagedValues);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new SourceValueProductPlan(
        0,
        failureFunction,
        failureStatement,
        failureCode,
        false
      );
    }

    return new SourceValueProductPlan(valueCount, -1, -1, 0, true);
  }

}
