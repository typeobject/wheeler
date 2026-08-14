//! Derives callable result kinds from retained source signatures.

module wheeler.compiler.closure.source_callable_result_products;

import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.compiler.type_codes;

classical class SourceCallableResultProducts {
  private const long MAX_CALLABLES = 64;
  private const long MAX_PRODUCT_CALLABLES = 4096;

  /// Reports one complete callable result-kind table.
  public record SourceCallableResultPlan(long callableCount, boolean valid) {}

  private long tokenAtStart(long start, long tokenCount, borrow mut words tokenStarts) {
    long selected = -1;
    long matches = 0;
    long token = 0;
    while (token < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenStarts[token] == start) {
        selected = token;
        matches += 1;
      }

      token += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long resultType(
    borrow utf8 source,
    long bodyToken,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths
  ) {
    long close = bodyToken - 1;
    if (close < 0) {
      return -1;
    }

    if (
      punctuationAt(source, tokenKinds, tokenStarts, close, PUNCTUATION_CLOSE_PAREN) == false
    ) {
      return -1;
    }

    long depth = 1;
    long cursor = close - 1;
    long open = -1;
    while (-1 < cursor) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        depth -= 1;
        if (depth == 0) {
          open = cursor;
          cursor = -1;
        }
      }

      if (-1 < cursor) {
        cursor -= 1;
      }
    }

    if (open < 2) {
      return -1;
    }

    if (tokenKinds[open - 1] != 1) {
      return -1;
    }

    long resultHash = tokenHash(source, tokenStarts, tokenLengths, open - 2);
    if (resultHash == TOKEN_VOID) {
      return 0;
    }

    if (resultHash == TOKEN_LONG) {
      return TYPE_SIGNED;
    }

    if (resultHash == TOKEN_BOOLEAN) {
      return TYPE_BOOLEAN;
    }

    return -1;
  }

  /// Publishes signed, Boolean, or void result kinds in local callable order.
  public SourceCallableResultPlan materializeSourceCallableResultProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    borrow mut words bodyStarts,
    borrow mut words resultTypes
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < firstCallable);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(callableCount < MAX_PRODUCT_CALLABLES - firstCallable + 1);
    assert(bufferLength(bodyStarts) == MAX_PRODUCT_CALLABLES);
    assert(bufferLength(resultTypes) == MAX_CALLABLES);

    region staging = new region(/* bytes= */ 98832, /* allocations= */ 4);
    words tokenKinds = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(staging, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(staging, MAX_COMPILER_TOKENS);
    words stagedTypes = allocate(staging, MAX_CALLABLES);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    boolean valid = -1 < tokenCount;
    long localCallable = 0;
    while (localCallable < callableCount) limit MAX_CALLABLES {
      long bodyStart = bodyStarts[firstCallable + localCallable] - archiveSourceStart;
      long bodyToken = tokenAtStart(bodyStart, tokenCount, tokenStarts);
      if (bodyToken < 0) {
        valid = false;
      } else {
        long type = resultType(source, bodyToken, tokenKinds, tokenStarts, tokenLengths);
        if (type < 0) {
          valid = false;
        } else {
          set(stagedTypes, localCallable, type);
        }
      }

      localCallable += 1;
    }

    if (valid) {
      localCallable = 0;
      while (localCallable < callableCount) limit MAX_CALLABLES {
        set(resultTypes, localCallable, stagedTypes[localCallable]);
        localCallable += 1;
      }
    }

    drop(stagedTypes);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(staging);
    return new SourceCallableResultPlan(callableCount, valid);
  }
}
