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
  /// Names one chain edge beside four direct root imports.
  public const long SIX_PLAN_CHAIN_AND_DIRECTS = 4;
  /// Names one two-leaf fork beside three direct root imports.
  public const long SIX_PLAN_FORK_AND_DIRECTS = 5;
  /// Names two independent chains beside two direct root imports.
  public const long SIX_PLAN_PAIRS_AND_DIRECTS = 6;

  private const long MODULE_COUNT = 6;
  private const long SINGLE_IMPORT = 1;
  private const long TWO_IMPORTS = 2;
  private const long FOUR_IMPORTS = 4;
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

    if (dependency.importCount == TWO_IMPORTS) {
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

    if (dependency.importCount == FIVE_EDGES) {
      return dependency.importsCandidate;
    }

    if (dependency.importCount == FOUR_IMPORTS) {
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

  private SixGraphPlan mixedGraphPlan(borrow mut words graph, borrow mut words rootDirect) {
    long leaf = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long fourthDirect = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      long candidate = 0;
      while (candidate < MODULE_COUNT) limit MODULE_COUNT {
        if (graph[source * MODULE_COUNT + candidate] == 1) {
          leaf = source;
          dependent = candidate;
        }

        candidate += 1;
      }

      source += 1;
    }

    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = source;
          } else {
            if (secondDirect < 0) {
              secondDirect = source;
            } else {
              if (thirdDirect < 0) {
                thirdDirect = source;
              } else {
                fourthDirect = source;
              }
            }
          }
        }
      }

      source += 1;
    }

    return new SixGraphPlan(
      SIX_PLAN_CHAIN_AND_DIRECTS,
      leaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      fourthDirect,
      true
    );
  }

  private long incomingCount(borrow mut words graph, long candidate) {
    long incoming = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      incoming += graph[source * MODULE_COUNT + candidate];
      source += 1;
    }

    return incoming;
  }

  private long outgoingCount(borrow mut words graph, long candidate) {
    long outgoing = 0;
    long dependent = 0;
    while (dependent < MODULE_COUNT) limit MODULE_COUNT {
      outgoing += graph[candidate * MODULE_COUNT + dependent];
      dependent += 1;
    }

    return outgoing;
  }

  private long maximumIncoming(borrow mut words graph) {
    long maximum = 0;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, candidate);
      if (maximum < incoming) {
        maximum = incoming;
      }

      candidate += 1;
    }

    return maximum;
  }

  private boolean hasInteriorNode(borrow mut words graph) {
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (0 < incomingCount(graph, candidate)) {
        if (0 < outgoingCount(graph, candidate)) {
          return true;
        }
      }

      candidate += 1;
    }

    return false;
  }

  private SixGraphPlan pairsAndDirectsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long firstLeaf = -1;
    long firstDependent = -1;
    long secondLeaf = -1;
    long secondDependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, candidate);
      if (incoming == 1) {
        long source = 0;
        while (source < MODULE_COUNT) limit MODULE_COUNT {
          if (graph[source * MODULE_COUNT + candidate] == 1) {
            if (firstDependent < 0) {
              firstLeaf = source;
              firstDependent = candidate;
            } else {
              secondLeaf = source;
              secondDependent = candidate;
            }
          }

          source += 1;
        }
      }

      if (rootDirect[candidate] == 1) {
        if (incoming == 0) {
          if (firstDirect < 0) {
            firstDirect = candidate;
          } else {
            secondDirect = candidate;
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphPlan(
      SIX_PLAN_PAIRS_AND_DIRECTS,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private SixGraphPlan forkAndDirectsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long dependent = -1;
    long firstLeaf = -1;
    long secondLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, candidate);
      if (incoming == 2) {
        dependent = candidate;
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[candidate * MODULE_COUNT + dependent] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = candidate;
        } else {
          secondLeaf = candidate;
        }
      }

      if (rootDirect[candidate] == 1) {
        if (candidate == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = candidate;
          } else {
            if (secondDirect < 0) {
              secondDirect = candidate;
            } else {
              thirdDirect = candidate;
            }
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphPlan(
      SIX_PLAN_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
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

    boolean mixed = false;
    if (edgeCount == SINGLE_IMPORT) {
      mixed = rootCount == FIVE_EDGES;
    }

    boolean forkAndDirects = false;
    boolean pairsAndDirects = false;
    if (edgeCount == 2) {
      if (rootCount == FOUR_IMPORTS) {
        long maximum = maximumIncoming(graph);
        forkAndDirects = maximum == 2;
        if (maximum == 1) {
          pairsAndDirects = !hasInteriorNode(graph);
        }
      }
    }

    boolean valid = direct;
    if (structured) {
      valid = true;
    }

    if (mixed) {
      valid = true;
    }

    if (forkAndDirects) {
      valid = true;
    }

    if (pairsAndDirects) {
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
      if (pairsAndDirects) {
        result = pairsAndDirectsPlan(graph, rootDirect);
      } else {
        if (forkAndDirects) {
          result = forkAndDirectsPlan(graph, rootDirect);
        } else {
          if (mixed) {
            result = mixedGraphPlan(graph, rootDirect);
          } else {
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
