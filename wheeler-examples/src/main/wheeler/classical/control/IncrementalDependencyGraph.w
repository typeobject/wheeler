//! Propagates invalidation through one bounded mutable dependency graph.

module examples.graph.incremental;

import wheeler.core.collections.long_map;

classical class IncrementalDependencyGraph {
  variant GraphUpdate {
    case Accepted();
    case Cycle(long from, long to);
  }
  const long NODE_COUNT = 4;
  const long EDGE_CELLS = 16;
  const long QUEUE_CELLS = 16;

  state long sourceVersion = 0;
  state long parseVersion = 0;
  state long codeVersion = 0;
  state long linkVersion = 0;
  state long rebuilds = 0;
  state long affected = 0;
  state long cycleRejected = 0;
  state long transactionPhase = 0;

  long edgeIndex(long from, long to) {
    return from * NODE_COUNT + to;
  }

  void clearWords(borrow mut words values, long length) {
    long cursor = 0;
    while (cursor < length) limit QUEUE_CELLS {
      set(values, cursor, 0);
      cursor += 1;
    }
  }

  boolean reachable(
    borrow mut words edges,
    long start,
    long target,
    borrow mut words queue,
    borrow mut words seen
  ) {
    clearWords(queue, QUEUE_CELLS);
    clearWords(seen, NODE_COUNT);
    set(queue, 0, start);
    set(seen, start, 1);
    long head = 0;
    long tail = 1;
    while (head < tail) limit QUEUE_CELLS {
      long node = queue[head];
      if (node == target) {
        return true;
      }

      long next = 0;
      while (next < NODE_COUNT) limit NODE_COUNT {
        if (edges[edgeIndex(node, next)] == 1) {
          if (seen[next] == 0) {
            set(seen, next, 1);
            set(queue, tail, next);
            tail += 1;
          }
        }

        next += 1;
      }

      head += 1;
    }

    return false;
  }

  boolean addEdge(
    borrow mut words edges,
    long from,
    long to,
    borrow mut words queue,
    borrow mut words seen
  ) {
    long selected = edgeIndex(from, to);
    set(edges, selected, 1);
    boolean cycle = reachable(edges, to, from, queue, seen);
    if (cycle) {
      set(edges, selected, 0);
      return false;
    }

    return true;
  }

  GraphUpdate attemptEdge(
    borrow mut words edges,
    long from,
    long to,
    borrow mut words queue,
    borrow mut words seen
  ) {
    boolean accepted = addEdge(edges, from, to, queue, seen);
    if (accepted) {
      return new GraphUpdate.Accepted();
    }

    return new GraphUpdate.Cycle(from, to);
  }

  long invalidate(
    borrow mut words edges,
    long source,
    borrow mut words queue,
    borrow mut words seen,
    borrow mut longmap versions
  ) {
    clearWords(queue, QUEUE_CELLS);
    clearWords(seen, NODE_COUNT);
    set(queue, 0, source);
    set(seen, source, 1);
    long head = 0;
    long tail = 1;
    while (head < tail) limit QUEUE_CELLS {
      long node = queue[head];
      long version = 0;
      if (mapHas(versions, node)) {
        version = mapGet(versions, node);
      }

      put(versions, node, version + 1);
      long next = 0;
      while (next < NODE_COUNT) limit NODE_COUNT {
        if (edges[edgeIndex(node, next)] == 1) {
          if (seen[next] == 0) {
            set(seen, next, 1);
            set(queue, tail, next);
            tail += 1;
          }
        }

        next += 1;
      }

      head += 1;
    }

    return tail;
  }

  /// Builds, rejects a cyclic update, and invalidates every affected node once.
  ///
  /// - Effects: Mutates only declared state and bounded region-owned graph buffers.
  entry void main() {
    region arena = new region(512, 4);
    words edges = allocate(arena, EDGE_CELLS);
    words queue = allocate(arena, QUEUE_CELLS);
    words seen = allocate(arena, NODE_COUNT);
    longmap versions = allocateMap(arena, NODE_COUNT);
    assert(addEdge(edges, 0, 1, queue, seen));
    assert(addEdge(edges, 1, 2, queue, seen));
    assert(addEdge(edges, 2, 3, queue, seen));
    transactionPhase = 1;
    GraphUpdate update = attemptEdge(edges, 3, 0, queue, seen);
    match (update) {
      case GraphUpdate.Accepted() {
        cycleRejected = 0;
        transactionPhase = 3;
      }
      case GraphUpdate.Cycle(long from, long to) {
        cycleRejected = from + to + 1;
        transactionPhase = 2;
      }
    }

    assert(edges[edgeIndex(3, 0)] == 0);
    affected = invalidate(edges, 0, queue, seen, versions);
    rebuilds = affected;
    sourceVersion = mapGet(versions, 0) + 1;
    parseVersion = mapGet(versions, 1) + 1;
    codeVersion = mapGet(versions, 2) + 1;
    linkVersion = mapGet(versions, 3) + 1;
    assert(sourceVersion == 2);
    assert(parseVersion == 2);
    assert(codeVersion == 2);
    assert(linkVersion == 2);
    assert(rebuilds == 4);
    assert(affected == 4);
    assert(cycleRejected == 4);
    assert(transactionPhase == 2);
    drop(versions);
    drop(seen);
    drop(queue);
    drop(edges);
    drop(arena);
  }
}
