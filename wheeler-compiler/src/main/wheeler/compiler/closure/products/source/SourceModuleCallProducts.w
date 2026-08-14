//! Collects source-ordered local calls across one retained module.

module wheeler.compiler.closure.source_module_call_products;

import wheeler.compiler.closure.source_call_products;

classical class SourceModuleCallProducts {
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_ROWS = 1024;
  private const long MAX_CALLABLES = 64;
  private const long MAX_PRODUCT_CALLABLES = 4096;
  private const long STATEMENT_ROWS = 28672;

  /// Reports one complete module-local call and statement product set.
  public record SourceModuleCallPlan(long callCount, boolean valid) {}

  /// Resolves each callable body and publishes absolute call ranges atomically.
  public SourceModuleCallPlan materializeLocalSourceModuleCallProducts(
    borrow utf8 source,
    long archiveSourceStart,
    long firstCallable,
    long callableCount,
    borrow mut words bodyStarts,
    borrow mut words bodyLengths,
    borrow byteview names,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableParameterCounts,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words callRows,
    borrow mut words callStatements
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < firstCallable);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(callableCount < MAX_PRODUCT_CALLABLES - firstCallable + 1);
    assert(bufferLength(bodyStarts) == MAX_PRODUCT_CALLABLES);
    assert(bufferLength(bodyLengths) == MAX_PRODUCT_CALLABLES);
    assert(bufferLength(callableNameStarts) == MAX_PRODUCT_CALLABLES);
    assert(bufferLength(callableNameLengths) == MAX_PRODUCT_CALLABLES);
    assert(bufferLength(callableParameterCounts) == MAX_PRODUCT_CALLABLES);
    assert(-1 < statementCount);
    assert(statementCount < 4097);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);

    region staging = new region(/* bytes= */ 20480, /* allocations= */ 4);
    words stagedCalls = allocate(staging, CALL_ROWS);
    words stagedStatements = allocate(staging, CALL_COUNT_LIMIT);
    words bodyCalls = allocate(staging, CALL_ROWS);
    words bodyStatements = allocate(staging, CALL_COUNT_LIMIT);
    boolean valid = true;
    long callCount = 0;
    long localCallable = 0;
    while (localCallable < callableCount) limit MAX_CALLABLES {
      long sourceCallable = firstCallable + localCallable;
      long bodyStart = bodyStarts[sourceCallable] - archiveSourceStart;
      long bodyLength = bodyLengths[sourceCallable];
      if (bodyStart < 0) {
        valid = false;
      }

      if (bodyLength < 1) {
        valid = false;
      }

      long bodyCallCount = 0;
      if (valid) {
        bodyCallCount = resolveLocalUtf8ProductSourceCallProducts(
          source,
          bodyStart,
          bodyLength,
          names,
          /* firstLocalCallable= */ 0,
          callableCount,
          callableNameStarts,
          callableNameLengths,
          callableParameterCounts,
          bodyCalls
        );
        if (CALL_COUNT_LIMIT - callCount < bodyCallCount) {
          valid = false;
        }
      }

      if (valid) {
        SourceCallStatementPlan statementPlan = bindSourceCallStatements(
          bodyCallCount,
          /* callSourceBase= */ 0,
          localCallable,
          statementCount,
          statementRows,
          bodyCalls,
          bodyStatements
        );
        if (statementPlan.valid == false) {
          valid = false;
        }
      }

      long bodyCall = 0;
      while (bodyCall < bodyCallCount) limit CALL_COUNT_LIMIT {
        if (valid) {
          long targetCall = callCount + bodyCall;
          set(stagedCalls, targetCall, bodyCalls[bodyCall]);
          set(stagedCalls, 256 + targetCall, bodyCalls[256 + bodyCall]);
          set(stagedCalls, 512 + targetCall, bodyCalls[512 + bodyCall]);
          set(stagedCalls, 768 + targetCall, bodyCalls[768 + bodyCall]);
          set(stagedStatements, targetCall, bodyStatements[bodyCall]);
        }

        bodyCall += 1;
      }

      callCount += bodyCallCount;
      localCallable += 1;
    }

    if (valid) {
      long call = 0;
      while (call < callCount) limit CALL_COUNT_LIMIT {
        set(callRows, call, stagedCalls[call]);
        set(callRows, 256 + call, stagedCalls[256 + call]);
        set(callRows, 512 + call, stagedCalls[512 + call]);
        set(callRows, 768 + call, stagedCalls[768 + call]);
        set(callStatements, call, stagedStatements[call]);
        call += 1;
      }
    }

    drop(bodyStatements);
    drop(bodyCalls);
    drop(stagedStatements);
    drop(stagedCalls);
    drop(staging);
    if (valid == false) {
      return new SourceModuleCallPlan(0, false);
    }

    return new SourceModuleCallPlan(callCount, true);
  }
}
