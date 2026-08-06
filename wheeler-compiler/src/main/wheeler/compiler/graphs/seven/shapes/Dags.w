//! Assigns exact roles for admitted seven-module directed acyclic graphs.

module wheeler.compiler.graphs.seven.shape_dags;

import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenDagPlanShapes {
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

  /// Assigns one shared constant diamond beside three direct root imports.
  public SevenGraphPlan sharedDiamondAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long shared = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == 0) {
        if (outgoingCount(graph, candidate) == TWO_EDGES) {
          if (rootDirect[candidate] == 0) {
            shared = candidate;
          }
        }
      }

      candidate += 1;
    }

    if (shared < 0) {
      return invalidPlan();
    }

    long firstMiddle = -1;
    long secondMiddle = -1;
    long middleCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[shared * MODULE_COUNT + source] == 1) {
        if (incomingCount(graph, source) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (outgoingCount(graph, source) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }

        if (middleCount == 0) {
          firstMiddle = source;
        } else {
          secondMiddle = source;
        }

        middleCount += 1;
      }

      source += 1;
    }

    if (middleCount == TWO_EDGES) {} else {
      return invalidPlan();
    }

    long dependent = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[firstMiddle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (graph[secondMiddle * MODULE_COUNT + dependent] == 1) {} else {
      return invalidPlan();
    }

    if (incomingCount(graph, dependent) == TWO_EDGES) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, dependent) == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long firstDirect = -1;
    long secondDirect = -1;
    long thirdDirect = -1;
    long directCount = 0;
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
      SEVEN_PLAN_SHARED_DIAMOND_AND_DIRECTS,
      shared,
      firstMiddle,
      secondMiddle,
      dependent,
      firstDirect,
      secondDirect,
      thirdDirect,
      true
    );
  }

  /// Assigns one shared diamond with a side leaf beside two direct imports.
  public SevenGraphPlan sharedDiamondSideAndDirectsPlan(
    borrow mut words graph,
    borrow mut words rootDirect
  ) {
    long shared = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == 0) {
        if (outgoingCount(graph, candidate) == TWO_EDGES) {
          shared = candidate;
        }
      }

      candidate += 1;
    }

    if (shared < 0) {
      return invalidPlan();
    }

    long firstMiddle = -1;
    long secondMiddle = -1;
    long middleCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[shared * MODULE_COUNT + source] == 1) {
        if (incomingCount(graph, source) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (outgoingCount(graph, source) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (middleCount == 0) {
          firstMiddle = source;
        } else {
          secondMiddle = source;
        }

        middleCount += 1;
      }

      source += 1;
    }

    if (middleCount == TWO_EDGES) {} else {
      return invalidPlan();
    }

    long dependent = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[firstMiddle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (graph[secondMiddle * MODULE_COUNT + dependent] == 1) {} else {
      return invalidPlan();
    }

    if (incomingCount(graph, dependent) == THREE_EDGES) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, dependent) == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[dependent] == 1) {} else {
      return invalidPlan();
    }

    long sideLeaf = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[source * MODULE_COUNT + dependent] == 1) {
        if (source == firstMiddle) {} else {
          if (source == secondMiddle) {} else {
            sideLeaf = source;
          }
        }
      }

      source += 1;
    }

    if (sideLeaf < 0) {
      return invalidPlan();
    }

    if (incomingCount(graph, sideLeaf) == 0) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, sideLeaf) == SINGLE_EDGE) {} else {
      return invalidPlan();
    }

    if (rootDirect[shared] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[firstMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[secondMiddle] == 0) {} else {
      return invalidPlan();
    }

    if (rootDirect[sideLeaf] == 0) {} else {
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
      SEVEN_PLAN_SHARED_DIAMOND_SIDE_AND_DIRECTS,
      shared,
      firstMiddle,
      secondMiddle,
      sideLeaf,
      dependent,
      firstDirect,
      secondDirect,
      true
    );
  }

}
