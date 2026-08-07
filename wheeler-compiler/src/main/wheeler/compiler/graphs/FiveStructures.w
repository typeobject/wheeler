//! Builds exact rooted plans for five-module constant graphs.

module wheeler.compiler.graphs.five_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class FiveGraphStructures {
  /// Names one five-module full chain.
  public const long FIVE_STRUCTURE_CHAIN = 1;
  /// Names one five-module four-leaf fork.
  public const long FIVE_STRUCTURE_FORK = 2;
  /// Names one three-leaf fork beside a direct import.
  public const long FIVE_STRUCTURE_FORK_AND_DIRECT = 3;
  /// Names one chain edge beside three direct imports.
  public const long FIVE_STRUCTURE_CHAIN_AND_DIRECTS = 4;
  /// Names one two-leaf fork beside two direct imports.
  public const long FIVE_STRUCTURE_FORK_AND_TWO_DIRECTS = 5;
  /// Names two independent edges beside one direct import.
  public const long FIVE_STRUCTURE_PAIRS_AND_DIRECT = 6;
  /// Names one three-module chain beside two direct imports.
  public const long FIVE_STRUCTURE_LONG_CHAIN_AND_DIRECTS = 7;
  /// Names one four-module chain beside a direct import.
  public const long FIVE_STRUCTURE_DEEP_CHAIN_AND_DIRECT = 8;
  /// Names one nested fork beside a direct import.
  public const long FIVE_STRUCTURE_NESTED_FORK_AND_DIRECT = 9;
  /// Names two nested fork levels.
  public const long FIVE_STRUCTURE_NESTED_FORK = 10;
  /// Names one shared diamond with a side leaf.
  public const long FIVE_STRUCTURE_SHARED_DIAMOND = 11;
  /// Names five direct root imports.
  public const long FIVE_STRUCTURE_DIRECT = 12;

  private const long MODULE_COUNT = 5;
  private const long SINGLE_IMPORT = 1;
  private const long FOUR_IMPORTS = 4;

  /// Carries one exact topology and its deterministic leaf-first source order.
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

    if (0 < dependency.importCount) {} else {
      return false;
    }

    if (dependency.importCount < FOUR_IMPORTS + 1) {} else {
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

    if (dependency.importCount < MODULE_COUNT + 1) {} else {
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

  private long incomingCount(borrow mut words graph, long node) {
    long count = 0;
    long other = 0;
    while (other < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[other * MODULE_COUNT + node];
      other += 1;
    }

    return count;
  }

  private long outgoingCount(borrow mut words graph, long node) {
    long count = 0;
    long other = 0;
    while (other < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[node * MODULE_COUNT + other];
      other += 1;
    }

    return count;
  }

  private long maximumIncoming(borrow mut words graph) {
    long maximum = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      long count = incomingCount(graph, node);
      if (maximum < count) {
        maximum = count;
      }

      node += 1;
    }

    return maximum;
  }

  private long maximumOutgoing(borrow mut words graph) {
    long maximum = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      long count = outgoingCount(graph, node);
      if (maximum < count) {
        maximum = count;
      }

      node += 1;
    }

    return maximum;
  }

