//! Classifies supported six-module constant graphs from exact bounded facts.

module wheeler.compiler.graphs.six.structures;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.six_graph_kinds;

classical class SixGraphStructures {

  private const long MODULE_COUNT = 6;
  private const long SINGLE_EDGE = 1;
  private const long TWO_EDGES = 2;
  private const long THREE_EDGES = 3;
  private const long FOUR_ROOTS = 4;
  private const long FIVE_EDGES = 5;
  private const long FIVE_ROOTS = 5;
  private const long SIX_ROOTS = 6;

  /// Carries one validated structure and its leaf-to-root source order.
  public record SixGraphStructure(
    long topology,
    long first,
    long second,
    long third,
    long fourth,
    long fifth,
    long sixth,
    boolean valid
  ) {}

  /// Returns the sole canonical invalid six-module structure.
  public SixGraphStructure invalidSixGraphStructure() {
    return new SixGraphStructure(0, 0, 0, 0, 0, 0, 0, false);
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

  private long soleSource(borrow mut words graph, long dependent) {
    long found = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        found = source;
      }

      source += 1;
    }

    return found;
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

  private long maximumOutgoing(borrow mut words graph) {
    long maximum = 0;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      long outgoing = outgoingCount(graph, candidate);
      if (maximum < outgoing) {
        maximum = outgoing;
      }

      candidate += 1;
    }

    return maximum;
  }

  private long interiorNodeCount(borrow mut words graph) {
    long count = 0;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (0 < incomingCount(graph, candidate)) {
        if (0 < outgoingCount(graph, candidate)) {
          count += 1;
        }
      }

      candidate += 1;
    }

    return count;
  }

  private SixGraphStructure chainAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
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

    return new SixGraphStructure(
      SIX_STRUCTURE_CHAIN_AND_DIRECTS,
      leaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      fourthDirect,
      true
    );
  }

  private SixGraphStructure forkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long firstLeaf = -1;
    long secondLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
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

    return new SixGraphStructure(
      SIX_STRUCTURE_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  private SixGraphStructure pairsAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long firstLeaf = -1;
    long firstDependent = -1;
    long secondLeaf = -1;
    long secondDependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, candidate);
      if (incoming == SINGLE_EDGE) {
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

    return new SixGraphStructure(
      SIX_STRUCTURE_PAIRS_AND_DIRECTS,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private SixGraphStructure longChainAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long leaf = -1;
    long middle = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (0 < incomingCount(graph, candidate)) {
        if (0 < outgoingCount(graph, candidate)) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[candidate * MODULE_COUNT + middle] == 1) {
        leaf = candidate;
      }

      if (graph[middle * MODULE_COUNT + candidate] == 1) {
        dependent = candidate;
      }

      if (rootDirect[candidate] == 1) {
        if (incomingCount(graph, candidate) == 0) {
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

    return new SixGraphStructure(
      SIX_STRUCTURE_LONG_CHAIN_AND_DIRECTS,
      leaf,
      middle,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  private SixGraphStructure forkChainAndDirectPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long firstForkLeaf = -1;
    long secondForkLeaf = -1;
    long forkDependent = -1;
    long chainLeaf = -1;
    long chainDependent = -1;
    long direct = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      long incoming = incomingCount(graph, candidate);
      if (incoming == TWO_EDGES) {
        forkDependent = candidate;
      }

      if (incoming == SINGLE_EDGE) {
        if (rootDirect[candidate] == 1) {
          chainLeaf = soleSource(graph, candidate);
          chainDependent = candidate;
        }
      }

      if (incoming == 0) {
        if (rootDirect[candidate] == 1) {
          direct = candidate;
        }
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[candidate * MODULE_COUNT + forkDependent] == 1) {
        if (firstForkLeaf < 0) {
          firstForkLeaf = candidate;
        } else {
          secondForkLeaf = candidate;
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_FORK_CHAIN_AND_DIRECT,
      firstForkLeaf,
      secondForkLeaf,
      forkDependent,
      chainLeaf,
      chainDependent,
      direct,
      true
    );
  }

  private SixGraphStructure threeChainsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long firstLeaf = -1;
    long firstDependent = -1;
    long secondLeaf = -1;
    long secondDependent = -1;
    long thirdLeaf = -1;
    long thirdDependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == SINGLE_EDGE) {
        if (rootDirect[candidate] == 1) {
          if (firstDependent < 0) {
            firstLeaf = soleSource(graph, candidate);
            firstDependent = candidate;
          } else {
            if (secondDependent < 0) {
              secondLeaf = soleSource(graph, candidate);
              secondDependent = candidate;
            } else {
              thirdLeaf = soleSource(graph, candidate);
              thirdDependent = candidate;
            }
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_THREE_CHAINS,
      firstLeaf,
      firstDependent,
      secondLeaf,
      secondDependent,
      thirdLeaf,
      thirdDependent,
      true
    );
  }

  private SixGraphStructure longAndShortChainsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long longLeaf = -1;
    long middle = -1;
    long longDependent = -1;
    long shortLeaf = -1;
    long shortDependent = -1;
    long direct = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == SINGLE_EDGE) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    longLeaf = soleSource(graph, middle);
    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[middle * MODULE_COUNT + candidate] == 1) {
        longDependent = candidate;
      }

      if (rootDirect[candidate] == 1) {
        long incoming = incomingCount(graph, candidate);
        if (incoming == 0) {
          direct = candidate;
        }

        if (incoming == SINGLE_EDGE) {
          if (candidate == longDependent) {} else {
            shortLeaf = soleSource(graph, candidate);
            shortDependent = candidate;
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_LONG_AND_SHORT_CHAINS,
      longLeaf,
      middle,
      longDependent,
      shortLeaf,
      shortDependent,
      direct,
      true
    );
  }

  private SixGraphStructure unevenTreeAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long leaf = -1;
    long middle = -1;
    long secondLeaf = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == SINGLE_EDGE) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[candidate * MODULE_COUNT + middle] == 1) {
        leaf = candidate;
      }

      if (graph[middle * MODULE_COUNT + candidate] == 1) {
        dependent = candidate;
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[candidate * MODULE_COUNT + dependent] == 1) {
        if (candidate == middle) {} else {
          secondLeaf = candidate;
        }
      }

      if (rootDirect[candidate] == 1) {
        if (incomingCount(graph, candidate) == 0) {
          if (firstDirect < 0) {
            firstDirect = candidate;
          } else {
            secondDirect = candidate;
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_UNEVEN_TREE_AND_DIRECTS,
      leaf,
      middle,
      secondLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private SixGraphStructure nestedForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long firstLeaf = -1;
    long secondLeaf = -1;
    long middle = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[candidate * MODULE_COUNT + middle] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = candidate;
        } else {
          secondLeaf = candidate;
        }
      }

      if (graph[middle * MODULE_COUNT + candidate] == 1) {
        dependent = candidate;
      }

      if (rootDirect[candidate] == 1) {
        if (incomingCount(graph, candidate) == 0) {
          if (firstDirect < 0) {
            firstDirect = candidate;
          } else {
            secondDirect = candidate;
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_NESTED_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      middle,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private SixGraphStructure threeLeafForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == THREE_EDGES) {
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
          if (secondLeaf < 0) {
            secondLeaf = candidate;
          } else {
            thirdLeaf = candidate;
          }
        }
      }

      if (rootDirect[candidate] == 1) {
        if (candidate == dependent) {} else {
          if (firstDirect < 0) {
            firstDirect = candidate;
          } else {
            secondDirect = candidate;
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_THREE_LEAF_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private SixGraphStructure deepChainAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long leaf = -1;
    long second = -1;
    long third = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == 0) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          long next = 0;
          while (next < MODULE_COUNT) limit MODULE_COUNT {
            if (graph[candidate * MODULE_COUNT + next] == 1) {
              if (outgoingCount(graph, next) == SINGLE_EDGE) {
                leaf = candidate;
                second = next;
              }
            }

            next += 1;
          }
        }
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[second * MODULE_COUNT + candidate] == 1) {
        third = candidate;
      }

      candidate += 1;
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[third * MODULE_COUNT + candidate] == 1) {
        dependent = candidate;
      }

      if (rootDirect[candidate] == 1) {
        if (incomingCount(graph, candidate) == 0) {
          if (firstDirect < 0) {
            firstDirect = candidate;
          } else {
            secondDirect = candidate;
          }
        }
      }

      candidate += 1;
    }

    return new SixGraphStructure(
      SIX_STRUCTURE_DEEP_CHAIN_AND_DIRECTS,
      leaf,
      second,
      third,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  private SixGraphStructure directPlan(borrow mut words order) {
    return new SixGraphStructure(
      SIX_STRUCTURE_DIRECT,
      order[0],
      order[1],
      order[2],
      order[3],
      order[4],
      order[5],
      true
    );
  }

  private SixGraphStructure completeTreePlan(
    borrow mut words graph,
    borrow mut words rootDirect,
    borrow mut words order
  ) {
    if (writeChainOrder(graph, rootDirect, MODULE_COUNT, order)) {
      return new SixGraphStructure(
        SIX_STRUCTURE_CHAIN,
        order[0],
        order[1],
        order[2],
        order[3],
        order[4],
        order[5],
        true
      );
    }

    if (writeForkOrder(graph, rootDirect, MODULE_COUNT, order)) {
      return new SixGraphStructure(
        SIX_STRUCTURE_FORK,
        order[0],
        order[1],
        order[2],
        order[3],
        order[4],
        order[5],
        true
      );
    }

    return invalidSixGraphStructure();
  }

  /// Selects one exact admitted topology after complete rooted graph validation.
  public SixGraphStructure selectSixGraphStructure(
    borrow mut words graph,
    borrow mut words rootDirect,
    long edgeCount,
    long rootCount,
    borrow mut words order
  ) {
    if (edgeCount == 0) {
      if (rootCount == SIX_ROOTS) {
        return directPlan(order);
      }
    }

    if (edgeCount == SINGLE_EDGE) {
      if (rootCount == FIVE_ROOTS) {
        return chainAndDirectsPlan(graph, rootDirect);
      }
    }

    if (edgeCount == TWO_EDGES) {
      if (rootCount == FOUR_ROOTS) {
        long maximum = maximumIncoming(graph);
        if (maximum == TWO_EDGES) {
          return forkAndDirectsPlan(graph, rootDirect);
        }

        if (maximum == SINGLE_EDGE) {
          long interiorCount = interiorNodeCount(graph);
          if (interiorCount == 0) {
            return pairsAndDirectsPlan(graph, rootDirect);
          }

          if (interiorCount == SINGLE_EDGE) {
            return longChainAndDirectsPlan(graph, rootDirect);
          }
        }
      }
    }

    if (edgeCount == THREE_EDGES) {
      if (rootCount == THREE_EDGES) {
        long threeEdgeMaximum = maximumIncoming(graph);
        if (threeEdgeMaximum == THREE_EDGES) {
          return threeLeafForkAndDirectsPlan(graph, rootDirect);
        }

        if (threeEdgeMaximum == TWO_EDGES) {
          long candidate = 0;
          while (candidate < MODULE_COUNT) limit MODULE_COUNT {
            if (incomingCount(graph, candidate) == TWO_EDGES) {
              if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
                return nestedForkAndDirectsPlan(graph, rootDirect);
              }
            }

            candidate += 1;
          }

          long twoEdgeInteriorCount = interiorNodeCount(graph);
          if (twoEdgeInteriorCount == SINGLE_EDGE) {
            return unevenTreeAndDirectsPlan(graph, rootDirect);
          }

          if (twoEdgeInteriorCount == 0) {
            return forkChainAndDirectPlan(graph, rootDirect);
          }
        }

        if (threeEdgeMaximum == SINGLE_EDGE) {
          if (maximumOutgoing(graph) == SINGLE_EDGE) {
            long oneEdgeInteriorCount = interiorNodeCount(graph);
            if (oneEdgeInteriorCount == TWO_EDGES) {
              return deepChainAndDirectsPlan(graph, rootDirect);
            }

            if (oneEdgeInteriorCount == SINGLE_EDGE) {
              return longAndShortChainsPlan(graph, rootDirect);
            }

            if (oneEdgeInteriorCount == 0) {
              return threeChainsPlan(graph, rootDirect);
            }
          }
        }
      }
    }

    if (edgeCount == FIVE_EDGES) {
      if (rootCount == SINGLE_EDGE) {
        return completeTreePlan(graph, rootDirect, order);
      }
    }

    return invalidSixGraphStructure();
  }
}
