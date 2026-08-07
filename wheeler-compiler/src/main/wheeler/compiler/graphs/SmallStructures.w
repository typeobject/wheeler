//! Builds exact rooted plans for two- and three-module constant graphs.

module wheeler.compiler.graphs.small_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class SmallGraphStructures {
  /// Names a graph whose modules are all direct root imports.
  public const long SMALL_STRUCTURE_DIRECT = 1;
  /// Names one full chain.
  public const long SMALL_STRUCTURE_CHAIN = 2;
  /// Names one two-leaf fork.
  public const long SMALL_STRUCTURE_FORK = 3;
  /// Names one chain edge beside one unrelated direct import.
  public const long SMALL_STRUCTURE_CHAIN_AND_DIRECT = 4;
  private const long TWO_MODULES = 2;
  private const long THREE_MODULES = 3;
  private const long SINGLE_IMPORT = 1;

  /// Carries one exact small topology and its canonical execution order.
  public record SmallGraphStructure(
    long topology,
    long first,
    long second,
    long third,
    boolean valid
  ) {}

  private BoundedGraphPlan invalidTwoPlan() {
    return new BoundedGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  private boolean graphEdge(borrow utf8 source, borrow utf8 dependentSource, long moduleCount) {
    HeaderDependency dependency = moduleDependency(source, dependentSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (0 < dependency.importCount) {} else {
      return false;
    }

    if (dependency.importCount < moduleCount) {} else {
      return false;
    }

    return dependency.importsCandidate;
  }

  private boolean rootEdge(HeaderDependency dependency, long moduleCount) {
    if (dependency.valid) {} else {
      return false;
    }

    if (0 < dependency.importCount) {} else {
      return false;
    }

    if (dependency.importCount < moduleCount + 1) {} else {
      return false;
    }

    return dependency.importsCandidate;
  }

  private long recordEdge(
    borrow mut words graph,
    long moduleCount,
    long source,
    long dependent,
    boolean present
  ) {
    if (present) {
      set(graph, source * moduleCount + dependent, 1);
      return 1;
    }

    return 0;
  }

  private long recordRoot(borrow mut words rootDirect, long source, boolean present) {
    if (present) {
      set(rootDirect, source, 1);
      return 1;
    }

    return 0;
  }

  private long incomingCount(borrow mut words graph, long moduleCount, long node) {
    long count = 0;
    long other = 0;
    while (other < moduleCount) limit THREE_MODULES {
      count += graph[other * moduleCount + node];
      other += 1;
    }

    return count;
  }

  private long outgoingCount(borrow mut words graph, long moduleCount, long node) {
    long count = 0;
    long other = 0;
    while (other < moduleCount) limit THREE_MODULES {
      count += graph[node * moduleCount + other];
      other += 1;
    }

    return count;
  }

  private boolean rootsAreSinks(
    borrow mut words graph,
    borrow mut words rootDirect,
    long moduleCount
  ) {
    long node = 0;
    while (node < moduleCount) limit THREE_MODULES {
      if (rootDirect[node] == 1) {
        if (outgoingCount(graph, moduleCount, node) == 0) {} else {
          return false;
        }
      }

      node += 1;
    }

    return true;
  }

  /// Produces one complete canonical two-module graph plan.
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
    long edgeCount = 0;
    edgeCount += recordEdge(
      graph,
      TWO_MODULES,
      0,
      1,
      graphEdge(firstSource, secondSource, TWO_MODULES)
    );
    edgeCount += recordEdge(
      graph,
      TWO_MODULES,
      1,
      0,
      graphEdge(secondSource, firstSource, TWO_MODULES)
    );
    HeaderDependency firstRoot = moduleDependency(firstSource, rootSource);
    HeaderDependency secondRoot = moduleDependency(secondSource, rootSource);
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, rootEdge(firstRoot, TWO_MODULES));
    rootCount += recordRoot(rootDirect, 1, rootEdge(secondRoot, TWO_MODULES));
    set(rootRanks, 0, firstRoot.candidateImportRank);
    set(rootRanks, 1, secondRoot.candidateImportRank);
    boolean redundantLeaf = edgeCount == SINGLE_IMPORT;
    if (redundantLeaf) {
      redundantLeaf = rootCount == TWO_MODULES;
    }

    boolean valid = edgeCount + rootCount == TWO_MODULES;
    if (redundantLeaf) {
      valid = true;
    }

    if (valid) {
      if (redundantLeaf) {} else {
        valid = rootsAreSinks(graph, rootDirect, TWO_MODULES);
      }
    }

    BoundedGraphPlan result = invalidTwoPlan();
    if (valid) {
      result = planBoundedGraph(graph, rootDirect, rootRanks, TWO_MODULES, order, reachable);
    }

    drop(reachable);
    drop(order);
    drop(rootRanks);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }

