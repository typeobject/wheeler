//! Resolves bounded unqualified source calls against callable products.

module wheeler.compiler.closure.source_call_products;

import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SourceCallProducts {
  private const long CALL_ROWS = 1024;
  private const long CALLABLE_SIGNATURE_ROWS = 24576;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_CALLABLE_PARAMETERS = 64;
  private const long MAX_CALLS_PER_BODY = 256;
  private const long PARAMETER_SIGNATURE_ROWS = 32768;
  private const long REQUEST_ROWS = 133;
  private const long TOKEN_ARENA_BYTES = 98320;

  private long closingParen(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long tokenCount
  ) {
    long depth = 1;
    long cursor = open + 1;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
      ) {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private boolean sameName(
    borrow utf8 body,
    long bodyStart,
    long bodyLength,
    borrow utf8 names,
    long nameStart,
    long nameLength
  ) {
    if (bodyLength != nameLength) {
      return false;
    }

    long bodyCursor = bodyStart;
    long nameCursor = nameStart;
    long bodyEnd = bodyStart + bodyLength;
    while (bodyCursor < bodyEnd) limit 256 {
      if (utf8Scalar(body, bodyCursor) != utf8Scalar(names, nameCursor)) {
        return false;
      }

      bodyCursor += utf8Width(body, bodyCursor);
      nameCursor += utf8Width(names, nameCursor);
    }

    return bodyCursor == bodyEnd;
  }

  private long matchingCallable(
    borrow utf8 body,
    long bodyNameStart,
    long bodyNameLength,
    long arity,
    borrow utf8 names,
    long firstCallable,
    long callableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts
  ) {
    long target = -1;
    long offset = 0;
    while (offset < callableCount) limit MAX_CALLABLES {
      long callable = firstCallable + offset;
      if (callableParameterCounts[callable] == arity) {
        if (
          sameName(
            body,
            bodyNameStart,
            bodyNameLength,
            names,
            callableNameStarts[callable],
            callableNameLengths[callable]
          )
        ) {
          assert(target == -1);
          target = callable;
        }
      }

      offset += 1;
    }

    return target;
  }

  private boolean typedParametersMatch(
    borrow mut words requestRows,
    long arity,
    borrow mut words callableRows,
    borrow mut words parameterRows,
    long callable
  ) {
    long firstParameter = callableRows[20480 + callable];
    assert(-1 < firstParameter);
    assert(arity < 16384 - firstParameter + 1);
    long parameter = 0;
    while (parameter < arity) limit MAX_CALLABLE_PARAMETERS {
      if (requestRows[5 + parameter] != parameterRows[firstParameter + parameter]) {
        return false;
      }

      if (
        requestRows[69 + parameter] != parameterRows[16384 + firstParameter + parameter]
      ) {
        return false;
      }

      parameter += 1;
    }

    return true;
  }

  /// Resolves one exact callable signature from a public dependency-product view.
  public long resolveTypedCallableProduct(
    borrow utf8 names,
    borrow mut words requestRows,
    long firstCallable,
    long callableCount,
    borrow mut words callableRows,
    borrow mut words parameterRows
  ) {
    assert(bufferLength(requestRows) == REQUEST_ROWS);
    assert(bufferLength(callableRows) == CALLABLE_SIGNATURE_ROWS);
    assert(bufferLength(parameterRows) == PARAMETER_SIGNATURE_ROWS);
    assert(-1 < firstCallable);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES - firstCallable + 1);
    long arity = requestRows[2];
    assert(-1 < arity);
    assert(arity < MAX_CALLABLE_PARAMETERS + 1);
    long target = -1;
    long offset = 0;
    while (offset < callableCount) limit MAX_CALLABLES {
      long callable = firstCallable + offset;
      if (callableRows[8192 + callable] == arity) {
        if (callableRows[12288 + callable] == requestRows[3]) {
          if (callableRows[16384 + callable] == requestRows[4]) {
            if (
              sameName(
                names,
                requestRows[0],
                requestRows[1],
                names,
                callableRows[callable],
                callableRows[4096 + callable]
              )
            ) {
              if (
                typedParametersMatch(requestRows, arity, callableRows, parameterRows, callable)
              ) {
                assert(target == -1);
                target = callable;
              }
            }
          }
        }
      }

      offset += 1;
    }

    return target;
  }

  /// Publishes imported call sites after local shadowing and ambiguity checks.
  public long resolveSourceCallProducts(
    borrow utf8 body,
    borrow utf8 names,
    long firstLocalCallable,
    long localCallableCount,
    long firstImportedCallable,
    long importedCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callRows
  ) {
    assert(-1 < firstLocalCallable);
    assert(-1 < localCallableCount);
    assert(localCallableCount < MAX_CALLABLES - firstLocalCallable + 1);
    assert(-1 < firstImportedCallable);
    assert(-1 < importedCallableCount);
    assert(importedCallableCount < MAX_CALLABLES - firstImportedCallable + 1);
    assert(bufferLength(callableNameStarts) == MAX_CALLABLES);
    assert(bufferLength(callableNameLengths) == MAX_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_CALLABLES);
    assert(bufferLength(callRows) == CALL_ROWS);

    region tokens = new region(/* bytes= */ TOKEN_ARENA_BYTES, /* allocations= */ 3);
    words tokenKinds = allocate(tokens, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(tokens, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(tokens, MAX_COMPILER_TOKENS);
    long tokenCount = scanSemanticTokens(body, tokenKinds, tokenStarts, tokenLengths);
    assert(-1 < tokenCount);
    long callCount = 0;
    long token = 0;
    while (token + 1 < tokenCount) limit MAX_COMPILER_TOKENS {
      if (tokenKinds[token] == 1) {
        if (
          punctuationAt(body, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN)
        ) {
          long close = closingParen(body, tokenKinds, tokenStarts, token + 1, tokenCount);
          assert(-1 < close);
          long arity = parameterCount(body, tokenKinds, tokenStarts, token + 1, close);
          assert(-1 < arity);
          long local = matchingCallable(
            body,
            tokenStarts[token],
            tokenLengths[token],
            arity,
            names,
            firstLocalCallable,
            localCallableCount,
            callableNameStarts,
            callableNameLengths,
            callableParameterCounts
          );
          if (local < 0) {
            long imported = matchingCallable(
              body,
              tokenStarts[token],
              tokenLengths[token],
              arity,
              names,
              firstImportedCallable,
              importedCallableCount,
              callableNameStarts,
              callableNameLengths,
              callableParameterCounts
            );
            if (-1 < imported) {
              assert(callCount < MAX_CALLS_PER_BODY);
              set(callRows, callCount, tokenStarts[token]);
              set(callRows, 256 + callCount, tokenLengths[token]);
              set(callRows, 512 + callCount, arity);
              set(callRows, 768 + callCount, imported);
              callCount += 1;
            }
          }
        }
      }

      token += 1;
    }

    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(tokens);
    return callCount;
  }
}
