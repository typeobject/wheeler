//! Builds complete plans for bounded four-module graphs.

module wheeler.compiler.graphs.four_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class FourGraphStructures {
  private const long MODULE_COUNT = 4;
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;

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

    return dependency.importCount == THREE_IMPORTS;
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
    borrow utf8 fourthSource
  ) {
    recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
  }

  private void recordRoot(borrow mut words rootDirect, long source, long rank) {
    if (0 < rank + 1) {
      set(rootDirect, source, 1);
    }
  }

  /// Selects every rooted acyclic four-module graph admitted by the matrix bound.
  public BoundedGraphPlan planFourGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 256, /* allocations= */ 5);
    words graph = allocate(arena, 16);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words rootRanks = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
    words reachable = allocate(arena, MODULE_COUNT);
    recordDirectedEdges(graph, firstSource, secondSource, thirdSource, fourthSource);
    long firstRank = rootRank(firstSource, rootSource);
    long secondRank = rootRank(secondSource, rootSource);
    long thirdRank = rootRank(thirdSource, rootSource);
    long fourthRank = rootRank(fourthSource, rootSource);
    set(rootRanks, 0, firstRank);
    set(rootRanks, 1, secondRank);
    set(rootRanks, 2, thirdRank);
    set(rootRanks, 3, fourthRank);
    recordRoot(rootDirect, 0, firstRank);
    recordRoot(rootDirect, 1, secondRank);
    recordRoot(rootDirect, 2, thirdRank);
    recordRoot(rootDirect, 3, fourthRank);
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
