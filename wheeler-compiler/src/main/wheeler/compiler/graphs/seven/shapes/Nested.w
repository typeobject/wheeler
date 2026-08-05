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

}
