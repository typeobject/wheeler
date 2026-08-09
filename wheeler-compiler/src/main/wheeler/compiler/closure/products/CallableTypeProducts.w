//! Freezes primitive callable types before dependency source is released.

module wheeler.compiler.closure.callable_type_products;

classical class CallableTypeProducts {
  private const long MAX_CALLABLES = 4096;
  private const long MAX_PARAMETERS = 16384;

  /// Reports whether every source range became a source-independent type code.
  public record CallableTypeProductPlan(long callableCount, long parameterCount, boolean valid) {}

  private boolean matches4(borrow byteview source, long start, long a, long b, long c, long d) {
    if (source[start] != a) {
      return false;
    }

    if (source[start + 1] != b) {
      return false;
    }

    if (source[start + 2] != c) {
      return false;
    }

    return source[start + 3] == d;
  }

  private boolean matches5(
    borrow byteview source,
    long start,
    long a,
    long b,
    long c,
    long d,
    long e
  ) {
    if (matches4(source, start, a, b, c, d) == false) {
      return false;
    }

    return source[start + 4] == e;
  }

  private boolean matches6(
    borrow byteview source,
    long start,
    long a,
    long b,
    long c,
    long d,
    long e,
    long f
  ) {
    if (matches5(source, start, a, b, c, d, e) == false) {
      return false;
    }

    return source[start + 5] == f;
  }

  private boolean matches7(
    borrow byteview source,
    long start,
    long a,
    long b,
    long c,
    long d,
    long e,
    long f,
    long g
  ) {
    if (matches6(source, start, a, b, c, d, e, f) == false) {
      return false;
    }

    return source[start + 6] == g;
  }

  private boolean matches8(
    borrow byteview source,
    long start,
    long a,
    long b,
    long c,
    long d,
    long e,
    long f,
    long g,
    long h
  ) {
    if (matches7(source, start, a, b, c, d, e, f, g) == false) {
      return false;
    }

    return source[start + 7] == h;
  }

  private long primitiveType(borrow byteview source, long start, long length) {
    if (length == 4) {
      if (matches4(source, start, 118, 111, 105, 100)) {
        return 0;
      }

      if (matches4(source, start, 108, 111, 110, 103)) {
        return 1;
      }

      if (matches4(source, start, 117, 116, 102, 56)) {
        return 7;
      }

      if (matches4(source, start, 68, 111, 110, 101)) {
        return 14;
      }
    }

    if (length == 5) {
      if (matches5(source, start, 119, 111, 114, 100, 115)) {
        return 4;
      }

      if (matches5(source, start, 98, 121, 116, 101, 115)) {
        return 5;
      }
    }

    if (length == 6) {
      if (matches6(source, start, 114, 101, 103, 105, 111, 110)) {
        return 3;
      }
    }

    if (length == 7) {
      if (matches7(source, start, 98, 111, 111, 108, 101, 97, 110)) {
        return 2;
      }

      if (matches7(source, start, 108, 111, 110, 103, 109, 97, 112)) {
        return 6;
      }
    }

    if (length == 8) {
      if (matches8(source, start, 98, 121, 116, 101, 118, 105, 101, 119)) {
        return 13;
      }
    }

    return -1;
  }

  /// Resolves primitive type ranges atomically while their local source is leased.
  public CallableTypeProductPlan materializePrimitiveCallableTypes(
    borrow byteview source,
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

    region scratch = new region(/* bytes= */ 163840, /* allocations= */ 2);
    words scratchResults = allocate(scratch, MAX_CALLABLES);
    words scratchParameters = allocate(scratch, MAX_PARAMETERS);
    boolean valid = true;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long start = resultTypeStarts[callable];
      long length = resultTypeLengths[callable];
      long firstParameter = firstParameters[callable];
      long ownedParameters = parameterCounts[callable];
      boolean callableValid = true;
      if (start < 0) {
        callableValid = false;
      }

      if (bufferLength(source) < start) {
        callableValid = false;
      }

      if (length < 1) {
        callableValid = false;
      }

      if (callableValid) {
        if (bufferLength(source) - start < length) {
          callableValid = false;
        }
      }

      if (firstParameter < 0) {
        callableValid = false;
      }

      if (parameterCount < firstParameter) {
        callableValid = false;
      }

      if (ownedParameters < 0) {
        callableValid = false;
      }

      if (callableValid) {
        if (parameterCount - firstParameter < ownedParameters) {
          callableValid = false;
        }
      }

      if (callableValid) {
        long type = primitiveType(source, start, length);
        if (type < 0) {
          callableValid = false;
        } else {
          set(scratchResults, callable, type);
        }
      }

      if (callableValid == false) {
        valid = false;
      }

      callable += 1;
    }

    long parameter = 0;
    while (parameter < parameterCount) limit MAX_PARAMETERS {
      long parameterStart = parameterTypeStarts[parameter];
      long parameterLength = parameterTypeLengths[parameter];
      long parameterMode = parameterModes[parameter];
      boolean parameterValid = true;
      if (parameterStart < 0) {
        parameterValid = false;
      }

      if (bufferLength(source) < parameterStart) {
        parameterValid = false;
      }

      if (parameterLength < 1) {
        parameterValid = false;
      }

      if (parameterValid) {
        if (bufferLength(source) - parameterStart < parameterLength) {
          parameterValid = false;
        }
      }

      if (parameterMode < 0) {
        parameterValid = false;
      }

      if (2 < parameterMode) {
        parameterValid = false;
      }

      if (parameterValid) {
        long parameterType = primitiveType(source, parameterStart, parameterLength);
        if (parameterType < 1) {
          parameterValid = false;
        } else {
          set(scratchParameters, parameter, parameterType);
        }
      }

      if (parameterValid == false) {
        valid = false;
      }

      parameter += 1;
    }

    if (valid) {
      callable = 0;
      while (callable < callableCount) limit MAX_CALLABLES {
        set(resultTypes, callable, scratchResults[callable]);
        callable += 1;
      }

      parameter = 0;
      while (parameter < parameterCount) limit MAX_PARAMETERS {
        set(parameterTypes, parameter, scratchParameters[parameter]);
        parameter += 1;
      }
    }

    drop(scratchParameters);
    drop(scratchResults);
    drop(scratch);
    return new CallableTypeProductPlan(callableCount, parameterCount, valid);
  }
}
