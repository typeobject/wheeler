//! Builds exact chain and fork orders for five-module constant graphs.

module wheeler.compiler.graphs.five_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class FiveGraphStructures {
  /// Names one exact five-module chain structure.
  public const long FIVE_STRUCTURE_CHAIN = 1;
  /// Names one exact five-module four-leaf fork structure.
  public const long FIVE_STRUCTURE_FORK = 2;

  private const long MODULE_COUNT = 5;
  private const long SINGLE_IMPORT = 1;
  private const long FOUR_EDGES = 4;

  /// Carries one exact topology and its leaf-to-root source order.
  public record FiveGraphStructure(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    boolean valid
  ) {}

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importCount == SINGLE_IMPORT) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FOUR_EDGES) {
      return dependency.importsCandidate;
    }

    return false;
  }

  private boolean rootEdge(borrow utf8 source, borrow utf8 rootSource) {
    HeaderDependency dependency = moduleDependency(source, rootSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importCount == SINGLE_IMPORT) {} else {
      return false;
    }

    return dependency.importsCandidate;
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
    borrow utf8 fourthSource,
    borrow utf8 fifthSource
  ) {
    long count = 0;
    count += recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    count += recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    count += recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    count += recordEdge(graph, 0, 4, graphEdge(firstSource, fifthSource));
    count += recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    count += recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    count += recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    count += recordEdge(graph, 1, 4, graphEdge(secondSource, fifthSource));
    count += recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    count += recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    count += recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    count += recordEdge(graph, 2, 4, graphEdge(thirdSource, fifthSource));
    count += recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    count += recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    count += recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
    count += recordEdge(graph, 3, 4, graphEdge(fourthSource, fifthSource));
    count += recordEdge(graph, 4, 0, graphEdge(fifthSource, firstSource));
    count += recordEdge(graph, 4, 1, graphEdge(fifthSource, secondSource));
    count += recordEdge(graph, 4, 2, graphEdge(fifthSource, thirdSource));
    count += recordEdge(graph, 4, 3, graphEdge(fifthSource, fourthSource));
    return count;
  }

  private long recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  /// Selects one exact five-module chain or fork before source rewriting.
  public FiveGraphStructure planFiveStructure(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 280, /* allocations= */ 3);
    words graph = allocate(arena, 25);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
    long edgeCount = recordDirectedEdges(
      graph,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource
    );
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, rootEdge(firstSource, rootSource));
    rootCount += recordRoot(rootDirect, 1, rootEdge(secondSource, rootSource));
    rootCount += recordRoot(rootDirect, 2, rootEdge(thirdSource, rootSource));
    rootCount += recordRoot(rootDirect, 3, rootEdge(fourthSource, rootSource));
    rootCount += recordRoot(rootDirect, 4, rootEdge(fifthSource, rootSource));
    boolean valid = edgeCount == FOUR_EDGES;
    if (valid) {
      valid = rootCount == SINGLE_IMPORT;
    }

    FiveGraphStructure result = new FiveGraphStructure(0, 0, 0, 0, 0, 0, false);
    if (valid) {
      boolean chain = writeChainOrder(graph, rootDirect, MODULE_COUNT, order);
      if (chain) {
        result = new FiveGraphStructure(
          FIVE_STRUCTURE_CHAIN,
          order[0],
          order[1],
          order[2],
          order[3],
          order[4],
          true
        );
      } else {
        boolean fork = writeForkOrder(graph, rootDirect, MODULE_COUNT, order);
        if (fork) {
          result = new FiveGraphStructure(
            FIVE_STRUCTURE_FORK,
            order[0],
            order[1],
            order[2],
            order[3],
            order[4],
            true
          );
        }
      }
    }

    drop(order);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }
}
