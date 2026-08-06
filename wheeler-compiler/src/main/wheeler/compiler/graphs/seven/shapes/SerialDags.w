//! Assigns exact roles for serial seven-module directed acyclic graphs.

module wheeler.compiler.graphs.seven.shape_serial_dags;

import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven_plan_kinds;

classical class SevenSerialDagPlanShapes {
  private const long MODULE_COUNT = 7;
  private const long SINGLE_EDGE = 1;
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

  /// Assigns two serial shared diamonds spanning all seven imported modules.
  public SevenGraphPlan serialDiamondsPlan(borrow mut words graph, borrow mut words rootDirect) {
    long firstShared = -1;
    long candidate = 0;
    while (candidate < MODULE_COUNT) limit MODULE_COUNT {
      if (incomingCount(graph, candidate) == 0) {
        if (outgoingCount(graph, candidate) == TWO_EDGES) {
          firstShared = candidate;
        }
      }

      candidate += 1;
    }

    if (firstShared < 0) {
      return invalidPlan();
    }

    long firstMiddle = -1;
    long secondMiddle = -1;
    long middleCount = 0;
    long source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[firstShared * MODULE_COUNT + source] == 1) {
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

    long secondShared = -1;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[firstMiddle * MODULE_COUNT + source] == 1) {
        secondShared = source;
      }

      source += 1;
    }

    if (secondShared < 0) {
      return invalidPlan();
    }

    if (graph[secondMiddle * MODULE_COUNT + secondShared] == 1) {} else {
      return invalidPlan();
    }

    if (incomingCount(graph, secondShared) == TWO_EDGES) {} else {
      return invalidPlan();
    }

    if (outgoingCount(graph, secondShared) == TWO_EDGES) {} else {
      return invalidPlan();
    }

    long thirdMiddle = -1;
    long fourthMiddle = -1;
    middleCount = 0;
    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (graph[secondShared * MODULE_COUNT + source] == 1) {
        if (incomingCount(graph, source) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (outgoingCount(graph, source) == SINGLE_EDGE) {} else {
          return invalidPlan();
        }

        if (middleCount == 0) {
          thirdMiddle = source;
        } else {
          fourthMiddle = source;
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
      if (graph[thirdMiddle * MODULE_COUNT + source] == 1) {
        dependent = source;
      }

      source += 1;
    }

    if (dependent < 0) {
      return invalidPlan();
    }

    if (graph[fourthMiddle * MODULE_COUNT + dependent] == 1) {} else {
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

    source = 0;
    while (source < MODULE_COUNT) limit MODULE_COUNT {
      if (source == dependent) {} else {
        if (rootDirect[source] == 0) {} else {
          return invalidPlan();
        }
      }

      source += 1;
    }

    return new SevenGraphPlan(
      SEVEN_PLAN_SERIAL_DIAMONDS,
      firstShared,
      firstMiddle,
      secondMiddle,
      secondShared,
      thirdMiddle,
      fourthMiddle,
      dependent,
      true
    );
  }
}
