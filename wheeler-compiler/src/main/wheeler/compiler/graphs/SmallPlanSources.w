//! Selects canonical source roles from complete small graph plans.

module wheeler.compiler.graphs.small_plan_sources;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.sources;

classical class SmallPlanSources {
  private long threeSingleEdgeSource(BoundedGraphPlan plan) {
    if (plannedEdge(plan, 0, 1)) {
      return 0;
    }

    if (plannedEdge(plan, 0, 2)) {
      return 0;
    }

    if (plannedEdge(plan, 1, 0)) {
      return 1;
    }

    if (plannedEdge(plan, 1, 2)) {
      return 1;
    }

    if (plannedEdge(plan, 2, 0)) {
      return 2;
    }

    assert(plannedEdge(plan, 2, 1));
    return 2;
  }

  private long threeSingleEdgeDependent(BoundedGraphPlan plan) {
    if (plannedEdge(plan, 0, 1)) {
      return 1;
    }

    if (plannedEdge(plan, 0, 2)) {
      return 2;
    }

    if (plannedEdge(plan, 1, 0)) {
      return 0;
    }

    if (plannedEdge(plan, 1, 2)) {
      return 2;
    }

    if (plannedEdge(plan, 2, 0)) {
      return 0;
    }

    assert(plannedEdge(plan, 2, 1));
    return 1;
  }

  private long threeSharedLeaf(BoundedGraphPlan plan) {
    long node = 0;
    while (node < GRAPH_SOURCE_COUNT_THREE) limit GRAPH_SOURCE_COUNT_THREE {
      if (plannedOutgoingCount(plan, node) == GRAPH_SOURCE_COUNT_TWO) {
        return node;
      }

      node += 1;
    }

    return -1;
  }

  private long threeRootOtherAt(BoundedGraphPlan plan, long excluded, long ordinal) {
    long found = 0;
    long rank = 0;
    while (rank < plan.rootCount) limit GRAPH_SOURCE_COUNT_THREE {
      long node = 0;
      while (node < GRAPH_SOURCE_COUNT_THREE) limit GRAPH_SOURCE_COUNT_THREE {
        if (plannedRootRankAt(plan, node) == rank) {
          if (node == excluded) {} else {
            if (found == ordinal) {
              return node;
            }

            found += 1;
          }
        }

        node += 1;
      }

      rank += 1;
    }

    return -1;
  }

  /// Selects the first canonical role from one complete three-module plan.
  public long threeFirstSource(BoundedGraphPlan plan) {
    if (plan.rootCount == GRAPH_SOURCE_COUNT_THREE) {
      if (plan.edgeCount == GRAPH_SOURCE_COUNT_TWO) {
        return threeSharedLeaf(plan);
      }
    }

    if (plan.edgeCount == 1) {
      return threeSingleEdgeSource(plan);
    }

    return plannedNodeAt(plan, 0);
  }

  /// Selects the second canonical role from one complete three-module plan.
  public long threeSecondSource(BoundedGraphPlan plan) {
    if (plan.rootCount == GRAPH_SOURCE_COUNT_THREE) {
      if (plan.edgeCount == GRAPH_SOURCE_COUNT_TWO) {
        return threeRootOtherAt(plan, threeSharedLeaf(plan), 0);
      }
    }

    if (plan.edgeCount == 1) {
      return threeSingleEdgeDependent(plan);
    }

    return plannedNodeAt(plan, 1);
  }

  /// Selects the final canonical role from one complete three-module plan.
  public long threeThirdSource(BoundedGraphPlan plan) {
    if (plan.rootCount == GRAPH_SOURCE_COUNT_THREE) {
      if (plan.edgeCount == GRAPH_SOURCE_COUNT_TWO) {
        return threeRootOtherAt(plan, threeSharedLeaf(plan), 1);
      }
    }

    if (plan.edgeCount == 1) {
      return GRAPH_SOURCE_COUNT_THREE - threeSingleEdgeSource(plan) - threeSingleEdgeDependent(
        plan
      );
    }

    return plannedNodeAt(plan, 2);
  }
}
