//! Collects source-ordered local calls across one retained module.

module wheeler.compiler.closure.source_module_call_products;

import wheeler.compiler.closure.qualified_source_call_products;
import wheeler.compiler.closure.source_call_products;

classical class SourceModuleCallProducts {
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_ROWS = 1024;
  private const long MAX_CALLABLES = 64;
  private const long MAX_PRODUCT_CALLABLES = 4096;
  private const long STATEMENT_ROWS = 28672;

  /// Reports one complete module-local call and statement product set.
  public record SourceModuleCallPlan(long callCount, boolean valid) {}

  /// Adds qualified imported calls and republishes all calls in source order.
  public SourceModuleCallPlan appendQualifiedSourceModuleCallProducts(
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
    long firstImportedCallable,
    long importedCallableCount,
    borrow byteview qualifierNames,
    borrow mut words qualifierNameStarts,
    borrow mut words qualifierNameLengths,
    borrow mut words qualifierDependencyRanks,
    borrow mut words importedDependencyRanks,
    long statementCount,
    borrow mut words statementRows,
    long unqualifiedCallCount,
    borrow mut words callRows,
    borrow mut words callStatements
  ) {
    assert(-1 < unqualifiedCallCount);
    assert(unqualifiedCallCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(callStatements) == CALL_COUNT_LIMIT);
    region staging = new region(/* bytes= */ 20480, /* allocations= */ 4);
    words combinedCalls = allocate(staging, CALL_ROWS);
    words combinedStatements = allocate(staging, CALL_COUNT_LIMIT);
    words bodyCalls = allocate(staging, CALL_ROWS);
    words bodyStatements = allocate(staging, CALL_COUNT_LIMIT);
    long initial = 0;
    while (initial < unqualifiedCallCount) limit CALL_COUNT_LIMIT {
      set(combinedCalls, initial, callRows[initial]);
      set(combinedCalls, 256 + initial, callRows[256 + initial]);
      set(combinedCalls, 512 + initial, callRows[512 + initial]);
      set(combinedCalls, 768 + initial, callRows[768 + initial]);
      set(combinedStatements, initial, callStatements[initial]);
      initial += 1;
    }

    boolean valid = true;
    long combinedCount = unqualifiedCallCount;
    long localCallable = 0;
    while (localCallable < callableCount) limit MAX_CALLABLES {
      long sourceCallable = firstCallable + localCallable;
      long bodyStart = bodyStarts[sourceCallable] - archiveSourceStart;
      long bodyLength = bodyLengths[sourceCallable];
      QualifiedSourceCallPlan qualifiedPlan = resolveQualifiedSourceCallProducts(
        source,
        bodyStart,
        bodyLength,
        names,
        firstImportedCallable,
        importedCallableCount,
        callableNameStarts,
        callableNameLengths,
        callableParameterCounts,
        qualifierNames,
        qualifierNameStarts,
        qualifierNameLengths,
        qualifierDependencyRanks,
        importedDependencyRanks,
        bodyCalls
      );
      if (qualifiedPlan.valid == false) {
        valid = false;
      }

      if (CALL_COUNT_LIMIT - combinedCount < qualifiedPlan.callCount) {
        valid = false;
      }

      if (valid) {
        SourceCallStatementPlan statementPlan = bindSourceCallStatements(
          qualifiedPlan.callCount,
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
      while (bodyCall < qualifiedPlan.callCount) limit CALL_COUNT_LIMIT {
        if (valid) {
          long target = combinedCount + bodyCall;
          set(combinedCalls, target, bodyCalls[bodyCall]);
          set(combinedCalls, 256 + target, bodyCalls[256 + bodyCall]);
          set(combinedCalls, 512 + target, bodyCalls[512 + bodyCall]);
          set(combinedCalls, 768 + target, bodyCalls[768 + bodyCall]);
          set(combinedStatements, target, bodyStatements[bodyCall]);
        }

        bodyCall += 1;
      }

      combinedCount += qualifiedPlan.callCount;
      localCallable += 1;
    }

    long published = 0;
    while (published < combinedCount) limit CALL_COUNT_LIMIT {
      long selected = -1;
      long selectedStart = 32769;
      long candidate = 0;
      while (candidate < combinedCount) limit CALL_COUNT_LIMIT {
        long candidateStart = combinedCalls[candidate];
        if (candidateStart < selectedStart) {
          selected = candidate;
          selectedStart = candidateStart;
        }

        candidate += 1;
      }

      if (selected < 0) {
        valid = false;
      }

      if (valid) {
        set(bodyCalls, published, combinedCalls[selected]);
        set(bodyCalls, 256 + published, combinedCalls[256 + selected]);
        set(bodyCalls, 512 + published, combinedCalls[512 + selected]);
        set(bodyCalls, 768 + published, combinedCalls[768 + selected]);
        set(bodyStatements, published, combinedStatements[selected]);
        set(combinedCalls, selected, 32769);
      }

      published += 1;
    }

    if (valid) {
      published = 0;
      while (published < combinedCount) limit CALL_COUNT_LIMIT {
        set(callRows, published, bodyCalls[published]);
        set(callRows, 256 + published, bodyCalls[256 + published]);
        set(callRows, 512 + published, bodyCalls[512 + published]);
        set(callRows, 768 + published, bodyCalls[768 + published]);
        set(callStatements, published, bodyStatements[published]);
        published += 1;
      }
    }

    drop(bodyStatements);
    drop(bodyCalls);
    drop(combinedStatements);
    drop(combinedCalls);
    drop(staging);
    if (valid == false) {
      return new SourceModuleCallPlan(0, false);
    }

    return new SourceModuleCallPlan(combinedCount, true);
  }

  /// Resolves each callable body and publishes absolute call ranges atomically.
  public SourceModuleCallPlan materializeSourceModuleCallProducts(
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
    long dependencyCount,
    borrow mut words dependencyRows,
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
    assert(-1 < dependencyCount);
    assert(dependencyCount < MAX_PRODUCT_CALLABLES + 1);
    if (0 < dependencyCount) {
      assert(bufferLength(dependencyRows) == 8192);
    }

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
        if (0 < dependencyCount) {
          bodyCallCount = resolveUtf8ProductSourceCallProducts(
            source,
            bodyStart,
            bodyLength,
            names,
            /* firstLocalCallable= */ 0,
            callableCount,
            callableNameStarts,
            callableNameLengths,
            callableParameterCounts,
            dependencyCount,
            dependencyRows,
            bodyCalls
          );
        } else {
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
        }

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
