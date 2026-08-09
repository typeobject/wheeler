//! Publishes callable-owned source statement ranges.

module wheeler.compiler.closure.source_statement_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.statements;
import wheeler.compiler.tokens;
import wheeler.lexer.scanner;

classical class SourceStatementProducts {
  private const long MAX_CALLABLES = 4096;
  private const long MAX_LOCAL_CALLABLES = 64;
  private const long MAX_STATEMENTS = 4096;
  private const long STATEMENT_ROWS = 24576;

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
    assert(bufferLength(statementRows) == STATEMENT_ROWS);

    region staging = new region(/* bytes= */ 295424, /* allocations= */ 5);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words localStatementStarts = allocate(staging, MAX_LOCAL_CALLABLES);
    words stagedRows = allocate(staging, STATEMENT_ROWS);
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
      while (row < STATEMENT_ROWS) limit STATEMENT_ROWS {
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
}
