//! Publishes callable-owned source statement ranges.

module wheeler.compiler.closure.source_statement_products;

import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.compiler_token_limits;
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
  private const long OPEN_BRACE_SCALAR = 123;
  private const long SOURCE_BLOCK_MINIMUM_BYTES = 2;
  private const long SOURCE_STATEMENT_ROWS = 24576;

  /// Reports balanced callable-local source block products.
  public record SourceBlockProductPlan(long blockCount, boolean valid) {}

  /// Reports the complete source statement extent.
  public record SourceStatementProductPlan(long statementCount, boolean valid) {}

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
      long column = 0;
      while (column < 6) limit 6 {
        long row = 0;
        while (row < statementCount) limit MAX_STATEMENTS {
          set(
            statementRows,
            column * MAX_STATEMENTS + row,
            stagedRows[column * MAX_STATEMENTS + row]
          );
          row += 1;
        }

        column += 1;
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
      long column = 0;
      while (column < 6) limit 6 {
        long row = 0;
        while (row < blockCount) limit MAX_BLOCKS {
          set(blockRows, column * MAX_BLOCKS + row, stagedRows[column * MAX_BLOCKS + row]);
          row += 1;
        }

        column += 1;
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
