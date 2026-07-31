//! Classifies supported six-module constant graphs before source rewriting.

module wheeler.compiler.graphs.six.plans;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;

classical class SixGraphPlans {
  /// Names the six-module direct-star plan.
  public const long SIX_PLAN_DIRECT = 1;
  /// Names the six-module full-chain plan.
  public const long SIX_PLAN_CHAIN = 2;
  /// Names the six-module five-leaf-fork plan.
  public const long SIX_PLAN_FORK = 3;

  private const long MODULE_COUNT = 6;
  private const long SINGLE_IMPORT = 1;
  private const long FIVE_IMPORTS = 5;
  private const long SIX_IMPORTS = 6;

  /// Carries one validated six-module topology selection.
  public record SixGraphPlan(long topology, boolean valid) {}

  private boolean directSource(
    borrow utf8 source,
    borrow utf8 rootSource,
    long expectedImportCount
  ) {
    LinkPlan plan = planConstantImport(source, rootSource, expectedImportCount);
    return plan.valid;
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

  private boolean forkEdge(borrow utf8 source, borrow utf8 dependentSource) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (dependency.importCount == FIVE_IMPORTS) {} else {
      return false;
    }

    return dependency.importsCandidate;
  }

  private boolean allDirect(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource
  ) {
    if (directSource(firstSource, rootSource, SIX_IMPORTS)) {} else {
      return false;
    }

    if (directSource(secondSource, rootSource, SIX_IMPORTS)) {} else {
      return false;
    }

    if (directSource(thirdSource, rootSource, SIX_IMPORTS)) {} else {
      return false;
    }

    if (directSource(fourthSource, rootSource, SIX_IMPORTS)) {} else {
      return false;
    }

    if (directSource(fifthSource, rootSource, SIX_IMPORTS)) {} else {
      return false;
    }

    return directSource(sixthSource, rootSource, SIX_IMPORTS);
  }

  private boolean forkWithFirstDependent(
    borrow utf8 dependentSource,
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 fourthLeafSource,
    borrow utf8 fifthLeafSource,
    borrow utf8 rootSource
  ) {
    if (headerEdge(dependentSource, rootSource)) {} else {
      return false;
    }

    if (forkEdge(firstLeafSource, dependentSource)) {} else {
      return false;
    }

    if (forkEdge(secondLeafSource, dependentSource)) {} else {
      return false;
    }

    if (forkEdge(thirdLeafSource, dependentSource)) {} else {
      return false;
    }

    if (forkEdge(fourthLeafSource, dependentSource)) {} else {
      return false;
    }

    return forkEdge(fifthLeafSource, dependentSource);
  }

  private boolean fiveLeafFork(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource
  ) {
    if (
      forkWithFirstDependent(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return true;
    }

    if (
      forkWithFirstDependent(
        secondSource,
        firstSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return true;
    }

    if (
      forkWithFirstDependent(
        thirdSource,
        firstSource,
        secondSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return true;
    }

    if (
      forkWithFirstDependent(
        fourthSource,
        firstSource,
        secondSource,
        thirdSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return true;
    }

    if (
      forkWithFirstDependent(
        fifthSource,
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        sixthSource,
        rootSource
      )
    ) {
      return true;
    }

    return forkWithFirstDependent(
      sixthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
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
    count += recordEdge(graph, 0, 1, headerEdge(firstSource, secondSource));
    count += recordEdge(graph, 0, 2, headerEdge(firstSource, thirdSource));
    count += recordEdge(graph, 0, 3, headerEdge(firstSource, fourthSource));
    count += recordEdge(graph, 0, 4, headerEdge(firstSource, fifthSource));
    count += recordEdge(graph, 0, 5, headerEdge(firstSource, sixthSource));
    count += recordEdge(graph, 1, 0, headerEdge(secondSource, firstSource));
    count += recordEdge(graph, 1, 2, headerEdge(secondSource, thirdSource));
    count += recordEdge(graph, 1, 3, headerEdge(secondSource, fourthSource));
    count += recordEdge(graph, 1, 4, headerEdge(secondSource, fifthSource));
    count += recordEdge(graph, 1, 5, headerEdge(secondSource, sixthSource));
    count += recordEdge(graph, 2, 0, headerEdge(thirdSource, firstSource));
    count += recordEdge(graph, 2, 1, headerEdge(thirdSource, secondSource));
    count += recordEdge(graph, 2, 3, headerEdge(thirdSource, fourthSource));
    count += recordEdge(graph, 2, 4, headerEdge(thirdSource, fifthSource));
    count += recordEdge(graph, 2, 5, headerEdge(thirdSource, sixthSource));
    count += recordEdge(graph, 3, 0, headerEdge(fourthSource, firstSource));
    count += recordEdge(graph, 3, 1, headerEdge(fourthSource, secondSource));
    count += recordEdge(graph, 3, 2, headerEdge(fourthSource, thirdSource));
    count += recordEdge(graph, 3, 4, headerEdge(fourthSource, fifthSource));
    count += recordEdge(graph, 3, 5, headerEdge(fourthSource, sixthSource));
    count += recordEdge(graph, 4, 0, headerEdge(fifthSource, firstSource));
    count += recordEdge(graph, 4, 1, headerEdge(fifthSource, secondSource));
    count += recordEdge(graph, 4, 2, headerEdge(fifthSource, thirdSource));
    count += recordEdge(graph, 4, 3, headerEdge(fifthSource, fourthSource));
    count += recordEdge(graph, 4, 5, headerEdge(fifthSource, sixthSource));
    count += recordEdge(graph, 5, 0, headerEdge(sixthSource, firstSource));
    count += recordEdge(graph, 5, 1, headerEdge(sixthSource, secondSource));
    count += recordEdge(graph, 5, 2, headerEdge(sixthSource, thirdSource));
    count += recordEdge(graph, 5, 3, headerEdge(sixthSource, fourthSource));
    count += recordEdge(graph, 5, 4, headerEdge(sixthSource, fifthSource));
    return count;
  }

  private long recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  private boolean fullChain(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 384, /* allocations= */ 3);
    words graph = allocate(arena, 36);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
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
    rootCount += recordRoot(rootDirect, 0, headerEdge(firstSource, rootSource));
    rootCount += recordRoot(rootDirect, 1, headerEdge(secondSource, rootSource));
    rootCount += recordRoot(rootDirect, 2, headerEdge(thirdSource, rootSource));
    rootCount += recordRoot(rootDirect, 3, headerEdge(fourthSource, rootSource));
    rootCount += recordRoot(rootDirect, 4, headerEdge(fifthSource, rootSource));
    rootCount += recordRoot(rootDirect, 5, headerEdge(sixthSource, rootSource));
    boolean valid = edgeCount == FIVE_IMPORTS;
    if (valid) {
      valid = rootCount == SINGLE_IMPORT;
    }

    if (valid) {
      valid = writeChainOrder(graph, rootDirect, MODULE_COUNT, order);
    }

    drop(order);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return valid;
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
    if (
      allDirect(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return new SixGraphPlan(SIX_PLAN_DIRECT, true);
    }

    if (
      fiveLeafFork(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return new SixGraphPlan(SIX_PLAN_FORK, true);
    }

    if (
      fullChain(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource
      )
    ) {
      return new SixGraphPlan(SIX_PLAN_CHAIN, true);
    }

    return new SixGraphPlan(0, false);
  }
}
