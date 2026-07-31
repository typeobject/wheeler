//! Builds closed plans for supported seven-module constant graphs.

module wheeler.compiler.graphs.seven.plans;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;

classical class SevenGraphPlans {
  /// Names the seven-module direct-star plan.
  public const long SEVEN_PLAN_DIRECT = 1;
  /// Names the seven-module full-chain plan.
  public const long SEVEN_PLAN_CHAIN = 2;

  private const long MODULE_COUNT = 7;
  private const long SINGLE_IMPORT = 1;
  private const long SIX_EDGES = 6;
  private const long SEVEN_IMPORTS = 7;

  /// Carries one validated topology and its leaf-to-root source order.
  public record SevenGraphPlan(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    long sixth,
    long seventh,
    boolean valid
  ) {}

  private SevenGraphPlan invalidPlan() {
    return new SevenGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  private boolean directSource(borrow utf8 source, borrow utf8 rootSource) {
    LinkPlan plan = planConstantImport(source, rootSource, SEVEN_IMPORTS);
    return plan.valid;
  }

  private boolean allDirect(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource
  ) {
    if (directSource(firstSource, rootSource)) {} else {
      return false;
    }

    if (directSource(secondSource, rootSource)) {} else {
      return false;
    }

    if (directSource(thirdSource, rootSource)) {} else {
      return false;
    }

    if (directSource(fourthSource, rootSource)) {} else {
      return false;
    }

    if (directSource(fifthSource, rootSource)) {} else {
      return false;
    }

    if (directSource(sixthSource, rootSource)) {} else {
      return false;
    }

    return directSource(seventhSource, rootSource);
  }

  private boolean headerEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
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
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource
  ) {
    long count = 0;
    count += recordEdge(graph, 0, 1, headerEdge(firstSource, secondSource));
    count += recordEdge(graph, 0, 2, headerEdge(firstSource, thirdSource));
    count += recordEdge(graph, 0, 3, headerEdge(firstSource, fourthSource));
    count += recordEdge(graph, 0, 4, headerEdge(firstSource, fifthSource));
    count += recordEdge(graph, 0, 5, headerEdge(firstSource, sixthSource));
    count += recordEdge(graph, 0, 6, headerEdge(firstSource, seventhSource));
    count += recordEdge(graph, 1, 0, headerEdge(secondSource, firstSource));
    count += recordEdge(graph, 1, 2, headerEdge(secondSource, thirdSource));
    count += recordEdge(graph, 1, 3, headerEdge(secondSource, fourthSource));
    count += recordEdge(graph, 1, 4, headerEdge(secondSource, fifthSource));
    count += recordEdge(graph, 1, 5, headerEdge(secondSource, sixthSource));
    count += recordEdge(graph, 1, 6, headerEdge(secondSource, seventhSource));
    count += recordEdge(graph, 2, 0, headerEdge(thirdSource, firstSource));
    count += recordEdge(graph, 2, 1, headerEdge(thirdSource, secondSource));
    count += recordEdge(graph, 2, 3, headerEdge(thirdSource, fourthSource));
    count += recordEdge(graph, 2, 4, headerEdge(thirdSource, fifthSource));
    count += recordEdge(graph, 2, 5, headerEdge(thirdSource, sixthSource));
    count += recordEdge(graph, 2, 6, headerEdge(thirdSource, seventhSource));
    count += recordEdge(graph, 3, 0, headerEdge(fourthSource, firstSource));
    count += recordEdge(graph, 3, 1, headerEdge(fourthSource, secondSource));
    count += recordEdge(graph, 3, 2, headerEdge(fourthSource, thirdSource));
    count += recordEdge(graph, 3, 4, headerEdge(fourthSource, fifthSource));
    count += recordEdge(graph, 3, 5, headerEdge(fourthSource, sixthSource));
    count += recordEdge(graph, 3, 6, headerEdge(fourthSource, seventhSource));
    count += recordEdge(graph, 4, 0, headerEdge(fifthSource, firstSource));
    count += recordEdge(graph, 4, 1, headerEdge(fifthSource, secondSource));
    count += recordEdge(graph, 4, 2, headerEdge(fifthSource, thirdSource));
    count += recordEdge(graph, 4, 3, headerEdge(fifthSource, fourthSource));
    count += recordEdge(graph, 4, 5, headerEdge(fifthSource, sixthSource));
    count += recordEdge(graph, 4, 6, headerEdge(fifthSource, seventhSource));
    count += recordEdge(graph, 5, 0, headerEdge(sixthSource, firstSource));
    count += recordEdge(graph, 5, 1, headerEdge(sixthSource, secondSource));
    count += recordEdge(graph, 5, 2, headerEdge(sixthSource, thirdSource));
    count += recordEdge(graph, 5, 3, headerEdge(sixthSource, fourthSource));
    count += recordEdge(graph, 5, 4, headerEdge(sixthSource, fifthSource));
    count += recordEdge(graph, 5, 6, headerEdge(sixthSource, seventhSource));
    count += recordEdge(graph, 6, 0, headerEdge(seventhSource, firstSource));
    count += recordEdge(graph, 6, 1, headerEdge(seventhSource, secondSource));
    count += recordEdge(graph, 6, 2, headerEdge(seventhSource, thirdSource));
    count += recordEdge(graph, 6, 3, headerEdge(seventhSource, fourthSource));
    count += recordEdge(graph, 6, 4, headerEdge(seventhSource, fifthSource));
    count += recordEdge(graph, 6, 5, headerEdge(seventhSource, sixthSource));
    return count;
  }

  private long recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  private SevenGraphPlan fullChain(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 504, /* allocations= */ 3);
    words graph = allocate(arena, 49);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
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
    rootCount += recordRoot(rootDirect, 0, headerEdge(firstSource, rootSource));
    rootCount += recordRoot(rootDirect, 1, headerEdge(secondSource, rootSource));
    rootCount += recordRoot(rootDirect, 2, headerEdge(thirdSource, rootSource));
    rootCount += recordRoot(rootDirect, 3, headerEdge(fourthSource, rootSource));
    rootCount += recordRoot(rootDirect, 4, headerEdge(fifthSource, rootSource));
    rootCount += recordRoot(rootDirect, 5, headerEdge(sixthSource, rootSource));
    rootCount += recordRoot(rootDirect, 6, headerEdge(seventhSource, rootSource));
    boolean valid = edgeCount == SIX_EDGES;
    if (valid) {
      valid = rootCount == SINGLE_IMPORT;
    }

    if (valid) {
      valid = writeChainOrder(graph, rootDirect, MODULE_COUNT, order);
    }

    SevenGraphPlan result = invalidPlan();
    if (valid) {
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
    }

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
    if (
      allDirect(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        seventhSource,
        rootSource
      )
    ) {
      return new SevenGraphPlan(SEVEN_PLAN_DIRECT, 0, 1, 2, 3, 4, 5, 6, true);
    }

    return fullChain(
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
