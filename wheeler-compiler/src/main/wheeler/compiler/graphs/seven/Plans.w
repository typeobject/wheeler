//! Builds complete plans for bounded seven-module graphs.

module wheeler.compiler.graphs.seven.plans;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class SevenGraphPlans {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;
  private const long FIVE_IMPORTS = 5;
  private const long SIX_IMPORTS = 6;
  private const long SEVEN_IMPORTS = 7;

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importsCandidate) {} else {
      return false;
    }

    if (dependency.importCount == SINGLE_IMPORT) {
      return true;
    }

    if (dependency.importCount == TWO_IMPORTS) {
      return true;
    }

    if (dependency.importCount == THREE_IMPORTS) {
      return true;
    }

    if (dependency.importCount == FOUR_IMPORTS) {
      return true;
    }

    if (dependency.importCount == FIVE_IMPORTS) {
      return true;
    }

    return dependency.importCount == SIX_IMPORTS;
  }

  private long rootRank(borrow utf8 source, borrow utf8 rootSource) {
    HeaderDependency dependency = moduleDependency(source, rootSource);
    if (dependency.valid) {} else {
      return -1;
    }

    if (dependency.importsCandidate) {} else {
      return -1;
    }

    if (dependency.importCount == SINGLE_IMPORT) {
      return dependency.candidateImportRank;
    }

    if (dependency.importCount == TWO_IMPORTS) {
      return dependency.candidateImportRank;
    }

    if (dependency.importCount == THREE_IMPORTS) {
      return dependency.candidateImportRank;
    }

    if (dependency.importCount == FOUR_IMPORTS) {
      return dependency.candidateImportRank;
    }

    if (dependency.importCount == FIVE_IMPORTS) {
      return dependency.candidateImportRank;
    }

    if (dependency.importCount == SIX_IMPORTS) {
      return dependency.candidateImportRank;
    }

    if (dependency.importCount == SEVEN_IMPORTS) {
      return dependency.candidateImportRank;
    }

    return -1;
  }

  private void recordEdge(borrow mut words graph, long source, long dependent, boolean present) {
    if (present) {
      set(graph, source * MODULE_COUNT + dependent, 1);
    }
  }

  private void recordDirectedEdges(
    borrow mut words graph,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource
  ) {
    recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    recordEdge(graph, 0, 4, graphEdge(firstSource, fifthSource));
    recordEdge(graph, 0, 5, graphEdge(firstSource, sixthSource));
    recordEdge(graph, 0, 6, graphEdge(firstSource, seventhSource));
    recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    recordEdge(graph, 1, 4, graphEdge(secondSource, fifthSource));
    recordEdge(graph, 1, 5, graphEdge(secondSource, sixthSource));
    recordEdge(graph, 1, 6, graphEdge(secondSource, seventhSource));
    recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    recordEdge(graph, 2, 4, graphEdge(thirdSource, fifthSource));
    recordEdge(graph, 2, 5, graphEdge(thirdSource, sixthSource));
    recordEdge(graph, 2, 6, graphEdge(thirdSource, seventhSource));
    recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
    recordEdge(graph, 3, 4, graphEdge(fourthSource, fifthSource));
    recordEdge(graph, 3, 5, graphEdge(fourthSource, sixthSource));
    recordEdge(graph, 3, 6, graphEdge(fourthSource, seventhSource));
    recordEdge(graph, 4, 0, graphEdge(fifthSource, firstSource));
    recordEdge(graph, 4, 1, graphEdge(fifthSource, secondSource));
    recordEdge(graph, 4, 2, graphEdge(fifthSource, thirdSource));
    recordEdge(graph, 4, 3, graphEdge(fifthSource, fourthSource));
    recordEdge(graph, 4, 5, graphEdge(fifthSource, sixthSource));
    recordEdge(graph, 4, 6, graphEdge(fifthSource, seventhSource));
    recordEdge(graph, 5, 0, graphEdge(sixthSource, firstSource));
    recordEdge(graph, 5, 1, graphEdge(sixthSource, secondSource));
    recordEdge(graph, 5, 2, graphEdge(sixthSource, thirdSource));
    recordEdge(graph, 5, 3, graphEdge(sixthSource, fourthSource));
    recordEdge(graph, 5, 4, graphEdge(sixthSource, fifthSource));
    recordEdge(graph, 5, 6, graphEdge(sixthSource, seventhSource));
    recordEdge(graph, 6, 0, graphEdge(seventhSource, firstSource));
    recordEdge(graph, 6, 1, graphEdge(seventhSource, secondSource));
    recordEdge(graph, 6, 2, graphEdge(seventhSource, thirdSource));
    recordEdge(graph, 6, 3, graphEdge(seventhSource, fourthSource));
    recordEdge(graph, 6, 4, graphEdge(seventhSource, fifthSource));
    recordEdge(graph, 6, 5, graphEdge(seventhSource, sixthSource));
  }

  private void recordRoot(borrow mut words rootDirect, long source, long rank) {
    if (0 < rank + 1) {
      set(rootDirect, source, 1);
    }
  }

  /// Selects every rooted acyclic seven-module graph admitted by the matrix bound.
  public BoundedGraphPlan planSevenBoundedGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 616, /* allocations= */ 5);
    words graph = allocate(arena, 49);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words rootRanks = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
    words reachable = allocate(arena, MODULE_COUNT);
    recordDirectedEdges(
      graph,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource
    );
    long firstRank = rootRank(firstSource, rootSource);
    long secondRank = rootRank(secondSource, rootSource);
    long thirdRank = rootRank(thirdSource, rootSource);
    long fourthRank = rootRank(fourthSource, rootSource);
    long fifthRank = rootRank(fifthSource, rootSource);
    long sixthRank = rootRank(sixthSource, rootSource);
    long seventhRank = rootRank(seventhSource, rootSource);
    set(rootRanks, 0, firstRank);
    set(rootRanks, 1, secondRank);
    set(rootRanks, 2, thirdRank);
    set(rootRanks, 3, fourthRank);
    set(rootRanks, 4, fifthRank);
    set(rootRanks, 5, sixthRank);
    set(rootRanks, 6, seventhRank);
    recordRoot(rootDirect, 0, firstRank);
    recordRoot(rootDirect, 1, secondRank);
    recordRoot(rootDirect, 2, thirdRank);
    recordRoot(rootDirect, 3, fourthRank);
    recordRoot(rootDirect, 4, fifthRank);
    recordRoot(rootDirect, 5, sixthRank);
    recordRoot(rootDirect, 6, seventhRank);
    BoundedGraphPlan result = planBoundedGraph(
      graph,
      rootDirect,
      rootRanks,
      MODULE_COUNT,
      order,
      reachable
    );
    drop(reachable);
    drop(order);
    drop(rootRanks);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }
}
