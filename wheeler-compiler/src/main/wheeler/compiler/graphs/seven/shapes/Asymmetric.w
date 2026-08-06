//! Assigns exact roles for asymmetric seven-module fork shapes.

module wheeler.compiler.graphs.seven.shape_asymmetric;

import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenAsymmetricPlanShapes {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_EDGE = 1;
  private const long TWO_DIRECTS = 2;
  private const long TWO_EDGES = 2;

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
