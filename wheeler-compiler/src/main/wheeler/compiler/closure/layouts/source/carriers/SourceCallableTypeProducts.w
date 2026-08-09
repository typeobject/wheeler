//! Resolves primitive and source-local nominal callable types.

module wheeler.compiler.closure.source_callable_type_products;

import wheeler.compiler.closure.callable_type_products;

classical class SourceCallableTypeProducts {
  private const long AGGREGATE_ROWS = 832;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_PARAMETERS = 16384;

  /// Reports source-independent callable and parameter type extents.
  public record SourceCallableTypeProductPlan(
    long callableCount,
    long parameterCount,
    boolean valid
  ) {}

  private boolean sameRange(
    borrow byteview source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 256 {
      if (source[leftStart + offset] != source[rightStart + offset]) {
        return false;
      }

      offset += 1;
    }

    return true;
  }

  private long localNominalType(
    borrow byteview source,
    long start,
    long length,
    long aggregateCount,
    borrow mut words aggregateRows
  ) {
    long selected = -1;
    long matches = 0;
    long recordOrdinal = 0;
    long variantOrdinal = 0;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long kind = aggregateRows[aggregate];
      if (kind == 1) {
        if (
          sameRange(
            source,
            start,
            length,
            aggregateRows[64 + aggregate],
            aggregateRows[128 + aggregate]
          )
        ) {
          selected = 268435456 + recordOrdinal;
          matches += 1;
        }

        recordOrdinal += 1;
      }

      if (kind == 4) {
        if (
          sameRange(
            source,
            start,
            length,
            aggregateRows[64 + aggregate],
            aggregateRows[128 + aggregate]
          )
        ) {
          selected = 536870912 + variantOrdinal;
          matches += 1;
        }

        variantOrdinal += 1;
      }

      aggregate += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Publishes all callable types only after every primitive or nominal range resolves.
  public SourceCallableTypeProductPlan materializeSourceCallableTypes(
    borrow byteview source,
    long aggregateCount,
    borrow mut words aggregateRows,
    long callableCount,
    long parameterCount,
    borrow mut words resultTypeStarts,
    borrow mut words resultTypeLengths,
    borrow mut words firstParameters,
    borrow mut words parameterCounts,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes,
    borrow mut words resultTypes,
    borrow mut words parameterTypes
  ) {
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-1 < parameterCount);
    assert(parameterCount < MAX_PARAMETERS + 1);
    assert(bufferLength(resultTypeStarts) == MAX_CALLABLES);
    assert(bufferLength(resultTypeLengths) == MAX_CALLABLES);
    assert(bufferLength(firstParameters) == MAX_CALLABLES);
    assert(bufferLength(parameterCounts) == MAX_CALLABLES);
    assert(bufferLength(parameterTypeStarts) == MAX_PARAMETERS);
    assert(bufferLength(parameterTypeLengths) == MAX_PARAMETERS);
    assert(bufferLength(parameterModes) == MAX_PARAMETERS);
    assert(bufferLength(resultTypes) == MAX_CALLABLES);
    assert(bufferLength(parameterTypes) == MAX_PARAMETERS);

    region staging = new region(/* bytes= */ 163840, /* allocations= */ 2);
    words stagedResults = allocate(staging, MAX_CALLABLES);
    words stagedParameters = allocate(staging, MAX_PARAMETERS);
    boolean valid = true;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long start = resultTypeStarts[callable];
      long length = resultTypeLengths[callable];
      long firstParameter = firstParameters[callable];
      long ownedParameters = parameterCounts[callable];
      if (start < 0) {
        valid = false;
      }

      if (length < 1) {
        valid = false;
      }

      if (bufferLength(source) < start) {
        valid = false;
      } else {
        if (bufferLength(source) - start < length) {
          valid = false;
        }
      }

      if (firstParameter < 0) {
        valid = false;
      }

      if (parameterCount < firstParameter) {
        valid = false;
      }

      if (ownedParameters < 0) {
        valid = false;
      }

      if (parameterCount - firstParameter < ownedParameters) {
        valid = false;
      }

      long type = -1;
      if (valid) {
        type = sourcePrimitiveType(source, start, length);
        if (type < 0) {
          type = localNominalType(source, start, length, aggregateCount, aggregateRows);
        }
      }

      if (type < 0) {
        valid = false;
      } else {
        set(stagedResults, callable, type);
      }

      callable += 1;
    }

    long parameter = 0;
    while (parameter < parameterCount) limit MAX_PARAMETERS {
      long parameterStart = parameterTypeStarts[parameter];
      long parameterLength = parameterTypeLengths[parameter];
      long parameterMode = parameterModes[parameter];
      if (parameterStart < 0) {
        valid = false;
      }

      if (parameterLength < 1) {
        valid = false;
      }

      if (bufferLength(source) < parameterStart) {
        valid = false;
      } else {
        if (bufferLength(source) - parameterStart < parameterLength) {
          valid = false;
        }
      }

      if (parameterMode < 0) {
        valid = false;
      }

      if (2 < parameterMode) {
        valid = false;
      }

      long parameterType = -1;
      if (valid) {
        parameterType = sourcePrimitiveType(source, parameterStart, parameterLength);
        if (parameterType < 0) {
          parameterType = localNominalType(
            source,
            parameterStart,
            parameterLength,
            aggregateCount,
            aggregateRows
          );
        }
      }

      if (parameterType < 1) {
        valid = false;
      } else {
        set(stagedParameters, parameter, parameterType);
      }

      parameter += 1;
    }

    if (valid) {
      callable = 0;
      while (callable < callableCount) limit MAX_CALLABLES {
        set(resultTypes, callable, stagedResults[callable]);
        callable += 1;
      }

      parameter = 0;
      while (parameter < parameterCount) limit MAX_PARAMETERS {
        set(parameterTypes, parameter, stagedParameters[parameter]);
        parameter += 1;
      }
    }

    drop(stagedParameters);
    drop(stagedResults);
    drop(staging);
    return new SourceCallableTypeProductPlan(callableCount, parameterCount, valid);
  }
}
