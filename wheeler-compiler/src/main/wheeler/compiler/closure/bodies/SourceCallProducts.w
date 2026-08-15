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
  private const long STATEMENT_COUNT_LIMIT = 4096;
  private const long STATEMENT_ROWS = 28672;
  private const long STATEMENT_SOURCE_START_ROW = 12288;
  private const long STATEMENT_SOURCE_LENGTH_ROW = 16384;

  /// Reports one exact call-to-statement join.
  public record SourceCallStatementPlan(long callCount, boolean valid) {}

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

  private boolean sameProductName(
    borrow utf8 body,
    long bodyStart,
    long bodyLength,
    borrow byteview names,
    long nameStart,
    long nameLength
  ) {
    if (bodyLength != nameLength) {
      return false;
    }

    long offset = 0;
    while (offset < bodyLength) limit 256 {
      if (utf8Scalar(body, bodyStart + offset) != names[nameStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long matchingProductCallable(
    borrow utf8 body,
    long bodyNameStart,
    long bodyNameLength,
    long arity,
    borrow byteview names,
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
          sameProductName(
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

  private boolean typedCallableMatches(
    borrow utf8 names,
    borrow mut words requestRows,
    borrow mut words callableRows,
    borrow mut words parameterRows,
    long callable
  ) {
    long arity = requestRows[2];
    if (callableRows[8192 + callable] != arity) {
      return false;
    }

    if (callableRows[12288 + callable] != requestRows[3]) {
      return false;
    }

    if (callableRows[16384 + callable] != requestRows[4]) {
      return false;
    }

    if (
      !sameName(
        names,
        requestRows[0],
        requestRows[1],
        names,
        callableRows[callable],
        callableRows[4096 + callable]
      )
    ) {
      return false;
    }

    return typedParametersMatch(requestRows, arity, callableRows, parameterRows, callable);
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
      if (
        typedCallableMatches(names, requestRows, callableRows, parameterRows, callable)
      ) {
        assert(target == -1);
        target = callable;
      }

      offset += 1;
    }

    return target;
  }

  /// Resolves one exact signature from the dependency rank written at the call site.
  public long resolveRankedTypedCallableProduct(
    borrow utf8 names,
    borrow mut words requestRows,
    long dependencyRank,
    long firstCallable,
    long callableCount,
    borrow mut words callableRows,
    borrow mut words parameterRows,
    borrow mut words callableDependencyRanks
  ) {
    assert(-1 < dependencyRank);
    assert(bufferLength(requestRows) == REQUEST_ROWS);
    assert(bufferLength(callableRows) == CALLABLE_SIGNATURE_ROWS);
    assert(bufferLength(parameterRows) == PARAMETER_SIGNATURE_ROWS);
    assert(bufferLength(callableDependencyRanks) == MAX_CALLABLES);
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
      if (callableDependencyRanks[callable] == dependencyRank) {
        if (
          typedCallableMatches(names, requestRows, callableRows, parameterRows, callable)
        ) {
          assert(target == -1);
          target = callable;
        }
      }

      offset += 1;
    }

    return target;
  }

  /// Resolves one exact signature from a packed local or locked external view.
  public long resolvePackedTypedCallableProduct(
    borrow utf8 localNames,
    borrow utf8 externalNames,
    borrow mut words requestRows,
    long dependencyRank,
    long productCount,
    borrow mut words dependencyRows,
    borrow mut words localCallableRows,
    borrow mut words localParameterRows,
    borrow mut words externalCallableRows,
    borrow mut words externalParameterRows
  ) {
    assert(-1 < dependencyRank);
    assert(-1 < productCount);
    assert(productCount < MAX_CALLABLES + 1);
    assert(bufferLength(dependencyRows) == 8192);
    assert(bufferLength(requestRows) == REQUEST_ROWS);
    assert(bufferLength(localCallableRows) == CALLABLE_SIGNATURE_ROWS);
    assert(bufferLength(localParameterRows) == PARAMETER_SIGNATURE_ROWS);
    assert(bufferLength(externalCallableRows) == CALLABLE_SIGNATURE_ROWS);
    assert(bufferLength(externalParameterRows) == PARAMETER_SIGNATURE_ROWS);
    long arity = requestRows[2];
    assert(-1 < arity);
    assert(arity < MAX_CALLABLE_PARAMETERS + 1);
    long target = -1;
    long product = 0;
    while (product < productCount) limit MAX_CALLABLES {
      if (dependencyRows[product] == dependencyRank) {
        long encoded = dependencyRows[4096 + product];
        boolean matches = false;
        if (-1 < encoded) {
          assert(encoded < MAX_CALLABLES);
          matches = typedCallableMatches(
            localNames,
            requestRows,
            localCallableRows,
            localParameterRows,
            encoded
          );
        } else {
          long external = 0 - encoded - 1;
          assert(external < MAX_CALLABLES);
          matches = typedCallableMatches(
            externalNames,
            requestRows,
            externalCallableRows,
            externalParameterRows,
            external
          );
        }

        if (matches) {
          assert(target == -1);
          target = encoded;
        }
      }

      product += 1;
    }

    return target;
  }

  /// Binds every call token to its narrowest containing source statement atomically.
  public SourceCallStatementPlan bindSourceCallStatements(
    long callCount,
    long callSourceBase,
    long callableOwner,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words callRows,
    borrow mut words callStatements
  ) {
    assert(-1 < callCount);
    assert(callCount < MAX_CALLS_PER_BODY + 1);
    assert(-1 < callSourceBase);
    assert(-1 < callableOwner);
    assert(callableOwner < 64);
    assert(-1 < statementCount);
    assert(statementCount < STATEMENT_COUNT_LIMIT + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callStatements) == MAX_CALLS_PER_BODY);

    region staging = new region(/* bytes= */ 2048, /* allocations= */ 1);
    words stagedStatements = allocate(staging, MAX_CALLS_PER_BODY);
    boolean valid = true;
    long call = 0;
    while (call < callCount) limit MAX_CALLS_PER_BODY {
      long callStart = callSourceBase + callRows[call];
      long callLength = callRows[256 + call];
      long callEnd = callStart + callLength;
      long selected = -1;
      long selectedLength = 32769;
      long statement = 0;
      while (statement < statementCount) limit STATEMENT_COUNT_LIMIT {
        if (statementRows[statement] == callableOwner) {
          long statementStart = statementRows[STATEMENT_SOURCE_START_ROW + statement];
          long statementLength = statementRows[STATEMENT_SOURCE_LENGTH_ROW + statement];
          long statementEnd = statementStart + statementLength;
          if (statementStart < callStart + 1) {
            if (callEnd < statementEnd + 1) {
              if (statementLength < selectedLength) {
                selected = statement;
                selectedLength = statementLength;
              } else {
                if (statementLength == selectedLength) {
                  valid = false;
                }
              }
            }
          }
        }

        statement += 1;
      }

      if (selected < 0) {
        valid = false;
      }

      set(stagedStatements, call, selected);
      call += 1;
    }

    if (valid == false) {
      drop(stagedStatements);
      drop(staging);
      return new SourceCallStatementPlan(0, false);
    }

    call = 0;
    while (call < callCount) limit MAX_CALLS_PER_BODY {
      set(callStatements, call, stagedStatements[call]);
      call += 1;
    }

    drop(stagedStatements);
    drop(staging);
    return new SourceCallStatementPlan(callCount, true);
  }

  private long resolveSelectedUtf8ProductSourceCallProducts(
    boolean includeLocal,
    boolean includeImported,
    borrow utf8 body,
    long bodyStart,
    long bodyLength,
    borrow byteview names,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow mut words callRows
  ) {
    assert(-1 < bodyStart);
    assert(0 < bodyLength);
    assert(bodyLength < bufferLength(body) - bodyStart + 1);
    assert(-1 < firstLocalCallable);
    assert(-1 < localCallableCount);
    assert(localCallableCount < MAX_CALLABLES - firstLocalCallable + 1);
    assert(bufferLength(callableNameStarts) == MAX_CALLABLES);
    assert(bufferLength(callableNameLengths) == MAX_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_CALLABLES);
    assert(-1 < dependencyCount);
    assert(dependencyCount < MAX_CALLABLES + 1);
    if (includeImported) {
      assert(bufferLength(dependencyRows) == 8192);
    }

    assert(bufferLength(callRows) == CALL_ROWS);
    region tokens = new region(/* bytes= */ TOKEN_ARENA_BYTES, /* allocations= */ 3);
    words tokenKinds = allocate(tokens, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(tokens, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(tokens, MAX_COMPILER_TOKENS);
    region staged = new region(/* bytes= */ 8192, /* allocations= */ 1);
    words stagedCalls = allocate(staged, CALL_ROWS);
    long tokenCount = scanSemanticTokens(body, tokenKinds, tokenStarts, tokenLengths);
    assert(-1 < tokenCount);
    long callCount = 0;
    long token = 0;
    while (token + 1 < tokenCount) limit MAX_COMPILER_TOKENS {
      long selectedStart = tokenStarts[token];
      if (bodyStart - 1 < selectedStart) {
        if (selectedStart < bodyStart + bodyLength) {
          if (tokenKinds[token] == 1) {
            if (
              punctuationAt(body, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN)
            ) {
              long close = closingParen(body, tokenKinds, tokenStarts, token + 1, tokenCount);
              assert(-1 < close);
              long arity = parameterCount(body, tokenKinds, tokenStarts, token + 1, close);
              assert(-1 < arity);
              long local = matchingProductCallable(
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
              long selectedTarget = -1;
              if (-1 < local) {
                if (includeLocal) {
                  selectedTarget = local;
                }
              } else {
                if (includeImported) {
                  long imported = -1;
                  long product = 0;
                  while (product < dependencyCount) limit MAX_CALLABLES {
                    long candidate = dependencyRows[4096 + product];
                    if (-1 < candidate) {
                      if (callableParameterCounts[candidate] == arity) {
                        if (
                          sameProductName(
                            body,
                            tokenStarts[token],
                            tokenLengths[token],
                            names,
                            callableNameStarts[candidate],
                            callableNameLengths[candidate]
                          )
                        ) {
                          assert(imported == -1);
                          imported = candidate;
                        }
                      }
                    }

                    product += 1;
                  }

                  selectedTarget = imported;
                }
              }

              if (-1 < selectedTarget) {
                assert(callCount < MAX_CALLS_PER_BODY);
                set(stagedCalls, callCount, tokenStarts[token]);
                set(stagedCalls, 256 + callCount, tokenLengths[token]);
                set(stagedCalls, 512 + callCount, arity);
                set(stagedCalls, 768 + callCount, selectedTarget);
                callCount += 1;
              }
            }
          }
        }
      }

      token += 1;
    }

    long call = 0;
    while (call < callCount) limit MAX_CALLS_PER_BODY {
      set(callRows, call, stagedCalls[call]);
      set(callRows, 256 + call, stagedCalls[256 + call]);
      set(callRows, 512 + call, stagedCalls[512 + call]);
      set(callRows, 768 + call, stagedCalls[768 + call]);
      call += 1;
    }

    drop(stagedCalls);
    drop(staged);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(tokens);
    return callCount;
  }

  private long resolveSelectedProductSourceCallProducts(
    boolean includeLocal,
    boolean includeImported,
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    borrow byteview names,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow mut words callRows
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceLength < 32769);
    assert(sourceLength < bufferLength(source) - sourceStart + 1);
    region sourceArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
    long sourceByte = 0;
    while (sourceByte < sourceLength) limit 32768 {
      setByte(sourceBytes, sourceByte, source[sourceStart + sourceByte]);
      sourceByte += 1;
    }

    utf8 body = freezeUtf8(sourceBytes);
    long callCount = resolveSelectedUtf8ProductSourceCallProducts(
      includeLocal,
      includeImported,
      body,
      /* bodyStart= */ 0,
      bufferLength(body),
      names,
      firstLocalCallable,
      localCallableCount,
      callableNameStarts,
      callableNameLengths,
      callableParameterCounts,
      dependencyCount,
      dependencyRows,
      callRows
    );
    drop(body);
    drop(sourceArena);
    return callCount;
  }

  /// Resolves packed dependency calls after local shadowing without dependency source.
  public long resolveProductSourceCallProducts(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    borrow byteview names,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow mut words callRows
  ) {
    return resolveSelectedProductSourceCallProducts(
      false,
      true,
      source,
      sourceStart,
      sourceLength,
      names,
      firstLocalCallable,
      localCallableCount,
      callableNameStarts,
      callableNameLengths,
      callableParameterCounts,
      dependencyCount,
      dependencyRows,
      callRows
    );
  }

  /// Resolves local calls from copied names without dependency source.
  public long resolveLocalProductSourceCallProducts(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    borrow byteview names,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callRows
  ) {
    return resolveSelectedProductSourceCallProducts(
      true,
      false,
      source,
      sourceStart,
      sourceLength,
      names,
      firstLocalCallable,
      localCallableCount,
      callableNameStarts,
      callableNameLengths,
      callableParameterCounts,
      /* dependencyCount= */ 0,
      callRows,
      callRows
    );
  }

  /// Resolves local calls directly from one retained UTF-8 callable body.
  public long resolveLocalUtf8ProductSourceCallProducts(
    borrow utf8 body,
    long bodyStart,
    long bodyLength,
    borrow byteview names,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callRows
  ) {
    return resolveSelectedUtf8ProductSourceCallProducts(
      true,
      false,
      body,
      bodyStart,
      bodyLength,
      names,
      firstLocalCallable,
      localCallableCount,
      callableNameStarts,
      callableNameLengths,
      callableParameterCounts,
      /* dependencyCount= */ 0,
      callRows,
      callRows
    );
  }

  /// Resolves local and direct-dependency calls from one retained UTF-8 callable body.
  public long resolveUtf8ProductSourceCallProducts(
    borrow utf8 body,
    long bodyStart,
    long bodyLength,
    borrow byteview names,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow mut words callRows
  ) {
    return resolveSelectedUtf8ProductSourceCallProducts(
      true,
      true,
      body,
      bodyStart,
      bodyLength,
      names,
      firstLocalCallable,
      localCallableCount,
      callableNameStarts,
      callableNameLengths,
      callableParameterCounts,
      dependencyCount,
      dependencyRows,
      callRows
    );
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