  private long incomingDegreeCount(borrow mut words graph, long degree) {
    long count = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, node) == degree) {
        count += 1;
      }

      node += 1;
    }

    return count;
  }

  private long outgoingDegreeCount(borrow mut words graph, long degree) {
    long count = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (outgoingCount(graph, node) == degree) {
        count += 1;
      }

      node += 1;
    }

    return count;
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

  private long topology(borrow mut words graph, long edgeCount, long rootCount, long longest) {
    long maximumIncoming = maximumIncoming(graph);
    long maximumOutgoing = maximumOutgoing(graph);
    if (edgeCount == 0) {
      if (rootCount == MODULE_COUNT) {
        return FIVE_STRUCTURE_DIRECT;
      }
    }

    if (edgeCount == 1) {
      if (rootCount == 4) {
        return FIVE_STRUCTURE_CHAIN_AND_DIRECTS;
      }
    }

    if (edgeCount == 2) {
      if (rootCount == 3) {
        if (maximumIncoming == 2) {
          return FIVE_STRUCTURE_FORK_AND_TWO_DIRECTS;
        }

        if (maximumIncoming == 1) {
          if (maximumOutgoing == 1) {
            if (longest == 2) {
              return FIVE_STRUCTURE_LONG_CHAIN_AND_DIRECTS;
            }

            if (longest == 1) {
              return FIVE_STRUCTURE_PAIRS_AND_DIRECT;
            }
          }
        }
      }
    }

    if (edgeCount == 3) {
      if (rootCount == 2) {
        if (maximumIncoming == 3) {
          if (longest == 1) {
            return FIVE_STRUCTURE_FORK_AND_DIRECT;
          }
        }

        if (maximumIncoming == 2) {
          if (incomingDegreeCount(graph, 2) == 1) {
            if (longest == 2) {
              return FIVE_STRUCTURE_NESTED_FORK_AND_DIRECT;
            }
          }
        }

        if (maximumIncoming == 1) {
          if (maximumOutgoing == 1) {
            if (longest == 3) {
              return FIVE_STRUCTURE_DEEP_CHAIN_AND_DIRECT;
            }
          }
        }
      }
    }

    if (edgeCount == 4) {
      if (rootCount == 1) {
        if (maximumIncoming == 4) {
          if (longest == 1) {
            return FIVE_STRUCTURE_FORK;
          }
        }

        if (maximumIncoming == 2) {
          if (incomingDegreeCount(graph, 2) == 2) {
            if (longest == 2) {
              return FIVE_STRUCTURE_NESTED_FORK;
            }
          }
        }

        if (maximumIncoming == 1) {
          if (maximumOutgoing == 1) {
            if (longest == 4) {
              return FIVE_STRUCTURE_CHAIN;
            }
          }
        }
      }
    }

    if (edgeCount == 5) {
      if (rootCount == 1) {
        if (maximumIncoming == 3) {
          if (maximumOutgoing == 2) {
            if (outgoingDegreeCount(graph, 2) == 1) {
              if (longest == 2) {
                return FIVE_STRUCTURE_SHARED_DIAMOND;
              }
            }
          }
        }
      }
    }

    return 0;
  }

  private long sourceOf(borrow mut words graph, long dependent) {
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        return source;
      }

      source += 1;
    }

    return -1;
  }

  private long rootWithIncoming(borrow mut words graph, borrow mut words rootDirect, long degree) {
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (incomingCount(graph, node) == degree) {
          return node;
        }
      }

      node += 1;
    }

    return -1;
  }

  private FiveGraphStructure orderForkAndDirect(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 3);
    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long direct = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[node * MODULE_COUNT + dependent] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = node;
        } else {
          if (secondLeaf < 0) {
            secondLeaf = node;
          } else {
            thirdLeaf = node;
          }
        }
      }

      if (rootDirect[node] == 1) {
        if (node == dependent) {} else {
          direct = node;
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_FORK_AND_DIRECT,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      dependent,
      direct,
      true
    );
  }

  private FiveGraphStructure orderChainAndDirects(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 1);
    long leaf = sourceOf(graph, dependent);
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (node == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = node;
          } else {
            if (secondDirect < 0) {
              secondDirect = node;
            } else {
              thirdDirect = node;
            }
          }
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_CHAIN_AND_DIRECTS,
      leaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  private FiveGraphStructure orderForkAndTwoDirects(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 2);
    long firstLeaf = -1;
    long secondLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[node * MODULE_COUNT + dependent] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = node;
        } else {
          secondLeaf = node;
        }
      }

      if (rootDirect[node] == 1) {
        if (node == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = node;
          } else {
            secondDirect = node;
          }
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_FORK_AND_TWO_DIRECTS,
      firstLeaf,
      secondLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private FiveGraphStructure orderPairsAndDirect(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long firstDependent = -1;
    long secondDependent = -1;
    long direct = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (incomingCount(graph, node) == 1) {
          if (firstDependent < 0) {
            firstDependent = node;
          } else {
            secondDependent = node;
          }
        } else {
          direct = node;
        }
      }

      node += 1;
    }

    long firstLeaf = sourceOf(graph, firstDependent);
    long secondLeaf = sourceOf(graph, secondDependent);
    return new FiveGraphStructure(
      FIVE_STRUCTURE_PAIRS_AND_DIRECT,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      direct,
      true
    );
  }

  private FiveGraphStructure orderLongChainAndDirects(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 1);
    long middle = sourceOf(graph, dependent);
    long leaf = sourceOf(graph, middle);
    long firstDirect = -1;
    long secondDirect = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (node == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = node;
          } else {
            secondDirect = node;
          }
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_LONG_CHAIN_AND_DIRECTS,
      leaf,
      middle,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private FiveGraphStructure orderDeepChainAndDirect(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 1);
    long third = sourceOf(graph, dependent);
    long second = sourceOf(graph, third);
    long leaf = sourceOf(graph, second);
    long direct = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (node == dependent) {} else {
          direct = node;
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_DEEP_CHAIN_AND_DIRECT,
      leaf,
      second,
      third,
      dependent,
      direct,
      true
    );
  }

  private FiveGraphStructure orderNestedForkAndDirect(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long middle = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 0) {
        if (incomingCount(graph, node) == 2) {
          middle = node;
        }
      }

      node += 1;
    }

    long dependent = -1;
    long direct = -1;
    node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (graph[middle * MODULE_COUNT + node] == 1) {
          dependent = node;
        } else {
          direct = node;
        }
      }

      node += 1;
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[node * MODULE_COUNT + middle] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = node;
        } else {
          secondLeaf = node;
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_NESTED_FORK_AND_DIRECT,
      firstLeaf,
      secondLeaf,
      middle,
      dependent,
      direct,
      true
    );
  }

  private FiveGraphStructure orderNestedFork(borrow mut words graph, borrow mut words rootDirect) {
    long dependent = rootWithIncoming(graph, rootDirect, 2);
    long middle = -1;
    long sideLeaf = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (node == dependent) {} else {
        if (incomingCount(graph, node) == 2) {
          middle = node;
        }
      }

      node += 1;
    }

    node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[node * MODULE_COUNT + dependent] == 1) {
        if (node == middle) {} else {
          sideLeaf = node;
        }
      }

      node += 1;
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[node * MODULE_COUNT + middle] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = node;
        } else {
          secondLeaf = node;
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_NESTED_FORK,
      firstLeaf,
      secondLeaf,
      middle,
      sideLeaf,
      dependent,
      true
    );
  }

  private FiveGraphStructure orderSharedDiamond(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long sharedLeaf = -1;
    long join = rootWithIncoming(graph, rootDirect, 3);
    long firstDependent = -1;
    long secondDependent = -1;
    long sideLeaf = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (outgoingCount(graph, node) == 2) {
        sharedLeaf = node;
      }

      if (graph[node * MODULE_COUNT + join] == 1) {
        if (incomingCount(graph, node) == 1) {
          if (firstDependent < 0) {
            firstDependent = node;
          } else {
            secondDependent = node;
          }
        } else {
          sideLeaf = node;
        }
      }

      node += 1;
    }

    return new FiveGraphStructure(
      FIVE_STRUCTURE_SHARED_DIAMOND,
      sharedLeaf,
      firstDependent,
      secondDependent,
      join,
      sideLeaf,
      true
    );
  }

  private FiveGraphStructure executionOrder(
    long selected,
    borrow mut words graph,
    borrow mut words rootDirect,
    borrow mut words order
  ) {
    if (selected == FIVE_STRUCTURE_FORK_AND_DIRECT) {
      return orderForkAndDirect(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_CHAIN_AND_DIRECTS) {
      return orderChainAndDirects(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_FORK_AND_TWO_DIRECTS) {
      return orderForkAndTwoDirects(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_PAIRS_AND_DIRECT) {
      return orderPairsAndDirect(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_LONG_CHAIN_AND_DIRECTS) {
      return orderLongChainAndDirects(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_DEEP_CHAIN_AND_DIRECT) {
      return orderDeepChainAndDirect(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_NESTED_FORK_AND_DIRECT) {
      return orderNestedForkAndDirect(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_NESTED_FORK) {
      return orderNestedFork(graph, rootDirect);
    }

    if (selected == FIVE_STRUCTURE_SHARED_DIAMOND) {
      return orderSharedDiamond(graph, rootDirect);
    }

    return new FiveGraphStructure(
      selected,
      order[0],
      order[1],
      order[2],
      order[3],
      order[4],
      true
    );
  }

  /// Selects one exact rooted five-module topology before source rewriting.
  public FiveGraphStructure planFiveStructure(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 400, /* allocations= */ 6);
    words graph = allocate(arena, 25);
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
      fourthSource,
      fifthSource
    );
    long firstRootRank = rootRank(firstSource, rootSource);
    long secondRootRank = rootRank(secondSource, rootSource);
    long thirdRootRank = rootRank(thirdSource, rootSource);
    long fourthRootRank = rootRank(fourthSource, rootSource);
    long fifthRootRank = rootRank(fifthSource, rootSource);
    set(rootRanks, 0, firstRootRank);
    set(rootRanks, 1, secondRootRank);
    set(rootRanks, 2, thirdRootRank);
    set(rootRanks, 3, fourthRootRank);
    set(rootRanks, 4, fifthRootRank);
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, 0 < firstRootRank + 1);
    rootCount += recordRoot(rootDirect, 1, 0 < secondRootRank + 1);
    rootCount += recordRoot(rootDirect, 2, 0 < thirdRootRank + 1);
    rootCount += recordRoot(rootDirect, 3, 0 < fourthRootRank + 1);
    rootCount += recordRoot(rootDirect, 4, 0 < fifthRootRank + 1);
    boolean valid = edgeCount + rootCount == MODULE_COUNT;
    if (edgeCount == MODULE_COUNT) {
      valid = rootCount == SINGLE_IMPORT;
    }

    if (valid) {
      valid = rootsAreSinks(graph, rootDirect);
    }

    if (valid) {
      BoundedGraphPlan graphPlan = planBoundedGraph(
        graph,
        rootDirect,
        rootRanks,
        MODULE_COUNT,
        order,
        reachable
      );
      valid = graphPlan.valid;
    }

    long selected = 0;
    if (valid) {
      selected = topology(graph, edgeCount, rootCount, longestPath(graph, order, distances));
      valid = 0 < selected;
    }

    FiveGraphStructure result = new FiveGraphStructure(0, 0, 0, 0, 0, 0, false);
    if (valid) {
      result = executionOrder(selected, graph, rootDirect, order);
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
