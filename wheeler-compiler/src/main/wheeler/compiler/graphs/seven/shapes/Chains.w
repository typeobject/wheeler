//! Assigns exact roles for admitted long seven-module chain shapes.

module wheeler.compiler.graphs.seven.shape_chains;

import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenChainPlanShapes {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_EDGE = 1;
  private const long TWO_EDGES = 2;
  private const long TWO_DIRECTS = 2;
  private const long THREE_DIRECTS = 3;

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

  /// Assigns long and short chains beside two direct root imports.
  public SevenGraphPlan longShortChainsAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long longLeaf = -1;
    long middle = -1;
    long longDependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == SINGLE_EDGE) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          middle = candidate;
        }
      }

      candidate += 1;
    }

    if (middle < 0) {
      return invalidPlan();
    }

    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + middle] == 1) {
        longLeaf = source;
      }

      if (graph[middle * MODULE_COUNT + source] == 1) {
        longDependent = source;
      }

      source += 1;
    }

    if (longLeaf < 0) {
      return invalidPlan();
    }

    if (longDependent < 0) {
      return invalidPlan();
    }

    if (incomingCount(graph, longLeaf) == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[longLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[middle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[longDependent] == 1) {} else {
      return invalidPlan();
    }

    long shortLeaf = -1;
    long shortDependent = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      long dependent = 0;
      while (dependent < MODULE_COUNT) limit MODULE_COUNT {
        if (graph[source * MODULE_COUNT + dependent] == 1) {
          boolean longFirstEdge = source == longLeaf;
          if (longFirstEdge) {
            longFirstEdge = dependent == middle;
          }

          boolean longSecondEdge = source == middle;
          if (longSecondEdge) {
            longSecondEdge = dependent == longDependent;
          }

          if (longFirstEdge) {} else {
            if (longSecondEdge) {} else {
              shortLeaf = source;
              shortDependent = dependent;
            }
          }
        }

        dependent += 1;
      }

      source += 1;
    }

    if (shortLeaf < 0) {
      return invalidPlan();
    }

    if (incomingCount(graph, shortLeaf) == 0) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, shortDependent) == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[shortLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[shortDependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long directCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == longDependent) {} else {
          if (source == shortDependent) {} else {
            if (directCount == 0) {
              firstDirect = source;
            } else {
              secondDirect = source;
            }

            directCount += 1;
          }
        }
      }

      source += 1;
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_LONG_SHORT_CHAINS_AND_DIRECTS,
      longLeaf,
      middle,
      longDependent,
      shortLeaf,
      shortDependent,
      firstDirect,
      secondDirect,
      true
    );
  }

  /// Assigns one four-module chain and three direct root imports.
  public SevenGraphPlan fourChainAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long leaf = -1;
    long firstMiddle = -1;
    long secondMiddle = -1;
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == 0) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          if (rootDirect[candidate] == 0) {
            long target = 0;
            while (target < MODULE_COUNT) limit MODULE_COUNT {
              if (graph[candidate * MODULE_COUNT + target] == 1) {
                if (incomingCount(graph, target) == SINGLE_EDGE) {
                  if (outgoingCount(graph, target) == SINGLE_EDGE) {
                    leaf = candidate;
                    firstMiddle = target;
                  }
                }
              }

              target += 1;
            }
          }
        }
      }

      candidate += 1;
    }

    if (firstMiddle < 0) {
      return invalidPlan();
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[firstMiddle * MODULE_COUNT + candidate] == 1) {
        secondMiddle = candidate;
      }

      candidate += 1;
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

    if (rootDirect[firstMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondMiddle] == 0) {} else {
      return invalidPlan();
    }

    candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[secondMiddle * MODULE_COUNT + candidate] == 1) {
        dependent = candidate;
      }

      candidate += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long directCount = 0;
    long source = 0;
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
      SEVEN_PLAN_FOUR_CHAIN_AND_DIRECTS,
      leaf,
      firstMiddle,
      secondMiddle,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  /// Assigns two three-module chains beside one direct root import.
  public SevenGraphPlan twoLongChainsAndDirectPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long firstMiddle = -1;
    long secondMiddle = -1;
    long middleCount = 0;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == SINGLE_EDGE) {
        if (outgoingCount(graph, candidate) == SINGLE_EDGE) {
          if (middleCount == 0) {
            firstMiddle = candidate;
          } else {
            secondMiddle = candidate;
          }

          middleCount += 1;
        }
      }

      candidate += 1;
    }

    if (middleCount == TWO_EDGES) {} else {
      return invalidPlan();
    }

    long firstLeaf = -1;
    long firstDependent = -1;
    long secondLeaf = -1;
    long secondDependent = -1;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + firstMiddle] == 1) {
        firstLeaf = source;
      }

      if (graph[firstMiddle * MODULE_COUNT + source] == 1) {
        firstDependent = source;
      }

      if (graph[source * MODULE_COUNT + secondMiddle] == 1) {
        secondLeaf = source;
      }

      if (graph[secondMiddle * MODULE_COUNT + source] == 1) {
        secondDependent = source;
      }

      source += 1;
    }

    if (firstLeaf < 0) {
      return invalidPlan();
    }

    if (secondLeaf < 0) {
      return invalidPlan();
    }

    if (rootDirect[firstLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[firstMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[firstDependent] == 1) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondLeaf] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondDependent] == 1) {} else {
      return invalidPlan();
    }

    long direct = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (rootDirect[source] == 1) {
        if (source == firstDependent) {} else {
          if (source == secondDependent) {} else {
            direct = source;
          }
        }
      }

      source += 1;
    }

    if (direct < 0) {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_TWO_LONG_CHAINS_AND_DIRECT,
      firstLeaf,
      firstMiddle,
      firstDependent,
      secondLeaf,
      secondMiddle,
      secondDependent,
      direct,
      true
    );
  }
}
