//! Publishes callable-owned source statement ranges.

module wheeler.compiler.closure.source_statement_products;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.local_opcodes;
import wheeler.compiler.statement_opcodes;
import wheeler.compiler.statements;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceStatementProducts {
  private const long CLOSE_BRACE_SCALAR = 125;
  private const long DOCUMENTATION_TOKEN_KIND = 5;
  private const long LINE_COMMENT_TOKEN_KIND = 4;
  private const long MAX_BLOCK_DEPTH = 4;
  private const long MAX_BLOCKS = 1024;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_LOCAL_CALLABLES = 64;
  private const long MAX_STATEMENTS = 4096;
  private const long BLOCK_ROWS = 6144;
  private const long BLOCK_STACK_ROWS = 5;
  private const long BLOCK_STAGING_ARENA_BYTES = 442408;
  private const long FUNCTION_LOCAL_ROWS = 64;
  private const long MAX_VALUES = 1024;
  private const long OPEN_BRACE_SCALAR = 123;
  private const long SOURCE_BLOCK_MINIMUM_BYTES = 2;
  private const long SOURCE_STATEMENT_ROWS = 24576;
  private const long VALUE_ROWS = 7168;

  /// Reports balanced callable-local source block products.
  public record SourceBlockProductPlan(long blockCount, boolean valid) {}

  /// Reports the complete source statement extent.
  public record SourceStatementProductPlan(long statementCount, boolean valid) {}

  /// Reports named parameter and local value extents.
  public record SourceValueProductPlan(long valueCount, boolean valid) {}

  private long aggregateStatementWidth(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long start,
    long tokenCount
  ) {
    long depth = 0;
    long token = start;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (punctuationAt(source, tokenKinds, tokenStarts, token, 40)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 91)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 123)) {
        depth += 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 41)) {
        depth -= 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 93)) {
        depth -= 1;
      }

      if (punctuationAt(source, tokenKinds, tokenStarts, token, 125)) {
        if (depth == 0) {
          return 0;
        }

        depth -= 1;
        if (depth == 0) {
          return token - start + 1;
        }
      }

      if (depth == 0) {
        if (punctuationAt(source, tokenKinds, tokenStarts, token, 59)) {
          return token - start + 1;
        }
      }

      if (depth < 0) {
        return 0;
      }

      token += 1;
    }

    return 0;
  }

  /// Publishes local function, source ordinal, and exact statement range rows atomically.
  public SourceStatementProductPlan materializeSourceStatementProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    borrow mut words bodyStarts,
    borrow mut words bodyLengths,
    borrow mut words statementRows
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < firstCallable);
    assert(firstCallable < MAX_CALLABLES + 1);
    assert(-1 < callableCount);
    assert(callableCount < MAX_LOCAL_CALLABLES + 1);
    assert(callableCount < MAX_CALLABLES - firstCallable + 1);
    assert(bufferLength(bodyStarts) == MAX_CALLABLES);
    assert(bufferLength(bodyLengths) == MAX_CALLABLES);
    assert(bufferLength(statementRows) == SOURCE_STATEMENT_ROWS);

    region staging = new region(/* bytes= */ 295424, /* allocations= */ 5);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words localStatementStarts = allocate(staging, MAX_LOCAL_CALLABLES);
    words stagedRows = allocate(staging, SOURCE_STATEMENT_ROWS);
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

    long statementCount = 0;
    long localFunction = 0;
    while (localFunction < callableCount) limit MAX_LOCAL_CALLABLES {
      long callable = firstCallable + localFunction;
      long bodyStart = bodyStarts[callable] - archiveSourceStart;
      long bodyLength = bodyLengths[callable];
      if (bodyStart < 0) {
        valid = false;
      }

      if (bodyLength < 2) {
        valid = false;
      }

      if (bufferLength(source) < bodyStart) {
        valid = false;
      } else {
        if (bufferLength(source) - bodyStart < bodyLength) {
          valid = false;
        }
      }

      long openToken = -1;
      long openMatches = 0;
      long token = 0;
      while (token < semanticCount) limit MAX_COMPILER_TOKENS {
        if (tokenStarts[token] == bodyStart) {
          if (punctuationAt(source, tokenKinds, tokenStarts, token, 123)) {
            openToken = token;
            openMatches += 1;
          }
        }

        token += 1;
      }

      if (openMatches != 1) {
        valid = false;
      }

      long bodyEndToken = -1;
      long bodyStatementCount = 0;
      boolean scanningBody = -1 < openToken;
      long bodyCursor = openToken + 1;
      while (scanningBody) limit 65 {
        if (punctuationAt(source, tokenKinds, tokenStarts, bodyCursor, 125)) {
          bodyEndToken = bodyCursor;
          scanningBody = false;
        } else {
          long bodyStatementWidth = aggregateStatementWidth(
            source,
            tokenKinds,
            tokenStarts,
            bodyCursor,
            semanticCount
          );

          if (bodyStatementWidth < 1) {
            bodyStatementWidth = statementWidth(
              source,
              tokenKinds,
              tokenStarts,
              tokenLengths,
              bodyCursor
            );
          }

          if (bodyStatementWidth < 1) {
            valid = false;
            scanningBody = false;
          } else {
            set(localStatementStarts, bodyStatementCount, bodyCursor);
            bodyStatementCount += 1;
            bodyCursor += bodyStatementWidth;
            if (MAX_LOCAL_CALLABLES < bodyStatementCount) {
              valid = false;
              scanningBody = false;
            }
          }
        }
      }

      if (bodyEndToken < 0) {
        valid = false;
      } else {
        long expectedBodyEnd = bodyStart + bodyLength;
        long scannedBodyEnd = tokenStarts[bodyEndToken] + tokenLengths[bodyEndToken];
        if (scannedBodyEnd != expectedBodyEnd) {
          valid = false;
        }
      }

      if (MAX_STATEMENTS - statementCount < bodyStatementCount) {
        valid = false;
      }

      long localStatement = 0;
      while (localStatement < bodyStatementCount) limit MAX_LOCAL_CALLABLES {
        long statementToken = localStatementStarts[localStatement];
        long width = aggregateStatementWidth(
          source,
          tokenKinds,
          tokenStarts,
          statementToken,
          semanticCount
        );

        if (width < 1) {
          width = statementWidth(source, tokenKinds, tokenStarts, tokenLengths, statementToken);
        }

        if (width < 1) {
          valid = false;
        } else {
          long statement = statementCount + localStatement;
          long start = tokenStarts[statementToken];
          long endToken = statementToken + width - 1;
          long length = tokenStarts[endToken] + tokenLengths[endToken] - start;
          set(stagedRows, statement, localFunction);
          set(stagedRows, 4096 + statement, 0);
          set(stagedRows, 8192 + statement, localStatement + 1);
          set(stagedRows, 12288 + statement, 0);
          set(stagedRows, 16384 + statement, start);
          set(stagedRows, 20480 + statement, length);
        }

        localStatement += 1;
      }

      statementCount += bodyStatementCount;
      localFunction += 1;
    }

    if (valid) {
      long row = 0;
      while (row < SOURCE_STATEMENT_ROWS) limit SOURCE_STATEMENT_ROWS {
        set(statementRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(stagedRows);
    drop(localStatementStarts);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new SourceStatementProductPlan(0, false);
    }

    return new SourceStatementProductPlan(statementCount, true);
  }

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

  /// Publishes balanced block owners, parents, depths, extents, and local ordinals.
  public SourceBlockProductPlan materializeSourceBlockProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    borrow mut words bodyStarts,
    borrow mut words bodyLengths,
    borrow mut words blockRows
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < firstCallable);
    assert(firstCallable < MAX_CALLABLES + 1);
    assert(-1 < callableCount);
    assert(callableCount < MAX_LOCAL_CALLABLES + 1);
    assert(callableCount < MAX_CALLABLES - firstCallable + 1);
    assert(bufferLength(bodyStarts) == MAX_CALLABLES);
    assert(bufferLength(bodyLengths) == MAX_CALLABLES);
    assert(bufferLength(blockRows) == BLOCK_ROWS);

    region staging = new region(/* bytes= */ BLOCK_STAGING_ARENA_BYTES, /* allocations= */ 5);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words blockStack = allocate(staging, BLOCK_STACK_ROWS);
    words stagedRows = allocate(staging, BLOCK_ROWS);
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
      if (kind != LINE_COMMENT_TOKEN_KIND) {
        if (kind != DOCUMENTATION_TOKEN_KIND) {
          set(tokenKinds, semanticCount, kind);
          set(tokenStarts, semanticCount, tokenStarts[readToken]);
          set(tokenLengths, semanticCount, tokenLengths[readToken]);
          semanticCount += 1;
        }
      }

      readToken += 1;
    }

    long blockCount = 0;
    long localFunction = 0;
    while (localFunction < callableCount) limit MAX_LOCAL_CALLABLES {
      long callable = firstCallable + localFunction;
      long absoluteBodyStart = bodyStarts[callable];
      long bodyStart = 0;
      long bodyLength = bodyLengths[callable];
      long bodyEnd = 0;
      boolean rangeValid = true;
      if (absoluteBodyStart < archiveSourceStart) {
        rangeValid = false;
      }

      if (rangeValid) {
        bodyStart = absoluteBodyStart - archiveSourceStart;
        if (bodyLength < SOURCE_BLOCK_MINIMUM_BYTES) {
          rangeValid = false;
        } else {
          if (bufferLength(source) < bodyStart) {
            rangeValid = false;
          } else {
            if (bufferLength(source) - bodyStart < bodyLength) {
              rangeValid = false;
            }
          }
        }
      }

      if (rangeValid) {
        bodyEnd = bodyStart + bodyLength;
        long priorFunction = 0;
        while (priorFunction < localFunction) limit MAX_LOCAL_CALLABLES {
          long priorCallable = firstCallable + priorFunction;
          long absolutePriorStart = bodyStarts[priorCallable];
          long priorStart = 0;
          long priorLength = bodyLengths[priorCallable];
          if (absolutePriorStart < archiveSourceStart) {
            rangeValid = false;
          } else {
            priorStart = absolutePriorStart - archiveSourceStart;
            if (priorLength < SOURCE_BLOCK_MINIMUM_BYTES) {
              rangeValid = false;
            } else {
              if (bufferLength(source) < priorStart) {
                rangeValid = false;
              } else {
                if (bufferLength(source) - priorStart < priorLength) {
                  rangeValid = false;
                } else {
                  long priorEnd = priorStart + priorLength;
                  if (bodyStart < priorEnd) {
                    if (priorStart < bodyEnd) {
                      rangeValid = false;
                    }
                  }
                }
              }
            }
          }

          priorFunction += 1;
        }
      }

      if (rangeValid == false) {
        valid = false;
      }

      long stackDepth = 0;
      long localBlockCount = 0;
      long rootOpenCount = 0;
      long rootCloseCount = 0;
      long token = 0;
      while (token < semanticCount) limit MAX_COMPILER_TOKENS {
        long start = tokenStarts[token];
        long end = start + tokenLengths[token];
        boolean inBody = rangeValid;
        if (inBody) {
          inBody = bodyStart < start + 1;
          if (bodyEnd < end) {
            inBody = false;
          }
        }

        if (inBody) {
          if (
            punctuationAt(source, tokenKinds, tokenStarts, token, OPEN_BRACE_SCALAR)
          ) {
            if (stackDepth == 0) {
              if (start == bodyStart) {
                rootOpenCount += 1;
              } else {
                valid = false;
              }
            }

            if (MAX_BLOCKS < blockCount + 1) {
              valid = false;
            } else {
              if (MAX_BLOCK_DEPTH < stackDepth) {
                valid = false;
              } else {
                long parent = -1;
                if (0 < stackDepth) {
                  parent = blockStack[stackDepth - 1];
                }

                long openedBlock = blockCount;
                set(stagedRows, openedBlock, localFunction);
                set(stagedRows, 1024 + openedBlock, parent);
                set(stagedRows, 2048 + openedBlock, stackDepth);
                set(stagedRows, 3072 + openedBlock, start);
                set(stagedRows, 5120 + openedBlock, localBlockCount);
                set(blockStack, stackDepth, openedBlock);
                stackDepth += 1;
                blockCount += 1;
                localBlockCount += 1;
              }
            }
          }

          if (
            punctuationAt(source, tokenKinds, tokenStarts, token, CLOSE_BRACE_SCALAR)
          ) {
            if (stackDepth < 1) {
              valid = false;
            } else {
              stackDepth -= 1;
              long closedBlock = blockStack[stackDepth];
              long blockStart = stagedRows[3072 + closedBlock];
              set(stagedRows, 4096 + closedBlock, end - blockStart);
              if (stackDepth == 0) {
                if (end == bodyEnd) {
                  rootCloseCount += 1;
                } else {
                  valid = false;
                }
              }
            }
          }
        }

        token += 1;
      }

      if (stackDepth != 0) {
        valid = false;
      }

      if (rootOpenCount != 1) {
        valid = false;
      }

      if (rootCloseCount != 1) {
        valid = false;
      }

      localFunction += 1;
    }

    if (valid) {
      long row = 0;
      while (row < BLOCK_ROWS) limit BLOCK_ROWS {
        set(blockRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(stagedRows);
    drop(blockStack);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    if (valid == false) {
      return new SourceBlockProductPlan(0, false);
    }

    return new SourceBlockProductPlan(blockCount, true);
  }
}
