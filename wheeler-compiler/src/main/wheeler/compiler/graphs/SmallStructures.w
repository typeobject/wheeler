//! Builds complete bounded plans for two- and three-module graphs.

module wheeler.compiler.graphs.small_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class SmallGraphStructures {
  private const long TWO_MODULES = 2;
  private const long THREE_MODULES = 3;
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource, long moduleCount) {
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

    if (moduleCount == THREE_MODULES) {
      return dependency.importCount == TWO_IMPORTS;
    }

    return false;
  }

  private long rootRank(borrow utf8 source, borrow utf8 rootSource, long moduleCount) {
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

    if (moduleCount == THREE_MODULES) {
      if (dependency.importCount == THREE_IMPORTS) {
        return dependency.candidateImportRank;
      }
    }

    return -1;
  }

  private void recordEdge(
    borrow mut words graph,
    long moduleCount,
    long source,
    long dependent,
    boolean present
  ) {
    if (present) {
      set(graph, source * moduleCount + dependent, 1);
    }
  }

  private void recordRoot(borrow mut words rootDirect, long source, long rank) {
    if (0 < rank + 1) {
      set(rootDirect, source, 1);
    }
  }

  /// Produces every rooted acyclic two-module plan admitted by the matrix bound.
  public BoundedGraphPlan planTwoGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 96, /* allocations= */ 5);
    words graph = allocate(arena, 4);
    words rootDirect = allocate(arena, TWO_MODULES);
    words rootRanks = allocate(arena, TWO_MODULES);
    words order = allocate(arena, TWO_MODULES);
    words reachable = allocate(arena, TWO_MODULES);
    recordEdge(graph, TWO_MODULES, 0, 1, graphEdge(firstSource, secondSource, TWO_MODULES));
    recordEdge(graph, TWO_MODULES, 1, 0, graphEdge(secondSource, firstSource, TWO_MODULES));
    long firstRank = rootRank(firstSource, rootSource, TWO_MODULES);
    long secondRank = rootRank(secondSource, rootSource, TWO_MODULES);
    set(rootRanks, 0, firstRank);
    set(rootRanks, 1, secondRank);
    recordRoot(rootDirect, 0, firstRank);
    recordRoot(rootDirect, 1, secondRank);
    BoundedGraphPlan result = planBoundedGraph(
      graph,
      rootDirect,
      rootRanks,
      TWO_MODULES,
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

  private void recordThreeEdges(
    borrow mut words graph,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource
  ) {
    recordEdge(
      graph,
      THREE_MODULES,
      0,
      1,
      graphEdge(firstSource, secondSource, THREE_MODULES)
    );
    recordEdge(
      graph,
      THREE_MODULES,
      0,
      2,
      graphEdge(firstSource, thirdSource, THREE_MODULES)
    );
    recordEdge(
      graph,
      THREE_MODULES,
      1,
      0,
      graphEdge(secondSource, firstSource, THREE_MODULES)
    );
    recordEdge(
      graph,
      THREE_MODULES,
      1,
      2,
      graphEdge(secondSource, thirdSource, THREE_MODULES)
    );
    recordEdge(
      graph,
      THREE_MODULES,
      2,
      0,
      graphEdge(thirdSource, firstSource, THREE_MODULES)
    );
    recordEdge(
      graph,
      THREE_MODULES,
      2,
      1,
      graphEdge(thirdSource, secondSource, THREE_MODULES)
    );
  }

  /// Produces every rooted acyclic three-module plan admitted by the matrix bound.
  public BoundedGraphPlan planThreeGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 168, /* allocations= */ 5);
    words graph = allocate(arena, 9);
    words rootDirect = allocate(arena, THREE_MODULES);
    words rootRanks = allocate(arena, THREE_MODULES);
    words order = allocate(arena, THREE_MODULES);
    words reachable = allocate(arena, THREE_MODULES);
    recordThreeEdges(graph, firstSource, secondSource, thirdSource);
    long firstRank = rootRank(firstSource, rootSource, THREE_MODULES);
    long secondRank = rootRank(secondSource, rootSource, THREE_MODULES);
    long thirdRank = rootRank(thirdSource, rootSource, THREE_MODULES);
    set(rootRanks, 0, firstRank);
    set(rootRanks, 1, secondRank);
    set(rootRanks, 2, thirdRank);
    recordRoot(rootDirect, 0, firstRank);
    recordRoot(rootDirect, 1, secondRank);
    recordRoot(rootDirect, 2, thirdRank);
    BoundedGraphPlan result = planBoundedGraph(
      graph,
      rootDirect,
      rootRanks,
      THREE_MODULES,
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
