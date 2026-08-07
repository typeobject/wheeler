//! Validates bounded directed graph matrices used by native module plans.

module wheeler.compiler.graphs.matrix;

classical class BoundedGraphMatrix {
  private const long MAX_GRAPH_NODES = 7;
  private const long ORDER_RADIX = 8;
  private const long MAX_GRAPH_BITS = 49;

  /// Carries canonical bounded graph facts after complete rooted validation.
  public record BoundedGraphPlan(
    long nodeCount,
    long edgeCount,
    long rootCount,
    long edgeBits,
    long rootBits,
    long orderCode,
    long rootOrderCode,
    long privateBits,
    long sharedBits,
    boolean valid
  ) {}

  private BoundedGraphPlan invalidPlan() {
    return new BoundedGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, false);
  }

  private long incomingCount(borrow mut words graph, long nodeCount, long node) {
    long count = 0;
    long other = 0;
    while (other < nodeCount) limit MAX_GRAPH_NODES {
      count += graph[other * nodeCount + node];
      other += 1;
    }

    return count;
  }

  private long outgoingCount(borrow mut words graph, long nodeCount, long node) {
    long count = 0;
    long other = 0;
    while (other < nodeCount) limit MAX_GRAPH_NODES {
      count += graph[node * nodeCount + other];
      other += 1;
    }

    return count;
  }

  private boolean unused(borrow mut words order, long length, long candidate) {
    long cursor = 0;
    while (cursor < length) limit MAX_GRAPH_NODES {
      if (order[cursor] == candidate) {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  /// Writes one deterministic leaf-first order and proves every node reaches the root.
  public boolean writeRootedTopologicalOrder(
    borrow mut words graph,
    borrow mut words rootDirect,
    long nodeCount,
    borrow mut words order,
    borrow mut words reachable
  ) {
    if (0 < nodeCount) {} else {
      return false;
    }

    if (nodeCount < MAX_GRAPH_NODES + 1) {} else {
      return false;
    }

    long position = 0;
    while (position < nodeCount) limit MAX_GRAPH_NODES {
      long selected = -1;
      long node = 0;
      while (node < nodeCount) limit MAX_GRAPH_NODES {
        if (unused(order, position, node)) {
          boolean ready = true;
          long dependency = 0;
          while (dependency < nodeCount) limit MAX_GRAPH_NODES {
            if (unused(order, position, dependency)) {
              if (graph[dependency * nodeCount + node] == 1) {
                ready = false;
              }
            }

            dependency += 1;
          }

          if (ready) {
            if (selected < 0) {
              selected = node;
            }
          }
        }

        node += 1;
      }

      if (selected < 0) {
        return false;
      }

      set(order, position, selected);
      position += 1;
    }

    long reverseCursor = 0;
    while (reverseCursor < nodeCount) limit MAX_GRAPH_NODES {
      long reversePosition = nodeCount - reverseCursor - 1;
      long reverseNode = order[reversePosition];
      boolean reaches = rootDirect[reverseNode] == 1;
      long dependent = 0;
      while (dependent < nodeCount) limit MAX_GRAPH_NODES {
        if (graph[reverseNode * nodeCount + dependent] == 1) {
          if (reachable[dependent] == 1) {
            reaches = true;
          }
        }

        dependent += 1;
      }

      if (reaches) {
        set(reachable, reverseNode, 1);
      } else {
        return false;
      }

      reverseCursor += 1;
    }

    return true;
  }

  private long powerOfTwo(long exponent) {
    long power = 1;
    long cursor = 0;
    while (cursor < exponent) limit MAX_GRAPH_BITS {
      power = power * 2;
      cursor += 1;
    }

    return power;
  }

  /// Records exact edges, root visibility, role order, privacy, and shared dependencies.
  public BoundedGraphPlan planBoundedGraph(
    borrow mut words graph,
    borrow mut words rootDirect,
    borrow mut words rootRanks,
    long nodeCount,
    borrow mut words order,
    borrow mut words reachable
  ) {
    if (0 < nodeCount) {} else {
      return invalidPlan();
    }

    if (nodeCount < MAX_GRAPH_NODES + 1) {} else {
      return invalidPlan();
    }

    if (writeRootedTopologicalOrder(graph, rootDirect, nodeCount, order, reachable)) {} else {
      return invalidPlan();
    }

    long edgeCount = 0;
    long rootCount = 0;
    long edgeBits = 0;
    long rootBits = 0;
    long orderCode = 0;
    long rootOrderCode = 0;
    long privateBits = 0;
    long sharedBits = 0;
    long source = 0;
    while (source < nodeCount) limit MAX_GRAPH_NODES {
      long sourcePower = powerOfTwo(source);
      if (rootDirect[source] == 1) {
        long rootRank = rootRanks[source];
        if (0 < rootRank + 1) {} else {
          return invalidPlan();
        }

        if (rootRank < nodeCount) {} else {
          return invalidPlan();
        }

        long prior = 0;
        while (prior < source) limit MAX_GRAPH_NODES {
          if (rootDirect[prior] == 1) {
            if (rootRanks[prior] == rootRank) {
              return invalidPlan();
            }
          }

          prior += 1;
        }

        rootBits += sourcePower;
        rootCount += 1;
      } else {
        privateBits += sourcePower;
      }

      long outgoing = 0;
      long dependent = 0;
      while (dependent < nodeCount) limit MAX_GRAPH_NODES {
        if (graph[source * nodeCount + dependent] == 1) {
          long edge = source * nodeCount + dependent;
          edgeBits += powerOfTwo(edge);
          edgeCount += 1;
          outgoing += 1;
        }

        dependent += 1;
      }

      if (1 < outgoing) {
        sharedBits += sourcePower;
      }

      long orderPower = 1;
      long position = 0;
      while (position < source) limit MAX_GRAPH_NODES {
        orderPower = orderPower * ORDER_RADIX;
        position += 1;
      }

      orderCode += order[source] * orderPower;
      if (rootDirect[source] == 1) {
        rootOrderCode += (rootRanks[source] + 1) * orderPower;
      }

      source += 1;
    }

    long rank = 0;
    while (rank < rootCount) limit MAX_GRAPH_NODES {
      boolean present = false;
      source = 0;
      while (source < nodeCount) limit MAX_GRAPH_NODES {
        if (rootDirect[source] == 1) {
          if (rootRanks[source] == rank) {
            present = true;
          }
        }

        source += 1;
      }

      if (present) {} else {
        return invalidPlan();
      }

      rank += 1;
    }

    return new BoundedGraphPlan(
      nodeCount,
      edgeCount,
      rootCount,
      edgeBits,
      rootBits,
      orderCode,
      rootOrderCode,
      privateBits,
      sharedBits,
      true
    );
  }

  private long planDigit(BoundedGraphPlan plan, long packed, long index) {
    assert(plan.valid);
    assert(0 < index + 1);
    assert(index < plan.nodeCount);
    long shifted = packed;
    long cursor = 0;
    while (cursor < index) limit MAX_GRAPH_NODES {
      shifted = shifted / ORDER_RADIX;
      cursor += 1;
    }

    return shifted % ORDER_RADIX;
  }

  private boolean planBit(BoundedGraphPlan plan, long bits, long index) {
    assert(plan.valid);
    assert(0 < index + 1);
    assert(index < plan.nodeCount);
    long selected = bits / powerOfTwo(index);
    return selected % 2 == 1;
  }

  /// Selects one node from the validated leaf-first order.
  public long plannedNodeAt(BoundedGraphPlan plan, long position) {
    return planDigit(plan, plan.orderCode, position);
  }

  /// Selects one root-header import rank, or negative one for a private node.
  public long plannedRootRankAt(BoundedGraphPlan plan, long node) {
    return planDigit(plan, plan.rootOrderCode, node) - 1;
  }

  /// Reports whether the root imports one node directly.
  public boolean plannedRootDirect(BoundedGraphPlan plan, long node) {
    return planBit(plan, plan.rootBits, node);
  }

  /// Reports whether one node remains private to its dependents.
  public boolean plannedPrivate(BoundedGraphPlan plan, long node) {
    return planBit(plan, plan.privateBits, node);
  }

  /// Reports whether one dependency feeds more than one dependent.
  public boolean plannedShared(BoundedGraphPlan plan, long node) {
    return planBit(plan, plan.sharedBits, node);
  }

  /// Reports whether one validated dependency edge is present.
  public boolean plannedEdge(BoundedGraphPlan plan, long source, long dependent) {
    assert(plan.valid);
    assert(0 < source + 1);
    assert(source < plan.nodeCount);
    assert(0 < dependent + 1);
    assert(dependent < plan.nodeCount);
    long edge = source * plan.nodeCount + dependent;
    long selected = plan.edgeBits / powerOfTwo(edge);
    return selected % 2 == 1;
  }

  /// Writes leaves followed by the root-visible dependent for one complete fork.
  public boolean writeForkOrder(
    borrow mut words graph,
    borrow mut words rootDirect,
    long nodeCount,
    borrow mut words order
  ) {
    if (2 < nodeCount) {} else {
      return false;
    }

    if (nodeCount < MAX_GRAPH_NODES + 1) {} else {
      return false;
    }

    long dependent = -1;
    long dependentCount = 0;
    long node = 0;
    while (node < nodeCount) limit MAX_GRAPH_NODES {
      long incoming = incomingCount(graph, nodeCount, node);
      long outgoing = outgoingCount(graph, nodeCount, node);
      if (rootDirect[node] == 1) {
        if (incoming == nodeCount - 1) {
          if (outgoing == 0) {
            dependent = node;
            dependentCount += 1;
          }
        }
      }

      node += 1;
    }

    if (dependentCount == 1) {} else {
      return false;
    }

    long position = 0;
    node = 0;
    while (node < nodeCount) limit MAX_GRAPH_NODES {
      if (node == dependent) {} else {
        if (rootDirect[node] == 0) {} else {
          return false;
        }

        if (incomingCount(graph, nodeCount, node) == 0) {} else {
          return false;
        }

        if (outgoingCount(graph, nodeCount, node) == 1) {} else {
          return false;
        }

        if (graph[node * nodeCount + dependent] == 1) {} else {
          return false;
        }

        set(order, position, node);
        position += 1;
      }

      node += 1;
    }

    set(order, nodeCount - 1, dependent);
    return position == nodeCount - 1;
  }

  /// Writes the unique leaf-to-root order for one complete directed chain.
  public boolean writeChainOrder(
    borrow mut words graph,
    borrow mut words rootDirect,
    long nodeCount,
    borrow mut words order
  ) {
    if (1 < nodeCount) {} else {
      return false;
    }

    if (nodeCount < MAX_GRAPH_NODES + 1) {} else {
      return false;
    }

    long rootOwner = -1;
    long rootCount = 0;
    long leaf = -1;
    long leafCount = 0;
    long node = 0;
    while (node < nodeCount) limit MAX_GRAPH_NODES {
      long incoming = incomingCount(graph, nodeCount, node);
      long outgoing = outgoingCount(graph, nodeCount, node);
      if (incoming < 2) {} else {
        return false;
      }

      if (outgoing < 2) {} else {
        return false;
      }

      if (incoming == 0) {
        leaf = node;
        leafCount += 1;
      }

      if (rootDirect[node] == 1) {
        rootOwner = node;
        rootCount += 1;
      }

      node += 1;
    }

    if (leafCount == 1) {} else {
      return false;
    }

    if (rootCount == 1) {} else {
      return false;
    }

    set(order, 0, leaf);
    long position = 1;
    while (position < nodeCount) limit MAX_GRAPH_NODES {
      long previous = order[position - 1];
      long next = -1;
      long nextCount = 0;
      node = 0;
      while (node < nodeCount) limit MAX_GRAPH_NODES {
        if (graph[previous * nodeCount + node] == 1) {
          if (unused(order, position, node)) {
            next = node;
            nextCount += 1;
          }
        }

        node += 1;
      }

      if (nextCount == 1) {} else {
        return false;
      }

      set(order, position, next);
      position += 1;
    }

    return order[nodeCount - 1] == rootOwner;
  }
}
