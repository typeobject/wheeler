//! Builds complete bounded plans for four-module constant graphs.

module wheeler.compiler.graphs.four_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class FourGraphStructures {
  private const long MODULE_COUNT = 4;
  private const long MAX_DIRECT_IMPORTS = 4;
  private const long SHARED_DIAMOND_EDGES = 4;
  private const long SHARED_DIAMOND_DEGREE = 2;
  private const long SHARED_DIAMOND_PATH = 2;

  private BoundedGraphPlan invalidPlan() {
    return new BoundedGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (0 < dependency.importCount) {} else {
      return false;
    }

    if (dependency.importCount < MAX_DIRECT_IMPORTS) {} else {
      return false;
    }

    return dependency.importsCandidate;
  }

  private long rootRank(borrow utf8 source, borrow utf8 rootSource) {
    HeaderDependency dependency = moduleDependency(source, rootSource);
    if (dependency.valid) {} else {
      return -1;
    }

    if (0 < dependency.importCount) {} else {
      return -1;
    }

    if (dependency.importCount < MAX_DIRECT_IMPORTS + 1) {} else {
      return -1;
    }

    if (dependency.importsCandidate) {
      return dependency.candidateImportRank;
    }

    return -1;
  }

  private long recordEdge(borrow mut words graph, long source, long dependent, boolean present) {
    if (present) {
      set(graph, source * MODULE_COUNT + dependent, 1);
      return 1;
    }

    return 0;
  }

  private long recordDirectedEdges(
    borrow mut words graph,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource
  ) {
    long count = 0;
    count += recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    count += recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    count += recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    count += recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    count += recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    count += recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    count += recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    count += recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    count += recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    count += recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    count += recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    count += recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
    return count;
  }

  private long recordRoot(borrow mut words rootDirect, long source, long rank) {
    if (0 < rank + 1) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  private long incomingCount(borrow mut words graph, long node) {
    long count = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[source * MODULE_COUNT + node];
      source += 1;
    }

    return count;
  }

  private long outgoingCount(borrow mut words graph, long node) {
    long count = 0;
    long dependent = 0;
    while (dependent < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[node * MODULE_COUNT + dependent];
      dependent += 1;
    }

    return count;
  }

  private boolean rootsAreSinks(borrow mut words graph, borrow mut words rootDirect) {
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (outgoingCount(graph, node) == 0) {} else {
          return false;
        }
      }

      node += 1;
    }

    return true;
  }

  private long longestPath(
    borrow mut words graph,
    borrow mut words order,
    borrow mut words distances
  ) {
    long longest = 0;
    long position = 0;
    while (position < MODULE_COUNT) limit MODULE_COUNT {
      long source = order[position];
      long dependent = 0;
      while (dependent < MODULE_COUNT) limit MODULE_COUNT {
        if (graph[source * MODULE_COUNT + dependent] == 1) {
          long distance = distances[source] + 1;
          if (distances[dependent] < distance) {
            set(distances, dependent, distance);
          }

          if (longest < distance) {
            longest = distance;
          }
        }

        dependent += 1;
      }

      position += 1;
    }

    return longest;
  }

  private boolean sharedDiamond(
    borrow mut words graph,
    borrow mut words order,
    borrow mut words distances
  ) {
    long incomingTwo = 0;
    long outgoingTwo = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, node);
      long outgoing = outgoingCount(graph, node);
      if (incoming < SHARED_DIAMOND_DEGREE + 1) {} else {
        return false;
      }

      if (outgoing < SHARED_DIAMOND_DEGREE + 1) {} else {
        return false;
      }

      if (incoming == SHARED_DIAMOND_DEGREE) {
        incomingTwo += 1;
      }

      if (outgoing == SHARED_DIAMOND_DEGREE) {
        outgoingTwo += 1;
      }

      node += 1;
    }

    if (incomingTwo == 1) {} else {
      return false;
    }

    if (outgoingTwo == 1) {} else {
      return false;
    }

    return longestPath(graph, order, distances) == SHARED_DIAMOND_PATH;
  }

  /// Produces one complete canonical four-module graph plan.
  public BoundedGraphPlan planFourGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 288, /* allocations= */ 6);
    words graph = allocate(arena, 16);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words rootRanks = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
    words reachable = allocate(arena, MODULE_COUNT);
    words distances = allocate(arena, MODULE_COUNT);
    long edgeCount = recordDirectedEdges(
      graph,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource
    );
    long firstRootRank = rootRank(firstSource, rootSource);
    long secondRootRank = rootRank(secondSource, rootSource);
    long thirdRootRank = rootRank(thirdSource, rootSource);
    long fourthRootRank = rootRank(fourthSource, rootSource);
    set(rootRanks, 0, firstRootRank);
    set(rootRanks, 1, secondRootRank);
    set(rootRanks, 2, thirdRootRank);
    set(rootRanks, 3, fourthRootRank);
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, firstRootRank);
    rootCount += recordRoot(rootDirect, 1, secondRootRank);
    rootCount += recordRoot(rootDirect, 2, thirdRootRank);
    rootCount += recordRoot(rootDirect, 3, fourthRootRank);
    boolean valid = edgeCount + rootCount == MODULE_COUNT;
    if (edgeCount == SHARED_DIAMOND_EDGES) {
      valid = rootCount == 1;
    }

    if (valid) {
      valid = rootsAreSinks(graph, rootDirect);
    }

    BoundedGraphPlan result = invalidPlan();
    if (valid) {
      result = planBoundedGraph(graph, rootDirect, rootRanks, MODULE_COUNT, order, reachable);
      valid = result.valid;
    }

    if (valid) {
      if (edgeCount == SHARED_DIAMOND_EDGES) {
        valid = sharedDiamond(graph, order, distances);
      }
    }

    if (valid) {} else {
      result = invalidPlan();
    }

    drop(distances);
    drop(reachable);
    drop(order);
    drop(rootRanks);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }
}
