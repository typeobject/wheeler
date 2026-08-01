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
    long privateBits,
    long sharedBits,
    boolean valid
  ) {}

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
    long nodeCount,
    borrow mut words order,
    borrow mut words reachable
  ) {
    if (0 < nodeCount) {} else {
      return new BoundedGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
    }

    if (nodeCount < MAX_GRAPH_NODES + 1) {} else {
      return new BoundedGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
    }

    if (writeRootedTopologicalOrder(graph, rootDirect, nodeCount, order, reachable)) {} else {
      return new BoundedGraphPlan(0, 0, 0, 0, 0, 0, 0, 0, false);
    }

    long edgeCount = 0;
    long rootCount = 0;
    long edgeBits = 0;
    long rootBits = 0;
    long orderCode = 0;
    long privateBits = 0;
    long sharedBits = 0;
    long source = 0;
    while (source < nodeCount) limit MAX_GRAPH_NODES {
      long sourcePower = powerOfTwo(source);
      if (rootDirect[source] == 1) {
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
      source += 1;
    }

    return new BoundedGraphPlan(
      nodeCount,
      edgeCount,
      rootCount,
      edgeBits,
      rootBits,
      orderCode,
      privateBits,
      sharedBits,
      true
    );
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
