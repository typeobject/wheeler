//! Selects canonical source roles from complete four-module plans.

module wheeler.compiler.graphs.four_plan_sources;

import wheeler.compiler.graphs.matrix;

classical class FourPlanSources {
  private const long MODULE_COUNT = 4;
  private const long THREE_LEAVES = 3;

  /// Carries four canonical executor roles without a topology identity.
  public record FourSourceOrder(
    long first,
    long second,
    long third,
    long fourth,
    boolean valid
  ) {}

  private FourSourceOrder invalidOrder() {
    return new FourSourceOrder(0, 0, 0, 0, false);
  }

  /// Reports the largest incoming degree in one validated plan.
  public long fourMaximumIncoming(BoundedGraphPlan plan) {
    long maximum = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      long count = plannedIncomingCount(plan, node);
      if (maximum < count) {
        maximum = count;
      }

      node += 1;
    }

    return maximum;
  }

  /// Reports whether one nonroot node lies between a leaf and a dependent.
  public boolean fourHasMiddle(BoundedGraphPlan plan) {
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (plannedIncomingCount(plan, node) == 1) {
        if (plannedOutgoingCount(plan, node) == 1) {
          return true;
        }
      }

      node += 1;
    }

    return false;
  }

  /// Counts edges entering direct root modules.
  public long fourRootIncoming(BoundedGraphPlan plan) {
    long count = 0;
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (plannedRootDirect(plan, node)) {
        count += plannedIncomingCount(plan, node);
      }

      node += 1;
    }

    return count;
  }

  private long rootWithIncoming(BoundedGraphPlan plan, long degree) {
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (plannedRootDirect(plan, node)) {
        if (plannedIncomingCount(plan, node) == degree) {
          return node;
        }
      }

      node += 1;
    }

    return -1;
  }

  private long middleNode(BoundedGraphPlan plan) {
    long node = 0;
    while (node < MODULE_COUNT) limit MODULE_COUNT {
      if (plannedIncomingCount(plan, node) == 1) {
        if (plannedOutgoingCount(plan, node) == 1) {
          return node;
        }
      }

      node += 1;
    }

    return -1;
  }

  private long rootOtherAt(BoundedGraphPlan plan, long excluded, long ordinal) {
    long found = 0;
    long rank = 0;
    while (rank < plan.rootCount) limit MODULE_COUNT {
      long node = 0;
      while (node < MODULE_COUNT) limit MODULE_COUNT {
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

  private long incomingSourceAt(BoundedGraphPlan plan, long dependent, long ordinal) {
    long found = 0;
    long position = 0;
    while (position < MODULE_COUNT) limit MODULE_COUNT {
      long source = plannedNodeAt(plan, position);
      if (plannedEdge(plan, source, dependent)) {
        if (found == ordinal) {
          return source;
        }

        found += 1;
      }

      position += 1;
    }

    return -1;
  }

  private FourSourceOrder oneEdgeOrder(BoundedGraphPlan plan) {
    long dependent = rootWithIncoming(plan, 1);
    long leaf = plannedSingleSource(plan, dependent);
    return new FourSourceOrder(
      leaf,
      dependent,
      rootOtherAt(plan, dependent, 0),
      rootOtherAt(plan, dependent, 1),
      true
    );
  }

  private FourSourceOrder twoEdgeOrder(BoundedGraphPlan plan) {
    if (fourMaximumIncoming(plan) == 2) {
      long forkDependent = rootWithIncoming(plan, 2);
      return new FourSourceOrder(
        incomingSourceAt(plan, forkDependent, 0),
        incomingSourceAt(plan, forkDependent, 1),
        forkDependent,
        rootOtherAt(plan, forkDependent, 0),
        true
      );
    }

    if (fourHasMiddle(plan)) {
      long chainDependent = rootWithIncoming(plan, 1);
      long middle = plannedSingleSource(plan, chainDependent);
      return new FourSourceOrder(
        plannedSingleSource(plan, middle),
        middle,
        chainDependent,
        rootOtherAt(plan, chainDependent, 0),
        true
      );
    }

    long firstDependent = rootOtherAt(plan, -1, 0);
    long secondDependent = rootOtherAt(plan, -1, 1);
    return new FourSourceOrder(
      plannedSingleSource(plan, firstDependent),
      firstDependent,
      plannedSingleSource(plan, secondDependent),
      secondDependent,
      true
    );
  }

  private FourSourceOrder threeEdgeOrder(BoundedGraphPlan plan) {
    long maximumIncoming = fourMaximumIncoming(plan);
    if (maximumIncoming == THREE_LEAVES) {
      long forkDependent = rootWithIncoming(plan, THREE_LEAVES);
      return new FourSourceOrder(
        incomingSourceAt(plan, forkDependent, 0),
        incomingSourceAt(plan, forkDependent, 1),
        incomingSourceAt(plan, forkDependent, 2),
        forkDependent,
        true
      );
    }

    if (maximumIncoming == 2) {
      if (fourRootIncoming(plan) == 1) {
        long parent = rootWithIncoming(plan, 1);
        long fork = plannedSingleSource(plan, parent);
        return new FourSourceOrder(
          incomingSourceAt(plan, fork, 0),
          incomingSourceAt(plan, fork, 1),
          fork,
          parent,
          true
        );
      }

      long unevenDependent = rootWithIncoming(plan, 2);
      long middle = middleNode(plan);
      long firstIncoming = incomingSourceAt(plan, unevenDependent, 0);
      long secondIncoming = incomingSourceAt(plan, unevenDependent, 1);
      long otherLeaf = firstIncoming;
      if (firstIncoming == middle) {
        otherLeaf = secondIncoming;
      }

      return new FourSourceOrder(
        plannedSingleSource(plan, middle),
        middle,
        otherLeaf,
        unevenDependent,
        true
      );
    }

    return new FourSourceOrder(
      plannedNodeAt(plan, 0),
      plannedNodeAt(plan, 1),
      plannedNodeAt(plan, 2),
      plannedNodeAt(plan, 3),
      true
    );
  }

  /// Selects four canonical executor roles from one validated graph plan.
  public FourSourceOrder planFourSources(BoundedGraphPlan plan) {
    if (plan.valid) {} else {
      return invalidOrder();
    }

    if (plan.nodeCount == MODULE_COUNT) {} else {
      return invalidOrder();
    }

    if (plan.edgeCount == 0) {
      return new FourSourceOrder(
        plannedNodeAt(plan, 0),
        plannedNodeAt(plan, 1),
        plannedNodeAt(plan, 2),
        plannedNodeAt(plan, 3),
        true
      );
    }

    if (plan.edgeCount == 1) {
      return oneEdgeOrder(plan);
    }

    if (plan.edgeCount == 2) {
      return twoEdgeOrder(plan);
    }

    if (plan.edgeCount == 3) {
      return threeEdgeOrder(plan);
    }

    if (plan.edgeCount == MODULE_COUNT) {
      return new FourSourceOrder(
        plannedNodeAt(plan, 0),
        plannedNodeAt(plan, 1),
        plannedNodeAt(plan, 2),
        plannedNodeAt(plan, 3),
        true
      );
    }

    return invalidOrder();
  }
}
