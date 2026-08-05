//! Assigns exact roles for admitted wide seven-module fork shapes.

module wheeler.compiler.graphs.seven.shape_forks;

import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenForkPlanShapes {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_DIRECT = 1;
  private const long TWO_DIRECTS = 2;
  private const long THREE_DIRECTS = 3;
  private const long THREE_EDGES = 3;
  private const long FOUR_EDGES = 4;
  private const long FIVE_EDGES = 5;

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

  /// Assigns one three-leaf fork and three direct root imports.
  public SevenGraphPlan threeLeafForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == THREE_EDGES) {
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

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
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
      } else {
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
      }

      source += 1;
    }

    if (leafCount == THREE_EDGES) {} else {
      return invalidPlan();
    }

    if (directCount == THREE_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_THREE_LEAF_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  /// Assigns one five-leaf fork and one direct root import.
  public SevenGraphPlan fiveLeafForkAndDirectPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == FIVE_EDGES) {
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

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long fourthLeaf = -1;
    long fifthLeaf = -1;
    long direct = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
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

        if (leafCount == 3) {
          fourthLeaf = source;
        }

        if (leafCount == 4) {
          fifthLeaf = source;
        }

        leafCount += 1;
      } else {
        if (rootDirect[source] == 1) {
          if (source == dependent) {} else {
            direct = source;
            directCount += 1;
          }
        }
      }

      source += 1;
    }

    if (leafCount == FIVE_EDGES) {} else {
      return invalidPlan();
    }

    if (directCount == SINGLE_DIRECT) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_FIVE_LEAF_FORK_AND_DIRECT,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      fourthLeaf,
      fifthLeaf,
      dependent,
      direct,
      true
    );
  }

  /// Assigns one four-leaf fork and two direct root imports.
  public SevenGraphPlan wideForkAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long dependent = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == FOUR_EDGES) {
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

    long firstLeaf = -1;
    long secondLeaf = -1;
    long thirdLeaf = -1;
    long fourthLeaf = -1;
    long firstDirect = -1;
    long secondDirect = -1;
    long leafCount = 0;
    long directCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
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

        if (leafCount == 3) {
          fourthLeaf = source;
        }

        leafCount += 1;
      } else {
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
      }

      source += 1;
    }

    if (leafCount == FOUR_EDGES) {} else {
      return invalidPlan();
    }

    if (directCount == TWO_DIRECTS) {} else {
      return invalidPlan();
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_WIDE_FORK_AND_DIRECTS,
      firstLeaf,
      secondLeaf,
      thirdLeaf,
      fourthLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

}
