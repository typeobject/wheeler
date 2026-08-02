//! Builds closed plans for supported six-module constant graphs.

module wheeler.compiler.graphs.six.plans;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.six.structures;
import wheeler.compiler.module_headers;

classical class SixGraphPlans {
  /// Names the six-module direct-star plan.
  public const long SIX_PLAN_DIRECT = 1;
  /// Names the six-module full-chain plan.
  public const long SIX_PLAN_CHAIN = 2;
  /// Names the six-module five-leaf-fork plan.
  public const long SIX_PLAN_FORK = 3;
  /// Names one chain edge beside four direct root imports.
  public const long SIX_PLAN_CHAIN_AND_DIRECTS = 4;
  /// Names one two-leaf fork beside three direct root imports.
  public const long SIX_PLAN_FORK_AND_DIRECTS = 5;
  /// Names two independent chains beside two direct root imports.
  public const long SIX_PLAN_PAIRS_AND_DIRECTS = 6;
  /// Names one three-module chain beside three direct root imports.
  public const long SIX_PLAN_LONG_CHAIN_AND_DIRECTS = 7;
  /// Names one four-module chain beside two direct root imports.
  public const long SIX_PLAN_DEEP_CHAIN_AND_DIRECTS = 8;
  /// Names one three-leaf fork beside two direct root imports.
  public const long SIX_PLAN_THREE_LEAF_FORK_AND_DIRECTS = 9;
  /// Names one nested two-leaf fork beside two direct root imports.
  public const long SIX_PLAN_NESTED_FORK_AND_DIRECTS = 10;
  /// Names one uneven two-branch tree beside two direct root imports.
  public const long SIX_PLAN_UNEVEN_TREE_AND_DIRECTS = 11;
  /// Names one fork beside one chain and one direct root import.
  public const long SIX_PLAN_FORK_CHAIN_AND_DIRECT = 12;
  /// Names three independent chains imported directly by the root.
  public const long SIX_PLAN_THREE_CHAINS = 13;
  /// Names one long chain beside one short chain and one direct root import.
  public const long SIX_PLAN_LONG_AND_SHORT_CHAINS = 14;
  /// Bounds the contiguous root-branch plan range without naming another plan.
  public const long SIX_ROOT_BRANCH_PLAN_LIMIT = 15;

  private const long MODULE_COUNT = 6;
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;
  private const long FOUR_IMPORTS = 4;
  private const long FIVE_IMPORTS = 5;
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

  private SixGraphPlan orderedPlan(long topology, SixGraphStructure structure) {
    return new SixGraphPlan(
      topology,
      structure.first,
      structure.second,
      structure.third,
      structure.fourth,
      structure.fifth,
      structure.sixth,
      true
    );
  }

  private long publicTopology(long structure) {
    if (structure == SIX_STRUCTURE_DIRECT) {
      return SIX_PLAN_DIRECT;
    }

    if (structure == SIX_STRUCTURE_CHAIN) {
      return SIX_PLAN_CHAIN;
    }

    if (structure == SIX_STRUCTURE_FORK) {
      return SIX_PLAN_FORK;
    }

    if (structure == SIX_STRUCTURE_CHAIN_AND_DIRECTS) {
      return SIX_PLAN_CHAIN_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_FORK_AND_DIRECTS) {
      return SIX_PLAN_FORK_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_PAIRS_AND_DIRECTS) {
      return SIX_PLAN_PAIRS_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_LONG_CHAIN_AND_DIRECTS) {
      return SIX_PLAN_LONG_CHAIN_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_DEEP_CHAIN_AND_DIRECTS) {
      return SIX_PLAN_DEEP_CHAIN_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_THREE_LEAF_FORK_AND_DIRECTS) {
      return SIX_PLAN_THREE_LEAF_FORK_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_NESTED_FORK_AND_DIRECTS) {
      return SIX_PLAN_NESTED_FORK_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_UNEVEN_TREE_AND_DIRECTS) {
      return SIX_PLAN_UNEVEN_TREE_AND_DIRECTS;
    }

    if (structure == SIX_STRUCTURE_FORK_CHAIN_AND_DIRECT) {
      return SIX_PLAN_FORK_CHAIN_AND_DIRECT;
    }

    if (structure == SIX_STRUCTURE_THREE_CHAINS) {
      return SIX_PLAN_THREE_CHAINS;
    }

    if (structure == SIX_STRUCTURE_LONG_AND_SHORT_CHAINS) {
      return SIX_PLAN_LONG_AND_SHORT_CHAINS;
    }

    return 0;
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

    if (dependency.importCount == FIVE_IMPORTS) {
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
    borrow utf8 sixthSource
  ) {
    recordEdge(graph, 0, 1, graphEdge(firstSource, secondSource));
    recordEdge(graph, 0, 2, graphEdge(firstSource, thirdSource));
    recordEdge(graph, 0, 3, graphEdge(firstSource, fourthSource));
    recordEdge(graph, 0, 4, graphEdge(firstSource, fifthSource));
    recordEdge(graph, 0, 5, graphEdge(firstSource, sixthSource));
    recordEdge(graph, 1, 0, graphEdge(secondSource, firstSource));
    recordEdge(graph, 1, 2, graphEdge(secondSource, thirdSource));
    recordEdge(graph, 1, 3, graphEdge(secondSource, fourthSource));
    recordEdge(graph, 1, 4, graphEdge(secondSource, fifthSource));
    recordEdge(graph, 1, 5, graphEdge(secondSource, sixthSource));
    recordEdge(graph, 2, 0, graphEdge(thirdSource, firstSource));
    recordEdge(graph, 2, 1, graphEdge(thirdSource, secondSource));
    recordEdge(graph, 2, 3, graphEdge(thirdSource, fourthSource));
    recordEdge(graph, 2, 4, graphEdge(thirdSource, fifthSource));
    recordEdge(graph, 2, 5, graphEdge(thirdSource, sixthSource));
    recordEdge(graph, 3, 0, graphEdge(fourthSource, firstSource));
    recordEdge(graph, 3, 1, graphEdge(fourthSource, secondSource));
    recordEdge(graph, 3, 2, graphEdge(fourthSource, thirdSource));
    recordEdge(graph, 3, 4, graphEdge(fourthSource, fifthSource));
    recordEdge(graph, 3, 5, graphEdge(fourthSource, sixthSource));
    recordEdge(graph, 4, 0, graphEdge(fifthSource, firstSource));
    recordEdge(graph, 4, 1, graphEdge(fifthSource, secondSource));
    recordEdge(graph, 4, 2, graphEdge(fifthSource, thirdSource));
    recordEdge(graph, 4, 3, graphEdge(fifthSource, fourthSource));
    recordEdge(graph, 4, 5, graphEdge(fifthSource, sixthSource));
    recordEdge(graph, 5, 0, graphEdge(sixthSource, firstSource));
    recordEdge(graph, 5, 1, graphEdge(sixthSource, secondSource));
    recordEdge(graph, 5, 2, graphEdge(sixthSource, thirdSource));
    recordEdge(graph, 5, 3, graphEdge(sixthSource, fourthSource));
    recordEdge(graph, 5, 4, graphEdge(sixthSource, fifthSource));
  }

  private void recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
    }
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
    region arena = new region(/* bytes= */ 432, /* allocations= */ 4);
    words graph = allocate(arena, 36);
    words rootDirect = allocate(arena, MODULE_COUNT);
    words order = allocate(arena, MODULE_COUNT);
    words reachable = allocate(arena, MODULE_COUNT);
    recordDirectedEdges(
      graph,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource
    );
    recordRoot(rootDirect, 0, rootEdge(firstSource, rootSource));
    recordRoot(rootDirect, 1, rootEdge(secondSource, rootSource));
    recordRoot(rootDirect, 2, rootEdge(thirdSource, rootSource));
    recordRoot(rootDirect, 3, rootEdge(fourthSource, rootSource));
    recordRoot(rootDirect, 4, rootEdge(fifthSource, rootSource));
    recordRoot(rootDirect, 5, rootEdge(sixthSource, rootSource));
    BoundedGraphPlan graphPlan = planBoundedGraph(
      graph,
      rootDirect,
      MODULE_COUNT,
      order,
      reachable
    );
    SixGraphPlan result = invalidPlan();
    if (graphPlan.valid) {
      SixGraphStructure structure = selectSixGraphStructure(
        graph,
        rootDirect,
        graphPlan.edgeCount,
        graphPlan.rootCount,
        order
      );
      if (structure.valid) {
        long topology = publicTopology(structure.topology);
        if (0 < topology) {
          result = orderedPlan(topology, structure);
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
}
