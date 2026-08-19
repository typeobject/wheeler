//! Resolves canonically qualified imported calls from closed target products.

module wheeler.compiler.closure.qualified_source_call_products;

import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class QualifiedSourceCallProducts {
  private const long CALL_ROWS = 1024;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_CALLS = 256;
  private const long MAX_NAME_BYTES = 1048576;
  private const long PUNCTUATION_UNDERSCORE = 95;
  private const long TOKEN_ARENA_BYTES = 98320;

  /// Reports one atomically published qualified-call table.
  public record QualifiedSourceCallPlan(long callCount, boolean valid) {}

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

  private boolean sameBytes(
    borrow utf8 source,
    long sourceStart,
    long sourceLength,
    borrow byteview product,
    long productStart,
    long productLength
  ) {
    if (sourceLength != productLength) {
      return false;
    }

    long offset = 0;
    while (offset < sourceLength) limit 256 {
      if (utf8Scalar(source, sourceStart + offset) != product[productStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private boolean qualifierScalar(long scalar) {
    boolean accepted = PUNCTUATION_DOT == scalar;
    if (PUNCTUATION_UNDERSCORE == scalar) {
      accepted = true;
    }

    if (96 < scalar) {
      if (scalar < 123) {
        accepted = true;
      }
    }

    if (47 < scalar) {
      if (scalar < 58) {
        accepted = true;
      }
    }

    return accepted;
  }

  private long qualifierStart(borrow utf8 source, long end) {
    long cursor = end;
    while (0 < cursor) limit 256 {
      long scalar = utf8Scalar(source, cursor - 1);
      if (qualifierScalar(scalar)) {
        cursor -= 1;
      } else {
        return cursor;
      }
    }

    return cursor;
  }

  private boolean canonicalQualifier(borrow utf8 source, long start, long length) {
    if (length < 1) {
      return false;
    }

    if (256 < length) {
      return false;
    }

    boolean segmentStart = true;
    long offset = 0;
    while (offset < length) limit 256 {
      long scalar = utf8Scalar(source, start + offset);
      if (scalar == PUNCTUATION_DOT) {
        if (segmentStart) {
          return false;
        }

        segmentStart = true;
      } else {
        boolean first = 96 < scalar;
        if (122 < scalar) {
          first = false;
        }

        if (scalar == PUNCTUATION_UNDERSCORE) {
          first = true;
        }

        if (segmentStart) {
          if (first == false) {
            return false;
          }
        } else {
          if (qualifierScalar(scalar) == false) {
            return false;
          }
        }

        segmentStart = false;
      }

      offset += 1;
    }

    return segmentStart == false;
  }

  /// Replaces parser-default widths for calls carrying an exact qualifier.
  public boolean materializeQualifiedCallStatementWidths(
    borrow utf8 source,
    long callCount,
    long statementCount,
    borrow mut words callRows,
    borrow mut words callStatements,
    borrow mut words targetResultTypes,
    borrow mut words statementWidths
  ) {
    assert(-1 < callCount);
    assert(callCount < MAX_CALLS + 1);
    assert(-1 < statementCount);
    assert(statementCount < MAX_CALLABLES + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callStatements) == MAX_CALLS);
    assert(bufferLength(targetResultTypes) == MAX_CALLABLES);
    assert(bufferLength(statementWidths) == MAX_CALLABLES);
    region staging = new region(/* bytes= */ 32768, /* allocations= */ 1);
    words stagedWidths = allocate(staging, MAX_CALLABLES);
    long statement = 0;
    while (statement < statementCount) limit MAX_CALLABLES {
      set(stagedWidths, statement, statementWidths[statement]);
      statement += 1;
    }

    boolean valid = true;
    long call = 0;
    while (call < callCount) limit MAX_CALLS {
      long callStart = callRows[call];
      boolean callStartValid = -1 < callStart;
      if (bufferLength(source) < callStart) {
        callStartValid = false;
      }

      if (callStartValid == false) {
        valid = false;
      }

      if (callStartValid) {
        if (1 < callStart) {
          if (utf8Scalar(source, callStart - 1) == PUNCTUATION_COLON) {
            if (utf8Scalar(source, callStart - 2) == PUNCTUATION_COLON) {
              long owner = callStatements[call];
              long target = callRows[768 + call];
              long arity = callRows[512 + call];
              if (owner < 0) {
                valid = false;
              }

              if (MAX_CALLABLES - 1 < owner) {
                valid = false;
              }

              if (target < 0) {
                valid = false;
              }

              if (MAX_CALLABLES - 1 < target) {
                valid = false;
              }

              if (arity < 0) {
                valid = false;
              }

              if (7 < arity) {
                valid = false;
              }

              long resultKind = -1;
              if (-1 < target) {
                if (target < MAX_CALLABLES) {
                  resultKind = targetResultTypes[target];
                }
              }

              if (resultKind < 0) {
                valid = false;
              }

              if (2 < resultKind) {
                valid = false;
              }

              if (valid) {
                long width = arity * 2;
                if (0 < resultKind) {
                  width += 2;
                }

                set(stagedWidths, owner, width);
              }
            }
          }
        }
      }

      call += 1;
    }

    if (valid) {
      statement = 0;
      while (statement < statementCount) limit MAX_CALLABLES {
        set(statementWidths, statement, stagedWidths[statement]);
        statement += 1;
      }
    }

    drop(stagedWidths);
    drop(staging);
    return valid;
  }

  /// Resolves qualified calls against target-aligned module names and direct ranks.
  public QualifiedSourceCallPlan resolveQualifiedSourceCallProducts(
    borrow utf8 source,
    long bodyStart,
    long bodyLength,
    borrow byteview callableNames,
    long firstImportedCallable,
    long importedCallableCount,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    borrow byteview qualifierNames,
    borrow mut words qualifierNameStarts,
    borrow mut words qualifierNameLengths,
    borrow mut words qualifierDependencyRanks,
    borrow mut words importedDependencyRanks,
    borrow mut words callRows
  ) {
    assert(-1 < bodyStart);
    assert(0 < bodyLength);
    assert(bodyLength < bufferLength(source) - bodyStart + 1);
    assert(-1 < firstImportedCallable);
    assert(-1 < importedCallableCount);
    assert(importedCallableCount < MAX_CALLABLES - firstImportedCallable + 1);
    assert(bufferLength(callableNameStarts) == MAX_CALLABLES);
    assert(bufferLength(callableNameLengths) == MAX_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_CALLABLES);
    assert(bufferLength(qualifierNames) == MAX_NAME_BYTES);
    assert(MAX_CALLABLES - 1 < bufferLength(qualifierNameStarts));
    assert(MAX_CALLABLES - 1 < bufferLength(qualifierNameLengths));
    assert(MAX_CALLABLES - 1 < bufferLength(qualifierDependencyRanks));
    assert(MAX_CALLABLES - 1 < bufferLength(importedDependencyRanks));
    assert(bufferLength(callRows) == CALL_ROWS);

    region tokens = new region(/* bytes= */ TOKEN_ARENA_BYTES, /* allocations= */ 3);
    words tokenKinds = allocate(tokens, MAX_COMPILER_TOKENS);
    words tokenStarts = allocate(tokens, MAX_COMPILER_TOKENS);
    words tokenLengths = allocate(tokens, MAX_COMPILER_TOKENS);
    region staging = new region(/* bytes= */ 8192, /* allocations= */ 1);
    words stagedCalls = allocate(staging, CALL_ROWS);
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    boolean valid = -1 < tokenCount;
    long callCount = 0;
    long token = 0;
    while (token + 1 < tokenCount) limit MAX_COMPILER_TOKENS {
      long callStart = tokenStarts[token];
      if (bodyStart - 1 < callStart) {
        if (callStart < bodyStart + bodyLength) {
          if (tokenKinds[token] == 1) {
            if (
              punctuationAt(source, tokenKinds, tokenStarts, token + 1, PUNCTUATION_OPEN_PAREN)
            ) {
              boolean qualifiedTokens = false;
              if (1 < token) {
                if (
                  punctuationAt(source, tokenKinds, tokenStarts, token - 1, PUNCTUATION_COLON)
                ) {
                  if (
                    punctuationAt(
                      source,
                      tokenKinds,
                      tokenStarts,
                      token - 2,
                      PUNCTUATION_COLON
                    )
                  ) {
                    qualifiedTokens = true;
                  }
                }
              }

              if (qualifiedTokens) {
                if (1 < callStart) {
                  if (utf8Scalar(source, callStart - 1) == PUNCTUATION_COLON) {
                    if (utf8Scalar(source, callStart - 2) == PUNCTUATION_COLON) {} else {
                      valid = false;
                    }
                  } else {
                    valid = false;
                  }
                } else {
                  valid = false;
                }
              }

              if (1 < callStart) {
                if (utf8Scalar(source, callStart - 1) == PUNCTUATION_COLON) {
                  if (utf8Scalar(source, callStart - 2) == PUNCTUATION_COLON) {
                    long qualifierEnd = callStart - 2;
                    long qualifierBegin = qualifierStart(source, qualifierEnd);
                    long qualifierLength = qualifierEnd - qualifierBegin;
                    if (canonicalQualifier(source, qualifierBegin, qualifierLength)) {} else {
                      valid = false;
                    }

                    long close = closingParen(
                      source,
                      tokenKinds,
                      tokenStarts,
                      token + 1,
                      tokenCount
                    );
                    if (-1 < close) {} else {
                      valid = false;
                    }

                    long arity = -1;
                    if (-1 < close) {
                      arity = parameterCount(source, tokenKinds, tokenStarts, token + 1, close);
                    }

                    if (-1 < arity) {} else {
                      valid = false;
                    }

                    long selected = -1;
                    long imported = 0;
                    while (imported < importedCallableCount) limit MAX_CALLABLES {
                      long callable = firstImportedCallable + imported;
                      if (
                        qualifierDependencyRanks[imported] == importedDependencyRanks[imported]
                      ) {
                        if (callableParameterCounts[callable] == arity) {
                          if (
                            sameBytes(
                              source,
                              qualifierBegin,
                              qualifierLength,
                              qualifierNames,
                              qualifierNameStarts[imported],
                              qualifierNameLengths[imported]
                            )
                          ) {
                            if (
                              sameBytes(
                                source,
                                callStart,
                                tokenLengths[token],
                                callableNames,
                                callableNameStarts[callable],
                                callableNameLengths[callable]
                              )
                            ) {
                              if (selected < 0) {
                                selected = callable;
                              } else {
                                valid = false;
                              }
                            }
                          }
                        }
                      }

                      imported += 1;
                    }

                    if (selected < 0) {
                      valid = false;
                    }

                    if (callCount < MAX_CALLS) {} else {
                      valid = false;
                    }

                    if (valid) {
                      set(stagedCalls, callCount, callStart);
                      set(stagedCalls, 256 + callCount, tokenLengths[token]);
                      set(stagedCalls, 512 + callCount, arity);
                      set(stagedCalls, 768 + callCount, selected);
                      callCount += 1;
                    }
                  }
                }
              }
            }
          }
        }
      }

      token += 1;
    }

    if (valid) {
      long call = 0;
      while (call < callCount) limit MAX_CALLS {
        set(callRows, call, stagedCalls[call]);
        set(callRows, 256 + call, stagedCalls[256 + call]);
        set(callRows, 512 + call, stagedCalls[512 + call]);
        set(callRows, 768 + call, stagedCalls[768 + call]);
        call += 1;
      }
    }

    drop(stagedCalls);
    drop(staging);
    drop(tokenLengths);
    drop(tokenStarts);
    drop(tokenKinds);
    drop(tokens);
    return new QualifiedSourceCallPlan(callCount, valid);
  }
}
