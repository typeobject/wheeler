//! Stages callable coordinates through the shared class-member and signature fronts.

module wheeler.compiler.closure.source_callable_front_products;

import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_member_fronts;
import wheeler.compiler.source_member_modifiers;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class SourceCallableFrontProducts {
  private const long MAX_CALLABLES = 4096;
  private const long MAX_SOURCE_CALLABLES = 64;
  private const long MAX_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long MAX_SOURCE_COORDINATE = 9223372036854775807;
  private const long MODULE_RANGE_COLUMNS = 2;
  private const long PARAMETER_TOTAL_COLUMNS = 1;
  private const long CLASS_PREFIX_TOKENS = 4;
  private const long RESULT_SLOT_COLUMNS = 1 + 1;

  /// Stages one complete class and returns its callable count, or negative one on rejection.
  /// Coordinates include sourceStart. The callable window starts at firstCallable.
  /// All mutable arguments are private scratch and may change on rejection.
  /// The owner must validate the complete batch before publishing any staged products.
  /// This front does not resolve names, execute bodies, or verify source claims.
  public long stageSourceCallableProducts(
    borrow utf8 source,
    long sourceStart,
    long owner,
    long firstCallable,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words moduleRange,
    borrow mut words callableOwners,
    borrow mut words callableVisibilities,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableSignatureStarts,
    borrow mut words callableSignatureLengths,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callableFirstParameters,
    borrow mut words callableResultTypeStarts,
    borrow mut words callableResultTypeLengths,
    borrow mut words callableEffects,
    borrow mut words callableResultSlotWidths,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes,
    borrow mut words parameterTotal
  ) {
    long sourceLength = bufferLength(source);
    assert(0 < sourceLength);
    assert(sourceLength < MAX_SOURCE_BYTES + 1);
    assert(-1 < sourceStart);
    assert(sourceStart < MAX_SOURCE_COORDINATE - sourceLength + 1);
    assert(-1 < owner);
    assert(owner < MAX_MODULES);
    assert(-1 < firstCallable);
    assert(firstCallable < MAX_CALLABLES + 1);
    assert(bufferLength(tokenKinds) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenStarts) == MAX_COMPILER_TOKENS);
    assert(bufferLength(tokenLengths) == MAX_COMPILER_TOKENS);
    assert(bufferLength(moduleRange) == MODULE_RANGE_COLUMNS);
    assert(bufferLength(parameterTotal) == PARAMETER_TOTAL_COLUMNS);
    assert(-1 < parameterTotal[0]);
    assert(parameterTotal[0] < MAX_CLOSURE_PARAMETERS + 1);
    assert(bufferLength(callableOwners) == MAX_CALLABLES);
    assert(bufferLength(callableVisibilities) == MAX_CALLABLES);
    assert(bufferLength(callableNameStarts) == MAX_CALLABLES);
    assert(bufferLength(callableNameLengths) == MAX_CALLABLES);
    assert(bufferLength(callableSignatureStarts) == MAX_CALLABLES);
    assert(bufferLength(callableSignatureLengths) == MAX_CALLABLES);
    assert(bufferLength(callableBodyStarts) == MAX_CALLABLES);
    assert(bufferLength(callableBodyLengths) == MAX_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_CALLABLES);
    assert(bufferLength(callableFirstParameters) == MAX_CALLABLES);
    assert(bufferLength(callableResultTypeStarts) == MAX_CALLABLES);
    assert(bufferLength(callableResultTypeLengths) == MAX_CALLABLES);
    assert(bufferLength(callableEffects) == MAX_CALLABLES);
    assert(bufferLength(callableResultSlotWidths) == MAX_CALLABLES);
    assert(bufferLength(parameterTypeStarts) == MAX_CLOSURE_PARAMETERS);
    assert(bufferLength(parameterTypeLengths) == MAX_CLOSURE_PARAMETERS);
    assert(bufferLength(parameterModes) == MAX_CLOSURE_PARAMETERS);

    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    if (0 < tokenCount) {} else {
      return -1;
    }

    long body = moduleBodyStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      moduleRange,
      tokenCount
    );
    if (-1 < body) {} else {
      return -1;
    }

    if (
      classPrefixValid(source, tokenKinds, tokenStarts, tokenLengths, body, tokenCount) == false
    ) {
      return -1;
    }

    long cursor = body + CLASS_PREFIX_TOKENS;
    long callableCount = 0;
    boolean classClosed = false;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_BRACE)
      ) {
        classClosed = cursor + 1 == tokenCount;
        break;
      }

      long declarationStart = cursor;
      SourceMemberFront front = sourceMemberFront(
        source,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        tokenCount,
        declarationStart
      );
      if (front.valid == false) {
        return -1;
      }

      if (front.kind == 0) {
        if (callableCount < MAX_SOURCE_CALLABLES) {} else {
          return -1;
        }

        long callableIndex = firstCallable + callableCount;
        if (callableIndex < MAX_CALLABLES) {} else {
          return -1;
        }

        long nameToken = front.nameToken;
        long firstParen = nameToken + 1;
        long delimiter = front.bodyOpen;
        long closeBody = front.nextToken - 1;
        long closeParameters = front.parameterClose;
        long parameters = parameterCount(
          source,
          tokenKinds,
          tokenStarts,
          firstParen,
          closeParameters
        );
        if (-1 < parameters) {} else {
          return -1;
        }

        CallableHeader header = callableHeader(
          source,
          tokenStarts,
          tokenLengths,
          declarationStart,
          nameToken
        );
        if (header.valid) {} else {
          return -1;
        }

        long nextParameter = writeParameterProducts(
          source,
          sourceStart,
          tokenKinds,
          tokenStarts,
          tokenLengths,
          firstParen,
          closeParameters,
          parameters,
          parameterTotal[0],
          parameterTypeStarts,
          parameterTypeLengths,
          parameterModes
        );
        if (-1 < nextParameter) {} else {
          return -1;
        }

        long visibility = 0;
        if (header.exported) {
          visibility = 1;
        }

        long signatureStart = tokenStarts[declarationStart];
        long bodyStart = tokenStarts[delimiter];
        long bodyEnd = tokenStarts[closeBody] + tokenLengths[closeBody];
        set(callableOwners, callableIndex, owner);
        set(callableVisibilities, callableIndex, visibility);
        set(callableNameStarts, callableIndex, sourceStart + tokenStarts[nameToken]);
        set(callableNameLengths, callableIndex, tokenLengths[nameToken]);
        set(callableSignatureStarts, callableIndex, sourceStart + signatureStart);
        set(callableSignatureLengths, callableIndex, bodyStart - signatureStart);
        set(callableBodyStarts, callableIndex, sourceStart + bodyStart);
        set(callableBodyLengths, callableIndex, bodyEnd - bodyStart);
        set(callableParameterCounts, callableIndex, parameters);
        set(callableFirstParameters, callableIndex, parameterTotal[0]);
        long resultTypeStart = tokenStarts[header.resultTypeToken];
        long finalResultType = nameToken - 1;
        long resultTypeEnd = tokenStarts[finalResultType] + tokenLengths[finalResultType];
        set(callableResultTypeStarts, callableIndex, sourceStart + resultTypeStart);
        set(callableResultTypeLengths, callableIndex, resultTypeEnd - resultTypeStart);
        set(callableEffects, callableIndex, header.effects);
        long resultSlotWidth = 0;
        if (header.effects / MEMBER_REV % 2 == 1) {
          if (
            sourceTokenCode(source, tokenStarts, tokenLengths, header.resultTypeToken) == TOKEN_VOID
          ) {} else {
            resultSlotWidth = RESULT_SLOT_COLUMNS;
          }
        }

        set(callableResultSlotWidths, callableIndex, resultSlotWidth);
        set(parameterTotal, 0, nextParameter);
        callableCount += 1;
      }

      cursor = front.nextToken;
    }

    if (classClosed) {
      return callableCount;
    }

    return -1;
  }
}
