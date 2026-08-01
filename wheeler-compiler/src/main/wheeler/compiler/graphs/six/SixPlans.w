//! Builds closed plans for supported six-module constant graphs.

module wheeler.compiler.graphs.six.plans;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class SixGraphPlans {
  /// Names the six-module direct-star plan.
  public const long SIX_PLAN_DIRECT = 1;
  /// Names the six-module full-chain plan.
  public const long SIX_PLAN_CHAIN = 2;
  /// Names the six-module five-leaf-fork plan.
  public const long SIX_PLAN_FORK = 3;

  private const long MODULE_COUNT = 6;
  private const long SINGLE_IMPORT = 1;
  private const long FIVE_EDGES = 5;
  private const long SIX_IMPORTS = 6;

  /// Carries one validated topology and its leaf-to-root source order.
  public record SixGraphPlan(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    long sixth,
    boolean valid
  ) {}

  private SixGraphPlan invalidPlan() {
    return new SixGraphPlan(0, 0, 0, 0, 0, 0, 0, false);
  }

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importCount == SINGLE_IMPORT) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FIVE_EDGES) {
      return dependency.importsCandidate;
    }

    return false;
  }

  private boolean rootEdge(borrow utf8 source, borrow utf8 rootSource) {
    HeaderDependency dependency = moduleDependency(source, rootSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importCount == SINGLE_IMPORT) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == SIX_IMPORTS) {
      return dependency.importsCandidate;
    }

    return false;
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
    borrow utf8 fifthSource,
    borrow utf8 sixthSource
  ) {
    long count = 0;
    count += recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    count += recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    count += recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    count += recordEdge(graph, 0, 4, graphEdge(firstSource, fifthSource));
    count += recordEdge(graph, 0, 5, graphEdge(firstSource, sixthSource));
    count += recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    count += recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    count += recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    count += recordEdge(graph, 1, 4, graphEdge(secondSource, fifthSource));
    count += recordEdge(graph, 1, 5, graphEdge(secondSource, sixthSource));
    count += recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    count += recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    count += recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    count += recordEdge(graph, 2, 4, graphEdge(thirdSource, fifthSource));
    count += recordEdge(graph, 2, 5, graphEdge(thirdSource, sixthSource));
    count += recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    count += recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    count += recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
    count += recordEdge(graph, 3, 4, graphEdge(fourthSource, fifthSource));
    count += recordEdge(graph, 3, 5, graphEdge(fourthSource, sixthSource));
    count += recordEdge(graph, 4, 0, graphEdge(fifthSource, firstSource));
    count += recordEdge(graph, 4, 1, graphEdge(fifthSource, secondSource));
    count += recordEdge(graph, 4, 2, graphEdge(fifthSource, thirdSource));
    count += recordEdge(graph, 4, 3, graphEdge(fifthSource, fourthSource));
    count += recordEdge(graph, 4, 5, graphEdge(fifthSource, sixthSource));
    count += recordEdge(graph, 5, 0, graphEdge(sixthSource, firstSource));
    count += recordEdge(graph, 5, 1, graphEdge(sixthSource, secondSource));
    count += recordEdge(graph, 5, 2, graphEdge(sixthSource, thirdSource));
    count += recordEdge(graph, 5, 3, graphEdge(sixthSource, fourthSource));
    count += recordEdge(graph, 5, 4, graphEdge(sixthSource, fifthSource));
    return count;
  }

  private long recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  private SixGraphPlan structuredGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 432, /* allocations= */ 4);
    words graph = allocate(arena, 36);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
    words reachable = allocate(arena, MODULE_COUNT);
    long edgeCount = recordDirectedEdges(
      graph,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource
    );
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, rootEdge(firstSource, rootSource));
    rootCount += recordRoot(rootDirect, 1, rootEdge(secondSource, rootSource));
    rootCount += recordRoot(rootDirect, 2, rootEdge(thirdSource, rootSource));
    rootCount += recordRoot(rootDirect, 3, rootEdge(fourthSource, rootSource));
    rootCount += recordRoot(rootDirect, 4, rootEdge(fifthSource, rootSource));
    rootCount += recordRoot(rootDirect, 5, rootEdge(sixthSource, rootSource));
    boolean direct = false;
    if (edgeCount == 0) {
      direct = rootCount == SIX_IMPORTS;
    }

    boolean structured = false;
    if (edgeCount == FIVE_EDGES) {
      structured = rootCount == SINGLE_IMPORT;
    }

    boolean valid = direct;
    if (structured) {
      valid = true;
    }

    if (valid) {
      BoundedGraphPlan graphPlan = planBoundedGraph(
        graph,
        rootDirect,
        MODULE_COUNT,
        order,
        reachable
      );
      valid = graphPlan.valid;
    }

    SixGraphPlan result = invalidPlan();
    if (valid) {
      if (direct) {
        result = new SixGraphPlan(
          SIX_PLAN_DIRECT,
          order[0],
          order[1],
          order[2],
          order[3],
          order[4],
          order[5],
          true
        );
      } else {
        boolean chain = writeChainOrder(graph, rootDirect, MODULE_COUNT, order);
        if (chain) {
          result = new SixGraphPlan(
            SIX_PLAN_CHAIN,
            order[0],
            order[1],
            order[2],
            order[3],
            order[4],
            order[5],
            true
          );
        } else {
          boolean fork = writeForkOrder(graph, rootDirect, MODULE_COUNT, order);
          if (fork) {
            result = new SixGraphPlan(
              SIX_PLAN_FORK,
              order[0],
              order[1],
              order[2],
              order[3],
              order[4],
              order[5],
              true
            );
          }
        }
      }
    }

    drop(reachable);
    drop(order);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }

  /// Selects one supported six-module topology independent of source order.
  public SixGraphPlan planSixConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource
  ) {
    return structuredGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
  }
}
