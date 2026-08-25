//! Bridges one counted eight-module fixture to the bounded differential executor.

module wheeler.compiler.closure.small_executor;

import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.plan;
import wheeler.compiler.graphs.executor;
import wheeler.compiler.graphs.matrix;

classical class SmallClosureExecutor {
  private const long FIXTURE_MODULE_COUNT = 8;
  private const long MAX_IMPORTED_MODULES = 7;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long PLAN_ARENA_BYTES = 616;
  private const long SOURCE_ARENA_BYTES = 262144;

  private long expandedModule(long compact, long rootModule) {
    if (compact < rootModule) {
      return compact;
    }

    return compact + 1;
  }

  private long compactModule(long module, long rootModule) {
    if (module < rootModule) {
      return module;
    }

    return module - 1;
  }

  private utf8 copyClosureSource(
    borrow byteview archive,
    long module,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut region arena
  ) {
    long sourceStart = sourceStarts[module];
    long sourceLength = sourceLengths[module];
    assert(0 < sourceLength);
    assert(sourceLength < MAX_SOURCE_BYTES + 1);
    assert(-1 < sourceStart);
    assert(sourceStart < bufferLength(archive) + 1);
    assert(sourceLength < bufferLength(archive) - sourceStart + 1);
    bytes sourceBytes = allocateBytes(arena, sourceLength);
    long cursor = 0;
    while (cursor < sourceLength) limit MAX_SOURCE_BYTES {
      setByte(sourceBytes, cursor, archive[sourceStart + cursor]);
      cursor += 1;
    }

    return freezeUtf8(sourceBytes);
  }

  /// Executes one counted seven-import differential fixture from archive ranges.
  ///
  /// This migration bridge does not define the production closure-size ceiling.
  public GraphPlanExecution executeSmallCountedClosure(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words edgeTargets,
    borrow mut words importRanks,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut bytes output
  ) {
    requireMetadata(plan.moduleCount == FIXTURE_MODULE_COUNT);
    requireMetadata(plan.externalCount == 0);
    requireMetadata(-1 < plan.rootModule);
    requireMetadata(plan.rootModule < plan.moduleCount);
    region planArena = new region(/* bytes= */ PLAN_ARENA_BYTES, /* allocations= */ 5);
    words graph = allocate(planArena, MAX_IMPORTED_MODULES * MAX_IMPORTED_MODULES);
    words rootDirect = allocate(planArena, MAX_IMPORTED_MODULES);
    words rootRanks = allocate(planArena, MAX_IMPORTED_MODULES);
    words order = allocate(planArena, MAX_IMPORTED_MODULES);
    words reachable = allocate(planArena, MAX_IMPORTED_MODULES);

    long owner = 0;
    while (owner < plan.moduleCount) limit FIXTURE_MODULE_COUNT {
      long firstImport = firstImports[owner];
      long directCount = directImportCounts[owner];
      requireMetadata(directCount < MAX_IMPORTED_MODULES + 1);
      long rank = 0;
      while (rank < directCount) limit MAX_IMPORTED_MODULES {
        long edge = firstImport + rank;
        requireMetadata(-1 < edge);
        requireMetadata(edge < plan.importCount);
        long target = edgeTargets[edge];
        requireMetadata(-1 < target);
        requireMetadata(target < plan.moduleCount);
        requireMetadata((target == plan.rootModule) == false);
        long compactTarget = compactModule(target, plan.rootModule);
        if (owner == plan.rootModule) {
          set(rootDirect, compactTarget, 1);
          set(rootRanks, compactTarget, importRanks[edge]);
        } else {
          long compactOwner = compactModule(owner, plan.rootModule);
          set(graph, compactTarget * MAX_IMPORTED_MODULES + compactOwner, 1);
        }

        rank += 1;
      }

      owner += 1;
    }

    BoundedGraphPlan bounded = planBoundedGraph(
      graph,
      rootDirect,
      rootRanks,
      MAX_IMPORTED_MODULES,
      order,
      reachable
    );
    requireMetadata(bounded.valid);
    region sourceArena = new region(/* bytes= */ SOURCE_ARENA_BYTES, /* allocations= */ 8);
    utf8 firstSource = copyClosureSource(
      archive,
      expandedModule(0, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 secondSource = copyClosureSource(
      archive,
      expandedModule(1, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 thirdSource = copyClosureSource(
      archive,
      expandedModule(2, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 fourthSource = copyClosureSource(
      archive,
      expandedModule(3, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 fifthSource = copyClosureSource(
      archive,
      expandedModule(4, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 sixthSource = copyClosureSource(
      archive,
      expandedModule(5, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 seventhSource = copyClosureSource(
      archive,
      expandedModule(6, plan.rootModule),
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    utf8 rootSource = copyClosureSource(
      archive,
      plan.rootModule,
      sourceStarts,
      sourceLengths,
      sourceArena
    );
    GraphPlanExecution result = executeGraphPlan(
      bounded,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource,
      output
    );
    drop(rootSource);
    drop(seventhSource);
    drop(sixthSource);
    drop(fifthSource);
    drop(fourthSource);
    drop(thirdSource);
    drop(secondSource);
    drop(firstSource);
    drop(sourceArena);
    drop(reachable);
    drop(order);
    drop(rootRanks);
    drop(rootDirect);
    drop(graph);
    drop(planArena);
    return result;
  }
}
