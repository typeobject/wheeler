package com.typeobject.wheeler.runtime.io;

import java.util.ArrayList;
import java.util.List;
import java.util.Objects;

/** Prepared terminal-dependency DAG whose requests remain unsubmitted until execution. */
public final class IoGraph<T> {
  private static final int HARD_GRAPH_LIMIT = 10_000;

  /** Immutable graph node in canonical insertion order. */
  public record Node<T>(IoRequest<T> request, List<Integer> predecessors) {
    public Node {
      Objects.requireNonNull(request, "request");
      predecessors = List.copyOf(predecessors);
    }
  }

  private final List<Node<T>> nodes = new ArrayList<>();
  private final int maxNodes;
  private final int maxEdges;
  private int edgeCount;
  private boolean consumed;

  public IoGraph(int maxNodes, int maxEdges) {
    this.maxNodes = bounded("maxNodes", maxNodes);
    this.maxEdges = bounded("maxEdges", maxEdges);
  }

  /** Adds one request and returns its stable zero-based node identity. */
  public int add(IoRequest<T> request) {
    requireNodeCapacity();
    nodes.add(new Node<>(request, List.of()));
    return nodes.size() - 1;
  }

  /** Adds one request gated on terminal completion of earlier nodes. */
  public int addAfter(IoRequest<T> request, int... predecessors) {
    requireNodeCapacity();
    Objects.requireNonNull(predecessors, "predecessors");
    if (predecessors.length > maxEdges - edgeCount) {
      throw new IllegalStateException("graph edge capacity exceeded");
    }
    List<Integer> checked = new ArrayList<>(predecessors.length);
    int prior = -1;
    for (int predecessor : predecessors) {
      if (predecessor < 0 || predecessor >= nodes.size()) {
        throw new IllegalArgumentException("graph predecessor must already exist");
      }
      if (predecessor <= prior) {
        throw new IllegalArgumentException("graph predecessors must be unique and sorted");
      }
      checked.add(predecessor);
      prior = predecessor;
    }
    edgeCount = Math.addExact(edgeCount, checked.size());
    nodes.add(new Node<>(request, checked));
    return nodes.size() - 1;
  }

  /** Returns the number of prepared graph nodes. */
  public int nodeCount() {
    return nodes.size();
  }

  /** Returns the number of terminal dependency edges. */
  public int edgeCount() {
    return edgeCount;
  }

  List<Node<T>> nodes() {
    requireMutable();
    if (nodes.isEmpty()) {
      throw new IllegalStateException("I/O graph cannot be empty");
    }
    return List.copyOf(nodes);
  }

  void markConsumed() {
    requireMutable();
    consumed = true;
  }

  private void requireNodeCapacity() {
    requireMutable();
    if (nodes.size() >= maxNodes) {
      throw new IllegalStateException("graph node capacity exceeded");
    }
  }

  private void requireMutable() {
    if (consumed) {
      throw new IllegalStateException("I/O graph was already consumed");
    }
  }

  private static int bounded(String name, int value) {
    if (value < 1 || value > HARD_GRAPH_LIMIT) {
      throw new IllegalArgumentException(name + " must be between 1 and 10000");
    }
    return value;
  }
}
