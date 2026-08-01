//! Builds exact rooted plans for four-module constant graphs.

module wheeler.compiler.graphs.four_structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.module_headers;

classical class FourGraphStructures {
  /// Names four direct root imports.
  public const long FOUR_STRUCTURE_DIRECT = 1;
  /// Names one four-module full chain.
  public const long FOUR_STRUCTURE_CHAIN = 2;
  /// Names one three-leaf fork.
  public const long FOUR_STRUCTURE_FORK = 3;
  /// Names one two-leaf fork below a parent.
  public const long FOUR_STRUCTURE_FORK_THEN_PARENT = 4;
  /// Names one fork with an intermediate module on one arm.
  public const long FOUR_STRUCTURE_UNEVEN_FORK = 5;
  /// Names one two-leaf fork beside a direct import.
  public const long FOUR_STRUCTURE_FORK_AND_DIRECT = 6;
  /// Names two independent chain edges.
  public const long FOUR_STRUCTURE_TWO_CHAINS = 7;
  /// Names one three-module chain beside a direct import.
  public const long FOUR_STRUCTURE_CHAIN_AND_DIRECT = 8;
  /// Names one chain edge beside two direct imports.
  public const long FOUR_STRUCTURE_CHAIN_AND_DIRECTS = 9;
  /// Names one shared-dependency diamond.
  public const long FOUR_STRUCTURE_SHARED_DIAMOND = 10;

  private const long MODULE_COUNT = 4;
  private const long SINGLE_IMPORT = 1;
  private const long THREE_IMPORTS = 3;

  /// Carries one exact topology and its deterministic leaf-first source order.
  public record FourGraphStructure(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
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

    if (dependency.importCount < THREE_IMPORTS + 1) {} else {
      return false;
    }

    return dependency.importsCandidate;
  }

  private boolean rootEdge(borrow utf8 source, borrow utf8 rootSource) {
    HeaderDependency dependency = moduleDependency(source, rootSource);
    if (dependency.valid) {} else {
      return false;
    }

    if (0 < dependency.importCount) {} else {
      return false;
    }

    if (dependency.importCount < MODULE_COUNT + 1) {} else {
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

  private long rootIncoming(borrow mut words graph, borrow mut words rootDirect) {
    long count = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        count += incomingCount(graph, node);
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

  private long topology(
    borrow mut words graph,
    borrow mut words rootDirect,
    long edgeCount,
    long rootCount,
    long longest
  ) {
    long maximumIncoming = maximumIncoming(graph);
    long maximumOutgoing = maximumOutgoing(graph);
    if (edgeCount == 0) {
      if (rootCount == MODULE_COUNT) {
        return FOUR_STRUCTURE_DIRECT;
      }
    }

    if (edgeCount == 1) {
      if (rootCount == THREE_IMPORTS) {
        return FOUR_STRUCTURE_CHAIN_AND_DIRECTS;
      }
    }

    if (edgeCount == 2) {
      if (rootCount == 2) {
        if (maximumIncoming == 2) {
          return FOUR_STRUCTURE_FORK_AND_DIRECT;
        }

        if (maximumIncoming == 1) {
          if (maximumOutgoing == 1) {
            if (longest == 2) {
              return FOUR_STRUCTURE_CHAIN_AND_DIRECT;
            }

            if (longest == 1) {
              return FOUR_STRUCTURE_TWO_CHAINS;
            }
          }
        }
      }
    }

    if (edgeCount == 3) {
      if (rootCount == SINGLE_IMPORT) {
        if (maximumIncoming == THREE_IMPORTS) {
          if (longest == 1) {
            return FOUR_STRUCTURE_FORK;
          }
        }

        if (maximumIncoming == 2) {
          if (longest == 2) {
            if (rootIncoming(graph, rootDirect) == 1) {
              return FOUR_STRUCTURE_FORK_THEN_PARENT;
            }

            if (rootIncoming(graph, rootDirect) == 2) {
              return FOUR_STRUCTURE_UNEVEN_FORK;
            }
          }
        }

        if (maximumIncoming == 1) {
          if (maximumOutgoing == 1) {
            if (longest == THREE_IMPORTS) {
              return FOUR_STRUCTURE_CHAIN;
            }
          }
        }
      }
    }

    if (edgeCount == MODULE_COUNT) {
      if (rootCount == SINGLE_IMPORT) {
        if (maximumIncoming == 2) {
          if (maximumOutgoing == 2) {
            if (incomingDegreeCount(graph, 2) == 1) {
              if (outgoingDegreeCount(graph, 2) == 1) {
                if (longest == 2) {
                  return FOUR_STRUCTURE_SHARED_DIAMOND;
                }
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

  private FourGraphStructure orderUnevenFork(borrow mut words graph, borrow mut words rootDirect) {
    long dependent = rootWithIncoming(graph, rootDirect, 2);
    long middle = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 0) {
        if (incomingCount(graph, node) == 1) {
          if (outgoingCount(graph, node) == 1) {
            middle = node;
          }
        }
      }

      node += 1;
    }

    long leaf = sourceOf(graph, middle);
    long otherLeaf = -1;
    node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[node * MODULE_COUNT + dependent] == 1) {
        if (node == middle) {} else {
          otherLeaf = node;
        }
      }

      node += 1;
    }

    return new FourGraphStructure(
      FOUR_STRUCTURE_UNEVEN_FORK,
      leaf,
      middle,
      otherLeaf,
      dependent,
      true
    );
  }

  private FourGraphStructure orderForkAndDirect(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 2);
    long firstLeaf = -1;
    long secondLeaf = -1;
    long direct = -1;
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
          direct = node;
        }
      }

      node += 1;
    }

    return new FourGraphStructure(
      FOUR_STRUCTURE_FORK_AND_DIRECT,
      firstLeaf,
      secondLeaf,
      dependent,
      direct,
      true
    );
  }

  private FourGraphStructure orderTwoChains(borrow mut words graph, borrow mut words rootDirect) {
    long firstDependent = -1;
    long secondDependent = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[node] == 1) {
        if (firstDependent < 0) {
          firstDependent = node;
        } else {
          secondDependent = node;
        }
      }

      node += 1;
    }

    long firstLeaf = sourceOf(graph, firstDependent);
    long secondLeaf = sourceOf(graph, secondDependent);
    return new FourGraphStructure(
      FOUR_STRUCTURE_TWO_CHAINS,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      true
    );
  }

  private FourGraphStructure orderChainAndDirect(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 1);
    long middle = sourceOf(graph, dependent);
    long leaf = sourceOf(graph, middle);
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

    return new FourGraphStructure(
      FOUR_STRUCTURE_CHAIN_AND_DIRECT,
      leaf,
      middle,
      dependent,
      direct,
      true
    );
  }

  private FourGraphStructure orderChainAndDirects(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = rootWithIncoming(graph, rootDirect, 1);
    long leaf = sourceOf(graph, dependent);
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

    return new FourGraphStructure(
      FOUR_STRUCTURE_CHAIN_AND_DIRECTS,
      leaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private FourGraphStructure orderSharedDiamond(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long leaf = -1;
    long join = rootWithIncoming(graph, rootDirect, 2);
    long firstDependent = -1;
    long secondDependent = -1;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (outgoingCount(graph, node) == 2) {
        leaf = node;
      }

      if (graph[node * MODULE_COUNT + join] == 1) {
        if (firstDependent < 0) {
          firstDependent = node;
        } else {
          secondDependent = node;
        }
      }

      node += 1;
    }

    return new FourGraphStructure(
      FOUR_STRUCTURE_SHARED_DIAMOND,
      leaf,
      firstDependent,
      secondDependent,
      join,
      true
    );
  }

  private FourGraphStructure executionOrder(
    long selected,
    borrow mut words graph,
    borrow mut words rootDirect,
    borrow mut words order
  ) {
    if (selected == FOUR_STRUCTURE_UNEVEN_FORK) {
      return orderUnevenFork(graph, rootDirect);
    }

    if (selected == FOUR_STRUCTURE_FORK_AND_DIRECT) {
      return orderForkAndDirect(graph, rootDirect);
    }

    if (selected == FOUR_STRUCTURE_TWO_CHAINS) {
      return orderTwoChains(graph, rootDirect);
    }

    if (selected == FOUR_STRUCTURE_CHAIN_AND_DIRECT) {
      return orderChainAndDirect(graph, rootDirect);
    }

    if (selected == FOUR_STRUCTURE_CHAIN_AND_DIRECTS) {
      return orderChainAndDirects(graph, rootDirect);
    }

    if (selected == FOUR_STRUCTURE_SHARED_DIAMOND) {
      return orderSharedDiamond(graph, rootDirect);
    }

    return new FourGraphStructure(selected, order[0], order[1], order[2], order[3], true);
  }

  /// Selects one exact rooted four-module topology before source rewriting.
  public FourGraphStructure planFourStructure(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource
  ) {
    region arena = new region(/* bytes= */ 256, /* allocations= */ 5);
    words graph = allocate(arena, 16);
    words rootDirect = allocate(arena, MODULE_COUNT);
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
    long rootCount = 0;
    rootCount += recordRoot(rootDirect, 0, rootEdge(firstSource, rootSource));
    rootCount += recordRoot(rootDirect, 1, rootEdge(secondSource, rootSource));
    rootCount += recordRoot(rootDirect, 2, rootEdge(thirdSource, rootSource));
    rootCount += recordRoot(rootDirect, 3, rootEdge(fourthSource, rootSource));
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
        MODULE_COUNT,
        order,
        reachable
      );
      valid = graphPlan.valid;
    }

    long selected = 0;
    if (valid) {
      selected = topology(
        graph,
        rootDirect,
        edgeCount,
        rootCount,
        longestPath(graph, order, distances)
      );
      valid = 0 < selected;
    }

    FourGraphStructure result = new FourGraphStructure(0, 0, 0, 0, 0, false);
    if (valid) {
      result = executionOrder(selected, graph, rootDirect, order);
    }

    drop(distances);
    drop(reachable);
    drop(order);
    drop(rootDirect);
    drop(graph);
    drop(arena);
    return result;
  }
}
