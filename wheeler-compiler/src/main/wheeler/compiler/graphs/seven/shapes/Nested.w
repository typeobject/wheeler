//! Assigns exact roles for admitted nested seven-module fork shapes.

module wheeler.compiler.graphs.seven.shape_nested;

import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenNestedPlanShapes {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_EDGE = 1;
  private const long TWO_DIRECTS = 2;
  private const long TWO_EDGES = 2;
  private const long THREE_DIRECTS = 3;
  private const long THREE_EDGES = 3;

  private SevenGraphPlan invalidPlan() {
    return new SevenGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  private long incomingCount(borrow mut words graph, long dependent) {
    long count = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[source * MODULE_COUNT + dependent];
      source += 1;
    }

    return count;
  }

  private long outgoingCount(borrow mut words graph, long source) {
    long count = 0;
    long dependent = 0;
    while (dependent < MODULE_COUNT) limit MODULE_COUNT {
      count += graph[source * MODULE_COUNT + dependent];
      dependent += 1;
    }

    return count;
  }

  /// Assigns one nested three-leaf fork and two direct root imports.
  public SevenGraphPlan nestedThreeForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long middle = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == THREE_EDGES) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    if (rootDirect[middle] == 0) {} else {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long dependent = -1;
    long leafCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (leafCount == 0) {
          firstLeaf = source;
        }

        if (leafCount == 1) {
          secondLeaf = source;
        }

        if (leafCount == 2) {
          thirdLeaf = source;
        }

        leafCount += 1;
      }

      if (graph[middle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (leafCount == THREE_EDGES) {} else {
      return invalidPlan();
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          } else {
            secondDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_NESTED_THREE_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      middle,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  /// Assigns one nested two-leaf fork and three direct root imports.
  public SevenGraphPlan nestedForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long middle = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    if (rootDirect[middle] == 0) {} else {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long dependent = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (leafCount == 0) {
          firstLeaf = source;
        } else {
          secondLeaf = source;
        }

        leafCount += 1;
      }

      if (graph[middle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (leafCount == TWO_EDGES) {} else {
      return invalidPlan();
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          }

          if (directCount == 1) {
            secondDirect = source;
          }

          if (directCount == 2) {
            thirdDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == THREE_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_NESTED_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      middle,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  /// Assigns one deep nested two-leaf fork and two direct root imports.
  public SevenGraphPlan deepNestedForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long middle = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long secondMiddle = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = source;
        } else {
          secondLeaf = source;
        }
      }

      if (graph[middle * MODULE_COUNT + source] == 1) {
        secondMiddle = source;
      }

      source += 1;
    }

    if (secondMiddle < 0) {
      return invalidPlan();
    }

    if (incomingCount(graph, secondMiddle) == SINGLE_EDGE) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, secondMiddle) == SINGLE_EDGE) {} else {
      return invalidPlan();
    }

    long dependent = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[secondMiddle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[firstLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[middle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          } else {
            secondDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_DEEP_NESTED_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      middle,
      secondMiddle,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  /// Assigns one uneven nested fork and two direct root imports.
  public SevenGraphPlan unevenNestedForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long middle = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          long possibleDependent = -1;
          long target = 0;
          while (target < MODULE_COUNT) limit MODULE_COUNT {
            if (graph[candidate * MODULE_COUNT + target] == 1) {
              possibleDependent = target;
            }

            target += 1;
          }

          if (incomingCount(graph, possibleDependent) == TWO_EDGES) {
            middle = candidate;
          }
        }
      }

      candidate += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long secondLeaf = -1;
    long dependent = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        if (firstLeaf < 0) {
          firstLeaf = source;
        } else {
          secondLeaf = source;
        }
      }

      if (graph[middle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    long sideLeaf = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (source == middle) {} else {
          sideLeaf = source;
        }
      }

      source += 1;
    }

    if (sideLeaf < 0) {
      return invalidPlan();
    }

    if (rootDirect[firstLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[middle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[sideLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          } else {
            secondDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_UNEVEN_NESTED_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      middle,
      sideLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  /// Assigns two chained branches joined below two direct root imports.
  public SevenGraphPlan pairedNestedChainsAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        if (outgoingCount(graph, candidate) == 0) {
          if (rootDirect[candidate] == 1) {
            dependent = candidate;
          }
        }
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long firstMiddle = -1;
    long secondLeaf = -1;
    long secondMiddle = -1;
    long branchCount = 0;
    long middle = 0;
    while (middle < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[middle * MODULE_COUNT + dependent] == 1) {
        if (incomingCount(graph, middle) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (outgoingCount(graph, middle) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (rootDirect[middle] == 0) {} else {
          return invalidPlan();
        }

        long leaf = -1;
        long leafCandidate = 0;
        while (leafCandidate < MODULE_COUNT) limit MODULE_COUNT {
          if (graph[leafCandidate * MODULE_COUNT + middle] == 1) {
            leaf = leafCandidate;
          }

          leafCandidate += 1;
        }

        if (leaf < 0) {
          return invalidPlan();
        }

        if (rootDirect[leaf] == 0) {} else {
          return invalidPlan();
        }

        if (branchCount == 0) {
          firstLeaf = leaf;
          firstMiddle = middle;
        } else {
          secondLeaf = leaf;
          secondMiddle = middle;
        }

        branchCount += 1;
      }

      middle += 1;
    }

    if (branchCount == TWO_EDGES) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          } else {
            secondDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_PAIRED_NESTED_CHAINS_AND_DIRECTS,
      firstLeaf,
      firstMiddle,
      secondLeaf,
      secondMiddle,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  /// Assigns one extended three-branch fork beside two direct root imports.
  public SevenGraphPlan extendedForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == THREE_EDGES) {
        if (outgoingCount(graph, candidate) == 0) {
          if (rootDirect[candidate] == 1) {
            dependent = candidate;
          }
        }
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    long chainLeaf = -1;
    long middle = -1;
    long firstLeaf = -1;
    long secondLeaf = -1;
    long leafCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (incomingCount(graph, source) == SINGLE_EDGE) {
          if (middle < 0) {} else {
            return invalidPlan();
          }

          if (outgoingCount(graph, source) == SINGLE_EDGE) {} else {
            return invalidPlan();
          }

          middle = source;
        } else {
          if (incomingCount(graph, source) == 0) {} else {
            return invalidPlan();
          }

          if (outgoingCount(graph, source) == SINGLE_EDGE) {} else {
            return invalidPlan();
          }

          if (leafCount == 0) {
            firstLeaf = source;
          } else {
            secondLeaf = source;
          }

          leafCount += 1;
        }
      }

      source += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    if (leafCount == TWO_EDGES) {} else {
      return invalidPlan();
    }

    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        chainLeaf = source;
      }

      source += 1;
    }

    if (chainLeaf < 0) {
      return invalidPlan();
    }

    if (rootDirect[chainLeaf] == 0) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          } else {
            secondDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_EXTENDED_FORK_AND_DIRECTS,
      chainLeaf,
      middle,
      firstLeaf,
      secondLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  /// Assigns one asymmetric nested fork beside two direct root imports.
  public SevenGraphPlan asymmetricNestedForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long junction = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == TWO_EDGES) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          long dependentCandidate = -1;
          long target = 0;
          while (target < MODULE_COUNT) limit MODULE_COUNT {
            if (graph[candidate * MODULE_COUNT + target] == 1) {
              dependentCandidate = target;
            }

            target += 1;
          }

          if (incomingCount(graph, dependentCandidate) == SINGLE_EDGE) {
            if (outgoingCount(graph, dependentCandidate) == 0) {
              if (rootDirect[dependentCandidate] == 1) {
                junction = candidate;
              }
            }
          }
        }
      }

      candidate += 1;
    }

    if (junction < 0) {
      return invalidPlan();
    }

    long branchMiddle = -1;
    long sideLeaf = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + junction] == 1) {
        if (incomingCount(graph, source) == SINGLE_EDGE) {
          branchMiddle = source;
        } else {
          if (incomingCount(graph, source) == 0) {
            sideLeaf = source;
          }
        }
      }

      source += 1;
    }

    if (branchMiddle < 0) {
      return invalidPlan();
    }

    if (sideLeaf < 0) {
      return invalidPlan();
    }

    if (outgoingCount(graph, branchMiddle) == SINGLE_EDGE) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, sideLeaf) == SINGLE_EDGE) {} else {
      return invalidPlan();
    }

    long chainLeaf = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + branchMiddle] == 1) {
        chainLeaf = source;
      }

      source += 1;
    }

    if (chainLeaf < 0) {
      return invalidPlan();
    }

    long dependent = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[junction * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (rootDirect[chainLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[branchMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[sideLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[junction] == 0) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == dependent) {} else {
          if (directCount == 0) {
            firstDirect = source;
          } else {
            secondDirect = source;
          }

          directCount += 1;
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_ASYMMETRIC_NESTED_FORK_AND_DIRECTS,
      chainLeaf,
      branchMiddle,
      sideLeaf,
      junction,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }
}
