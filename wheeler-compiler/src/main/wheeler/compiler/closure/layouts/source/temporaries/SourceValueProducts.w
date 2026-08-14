//! Publishes callable value coordinates from source statement products.

module wheeler.compiler.closure.source_value_products;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceValueProducts {
  private const long FUNCTION_LOCAL_ROWS = 64;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_LOCAL_CALLABLES = 64;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_VALUES = 1024;
  private const long SOURCE_STATEMENT_ROWS = 24576;
  private const long VALUE_ROWS = 7168;

  /// Reports named parameter and local value extents.
  public record SourceValueProductPlan(long valueCount, boolean valid) {}

  /// Publishes named parameter and statement-result locals from source statement products.
  public SourceValueProductPlan materializeSourceValueProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    borrow mut words bodyStarts,
    long statementCount,
    borrow mut words statementRows,
    long statementStartRow,
    long statementLengthRow,
    borrow mut words valueRows,
    borrow mut words functionLocalCounts
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < firstCallable);
    assert(firstCallable < MAX_CALLABLES + 1);
    assert(-1 < callableCount);
    assert(callableCount < MAX_LOCAL_CALLABLES + 1);
    assert(callableCount < MAX_CALLABLES - firstCallable + 1);
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
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(functionLocalCounts) == FUNCTION_LOCAL_ROWS);

    region staging = new region(/* bytes= */ 156160, /* allocations= */ 5);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedValues = allocate(staging, VALUE_ROWS);
    words stagedLocalCounts = allocate(staging, FUNCTION_LOCAL_ROWS);
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

                      resultLocal = localBase + localWidth - 1;
                    } else {
                      valid = false;
                    }
                  }
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

          localBase += localWidth;
        }
      }

      if (255 < localBase) {
        valid = false;
      }

      set(stagedLocalCounts, localFunction, localBase);
      localFunction += 1;
    }

    if (valid) {
      long row = 0;
      while (row < VALUE_ROWS) limit VALUE_ROWS {
        set(valueRows, row, stagedValues[row]);
        row += 1;
      }

      row = 0;
      while (row < FUNCTION_LOCAL_ROWS) limit FUNCTION_LOCAL_ROWS {
        set(functionLocalCounts, row, stagedLocalCounts[row]);
        row += 1;
      }
    }

    drop(stagedLocalCounts);
    drop(stagedValues);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new SourceValueProductPlan(0, false);
    }

    return new SourceValueProductPlan(valueCount, true);
  }

}
