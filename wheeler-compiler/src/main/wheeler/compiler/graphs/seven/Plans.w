//! Builds closed plans for supported seven-module constant graphs.

module wheeler.compiler.graphs.seven.plans;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;
import wheeler.compiler.module_headers;

classical class SevenGraphPlans {

  private const long MODULE_COUNT = 7;
  private const long SINGLE_EDGE = 1;
  private const long SINGLE_IMPORT = 1;
  private const long TWO_DIRECTS = 2;
  private const long TWO_EDGES = 2;
  private const long TWO_IMPORTS = 2;
  private const long THREE_EDGES = 3;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_EDGES = 4;
  private const long FOUR_IMPORTS = 4;
  private const long FIVE_EDGES = 5;
  private const long FIVE_IMPORTS = 5;
  private const long SIX_EDGES = 6;
  private const long SIX_IMPORTS = 6;
  private const long SEVEN_IMPORTS = 7;

  private SevenGraphPlan invalidPlan() {
    return new SevenGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importCount == SINGLE_IMPORT) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == TWO_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == THREE_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FOUR_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FIVE_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == SIX_IMPORTS) {
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

    if (dependency.importCount == TWO_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == THREE_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FOUR_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FIVE_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == SIX_IMPORTS) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == SEVEN_IMPORTS) {
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
    borrow utf8 sixthSource,
    borrow utf8 seventhSource
  ) {
    long count = 0;
    count += recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    count += recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    count += recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    count += recordEdge(graph, 0, 4, graphEdge(firstSource, fifthSource));
    count += recordEdge(graph, 0, 5, graphEdge(firstSource, sixthSource));
    count += recordEdge(graph, 0, 6, graphEdge(firstSource, seventhSource));
    count += recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    count += recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    count += recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    count += recordEdge(graph, 1, 4, graphEdge(secondSource, fifthSource));
    count += recordEdge(graph, 1, 5, graphEdge(secondSource, sixthSource));
    count += recordEdge(graph, 1, 6, graphEdge(secondSource, seventhSource));
    count += recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    count += recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    count += recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    count += recordEdge(graph, 2, 4, graphEdge(thirdSource, fifthSource));
    count += recordEdge(graph, 2, 5, graphEdge(thirdSource, sixthSource));
    count += recordEdge(graph, 2, 6, graphEdge(thirdSource, seventhSource));
    count += recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    count += recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    count += recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
    count += recordEdge(graph, 3, 4, graphEdge(fourthSource, fifthSource));
    count += recordEdge(graph, 3, 5, graphEdge(fourthSource, sixthSource));
    count += recordEdge(graph, 3, 6, graphEdge(fourthSource, seventhSource));
    count += recordEdge(graph, 4, 0, graphEdge(fifthSource, firstSource));
    count += recordEdge(graph, 4, 1, graphEdge(fifthSource, secondSource));
    count += recordEdge(graph, 4, 2, graphEdge(fifthSource, thirdSource));
    count += recordEdge(graph, 4, 3, graphEdge(fifthSource, fourthSource));
    count += recordEdge(graph, 4, 5, graphEdge(fifthSource, sixthSource));
    count += recordEdge(graph, 4, 6, graphEdge(fifthSource, seventhSource));
    count += recordEdge(graph, 5, 0, graphEdge(sixthSource, firstSource));
    count += recordEdge(graph, 5, 1, graphEdge(sixthSource, secondSource));
    count += recordEdge(graph, 5, 2, graphEdge(sixthSource, thirdSource));
    count += recordEdge(graph, 5, 3, graphEdge(sixthSource, fourthSource));
    count += recordEdge(graph, 5, 4, graphEdge(sixthSource, fifthSource));
    count += recordEdge(graph, 5, 6, graphEdge(sixthSource, seventhSource));
    count += recordEdge(graph, 6, 0, graphEdge(seventhSource, firstSource));
    count += recordEdge(graph, 6, 1, graphEdge(seventhSource, secondSource));
    count += recordEdge(graph, 6, 2, graphEdge(seventhSource, thirdSource));
    count += recordEdge(graph, 6, 3, graphEdge(seventhSource, fourthSource));
    count += recordEdge(graph, 6, 4, graphEdge(seventhSource, fifthSource));
    count += recordEdge(graph, 6, 5, graphEdge(seventhSource, sixthSource));
    return count;
  }

  private long recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  private SevenGraphPlan structuredGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 560, /* allocations= */ 4);
    words graph = allocate(arena, 49);
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
      sixthSource,
      seventhSource
    );
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, rootEdge(firstSource, rootSource));
    rootCount += recordRoot(rootDirect, 1, rootEdge(secondSource, rootSource));
    rootCount += recordRoot(rootDirect, 2, rootEdge(thirdSource, rootSource));
    rootCount += recordRoot(rootDirect, 3, rootEdge(fourthSource, rootSource));
    rootCount += recordRoot(rootDirect, 4, rootEdge(fifthSource, rootSource));
    rootCount += recordRoot(rootDirect, 5, rootEdge(sixthSource, rootSource));
    rootCount += recordRoot(rootDirect, 6, rootEdge(seventhSource, rootSource));
    boolean direct = false;
    if (edgeCount == 0) {
      direct = rootCount == SEVEN_IMPORTS;
    }

    boolean structured = false;
    if (edgeCount == SIX_EDGES) {
      structured = rootCount == SINGLE_IMPORT;
    }

    boolean mixedChain = false;
    if (edgeCount == SINGLE_EDGE) {
      mixedChain = rootCount == SIX_IMPORTS;
    }

    boolean mixedFork = false;
    if (edgeCount == TWO_EDGES) {
      mixedFork = rootCount == FIVE_IMPORTS;
    }

    boolean mixedThreeChains = false;
    if (edgeCount == THREE_EDGES) {
      mixedThreeChains = rootCount == FOUR_IMPORTS;
    }

    boolean mixedWideFork = false;
    if (edgeCount == FOUR_EDGES) {
      mixedWideFork = rootCount == THREE_IMPORTS;
    }

    boolean mixedFiveLeafFork = false;
    if (edgeCount == FIVE_EDGES) {
      mixedFiveLeafFork = rootCount == TWO_IMPORTS;
    }

    boolean valid = direct;
    if (structured) {
      valid = true;
    }

    if (mixedChain) {
      valid = true;
    }

    if (mixedFork) {
      valid = true;
    }

    if (mixedThreeChains) {
      valid = true;
    }

    if (mixedWideFork) {
      valid = true;
    }

    if (mixedFiveLeafFork) {
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

    SevenGraphPlan result = invalidPlan();
    if (valid) {
      if (direct) {
        result = new SevenGraphPlan(
          SEVEN_PLAN_DIRECT,
          order[0],
          order[1],
          order[2],
          order[3],
          order[4],
          order[5],
          order[6],
          true
        );
      } else {
        if (mixedChain) {
          result = chainAndDirectsPlan(graph, rootDirect);
        }

        if (mixedFork) {
          result = forkAndDirectsPlan(graph, rootDirect);
          if (result.valid) {} else {
            result = pairsAndDirectsPlan(graph, rootDirect);
          }

          if (result.valid) {} else {
            result = longChainAndDirectsPlan(graph, rootDirect);
          }
        }

        if (mixedThreeChains) {
          result = threeChainsAndDirectPlan(graph, rootDirect);
          if (result.valid) {} else {
            result = threeLeafForkAndDirectsPlan(graph, rootDirect);
          }

          if (result.valid) {} else {
            result = nestedForkAndDirectsPlan(graph, rootDirect);
          }
        }

        if (mixedWideFork) {
          result = wideForkAndDirectsPlan(graph, rootDirect);
        }

        if (mixedFiveLeafFork) {
          result = fiveLeafForkAndDirectPlan(graph, rootDirect);
        }

        boolean chain = writeChainOrder(graph, rootDirect, MODULE_COUNT, order);
        if (chain) {
          result = new SevenGraphPlan(
            SEVEN_PLAN_CHAIN,
            order[0],
            order[1],
            order[2],
            order[3],
            order[4],
            order[5],
            order[6],
            true
          );
        } else {
          boolean fork = writeForkOrder(graph, rootDirect, MODULE_COUNT, order);
          if (fork) {
            result = new SevenGraphPlan(
              SEVEN_PLAN_FORK,
              order[0],
              order[1],
              order[2],
              order[3],
              order[4],
              order[5],
              order[6],
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

  /// Selects one supported seven-module topology before source rewriting.
  public SevenGraphPlan planSevenConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource
  ) {
    return structuredGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
  }
}