  private long recordThreeEdges(
    borrow mut words graph,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource
  ) {
    long count = 0;
    count += recordEdge(
      graph,
      THREE_MODULES,
      0,
      1,
      graphEdge(firstSource, secondSource, THREE_MODULES)
    );
    count += recordEdge(
      graph,
      THREE_MODULES,
      0,
      2,
      graphEdge(firstSource, thirdSource, THREE_MODULES)
    );
    count += recordEdge(
      graph,
      THREE_MODULES,
      1,
      0,
      graphEdge(secondSource, firstSource, THREE_MODULES)
    );
    count += recordEdge(
      graph,
      THREE_MODULES,
      1,
      2,
      graphEdge(secondSource, thirdSource, THREE_MODULES)
    );
    count += recordEdge(
      graph,
      THREE_MODULES,
      2,
      0,
      graphEdge(thirdSource, firstSource, THREE_MODULES)
    );
    count += recordEdge(
      graph,
      THREE_MODULES,
      2,
      1,
      graphEdge(thirdSource, secondSource, THREE_MODULES)
    );
    return count;
  }

  private SmallGraphStructure orderedThree(
    borrow mut words graph,
    borrow mut words rootDirect,
    borrow mut words order,
    long edgeCount,
    long rootCount
  ) {
    if (edgeCount == 0) {
      if (rootCount == THREE_MODULES) {
        return new SmallGraphStructure(
          SMALL_STRUCTURE_DIRECT,
          order[0],
          order[1],
          order[2],
          true
        );
      }
    }

    if (edgeCount == SINGLE_IMPORT) {
      if (rootCount == TWO_MODULES) {
        long leaf = -1;
        long dependent = -1;
        long direct = -1;
        long node = 0;
        while (node < THREE_MODULES) limit THREE_MODULES {
          if (outgoingCount(graph, THREE_MODULES, node) == SINGLE_IMPORT) {
            leaf = node;
          }

          node += 1;
        }

        node = 0;
        while (node < THREE_MODULES) limit THREE_MODULES {
          if (graph[leaf * THREE_MODULES + node] == 1) {
            dependent = node;
          }

          node += 1;
        }

        node = 0;
        while (node < THREE_MODULES) limit THREE_MODULES {
          if (rootDirect[node] == 1) {
            if (node == dependent) {} else {
              direct = node;
            }
          }

          node += 1;
        }

        return new SmallGraphStructure(
          SMALL_STRUCTURE_CHAIN_AND_DIRECT,
          leaf,
          dependent,
          direct,
          true
        );
      }
    }

    if (edgeCount == TWO_MODULES) {
      if (rootCount == SINGLE_IMPORT) {
        long finalNode = order[2];
        if (incomingCount(graph, THREE_MODULES, finalNode) == TWO_MODULES) {
          return new SmallGraphStructure(
            SMALL_STRUCTURE_FORK,
            order[0],
            order[1],
            finalNode,
            true
          );
        }

        if (incomingCount(graph, THREE_MODULES, finalNode) == SINGLE_IMPORT) {
          return new SmallGraphStructure(
            SMALL_STRUCTURE_CHAIN,
            order[0],
            order[1],
            finalNode,
            true
          );
        }
      }
    }

    return new SmallGraphStructure(0, 0, 0, 0, false);
  }

  /// Selects one exact rooted three-module topology.
  public SmallGraphStructure planThreeStructure(
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
    long edgeCount = recordThreeEdges(graph, firstSource, secondSource, thirdSource);
    HeaderDependency firstRoot = moduleDependency(firstSource, rootSource);
    HeaderDependency secondRoot = moduleDependency(secondSource, rootSource);
    HeaderDependency thirdRoot = moduleDependency(thirdSource, rootSource);
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, rootEdge(firstRoot, THREE_MODULES));
    rootCount += recordRoot(rootDirect, 1, rootEdge(secondRoot, THREE_MODULES));
    rootCount += recordRoot(rootDirect, 2, rootEdge(thirdRoot, THREE_MODULES));
    set(rootRanks, 0, firstRoot.candidateImportRank);
    set(rootRanks, 1, secondRoot.candidateImportRank);
    set(rootRanks, 2, thirdRoot.candidateImportRank);
    boolean valid = edgeCount + rootCount == THREE_MODULES;
    if (valid) {
      valid = rootsAreSinks(graph, rootDirect, THREE_MODULES);
    }

    if (valid) {
      BoundedGraphPlan graphPlan = planBoundedGraph(
        graph,
        rootDirect,
        rootRanks,
        THREE_MODULES,
        order,
        reachable
      );
      valid = graphPlan.valid;
    }

    SmallGraphStructure result = new SmallGraphStructure(0, 0, 0, 0, false);
    if (valid) {
      result = orderedThree(graph, rootDirect, order, edgeCount, rootCount);
    }

    drop(reachable);
    drop(order);
    drop(rootRanks);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }
}
