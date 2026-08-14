//! Propagates invalidation through one bounded mutable dependency graph.

module examples.graph.incremental;

import wheeler.core.collections.long_map;
import wheeler.core.collections.queue;

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

  boolean visited(borrow mut longmap seen, long node, long generation) {
    if (mapHas(seen, node)) {
      return mapGet(seen, node) == generation;
    }

    return false;
  }

  QueueCursor append(
    borrow mut words values,
    QueueCursor cursor,
    long value
  ) {
    Push result = push(values, cursor, value);
    match (result) {
      case Push.Full() {
        return cursor;
      }
      case Push.Value(QueueCursor next) {
        return next;
      }
    }
  }

  boolean reachable(
    borrow mut words edges,
    long start,
    long target,
    borrow mut words queue,
    borrow mut longmap seen,
    long generation
  ) {
    QueueCursor cursor = new QueueCursor(0, 0);
    cursor = append(queue, cursor, start);
    put(seen, start, generation);
    while (cursor.head < cursor.tail) limit QUEUE_CELLS {
      Pop result = pop(queue, cursor);
      match (result) {
        case Pop.Empty() {
          return false;
        }
        case Pop.Value(long node, QueueCursor after) {
          cursor = after;
          if (node == target) {
            return true;
          }

          long neighbor = 0;
          while (neighbor < NODE_COUNT) limit NODE_COUNT {
            if (edges[edgeIndex(node, neighbor)] == 1) {
              if (visited(seen, neighbor, generation) == false) {
                put(seen, neighbor, generation);
                cursor = append(queue, cursor, neighbor);
              }
            }

            neighbor += 1;
          }
        }
      }
    }

    return false;
  }

  boolean addEdge(
    borrow mut words edges,
    long from,
    long to,
    borrow mut words queue,
    borrow mut longmap seen,
    long generation
  ) {
    long selected = edgeIndex(from, to);
    set(edges, selected, 1);
    boolean cycle = reachable(edges, to, from, queue, seen, generation);
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
    borrow mut longmap seen,
    long generation
  ) {
    boolean accepted = addEdge(edges, from, to, queue, seen, generation);
    if (accepted) {
      return new GraphUpdate.Accepted();
    }

    return new GraphUpdate.Cycle(from, to);
  }

  long invalidate(
    borrow mut words edges,
    long source,
    borrow mut words queue,
    borrow mut longmap seen,
    borrow mut longmap versions,
    long generation
  ) {
    QueueCursor cursor = new QueueCursor(0, 0);
    cursor = append(queue, cursor, source);
    put(seen, source, generation);
    long count = 0;
    while (cursor.head < cursor.tail) limit QUEUE_CELLS {
      Pop result = pop(queue, cursor);
      match (result) {
        case Pop.Empty() {
          return count;
        }
        case Pop.Value(long node, QueueCursor after) {
          cursor = after;
          long version = 0;
          if (mapHas(versions, node)) {
            version = mapGet(versions, node);
          }

          put(versions, node, version + 1);
          count += 1;
          long neighbor = 0;
          while (neighbor < NODE_COUNT) limit NODE_COUNT {
            if (edges[edgeIndex(node, neighbor)] == 1) {
              if (visited(seen, neighbor, generation) == false) {
                put(seen, neighbor, generation);
                cursor = append(queue, cursor, neighbor);
              }
            }

            neighbor += 1;
          }
        }
      }
    }

    return count;
  }

  /// Builds, rejects a cyclic update, and invalidates every affected node once.
  ///
  /// - Effects: Mutates only declared state and bounded region-owned graph buffers.
  entry void main() {
    region arena = new region(512, 4);
    words edges = allocate(arena, EDGE_CELLS);
    words queue = allocate(arena, QUEUE_CELLS);
    longmap seen = allocateMap(arena, NODE_COUNT);
    longmap versions = allocateMap(arena, NODE_COUNT);
    assert(addEdge(edges, 0, 1, queue, seen, 1));
    assert(addEdge(edges, 1, 2, queue, seen, 2));
    assert(addEdge(edges, 2, 3, queue, seen, 3));
    transactionPhase = 1;
    GraphUpdate update = attemptEdge(edges, 3, 0, queue, seen, 4);
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
    affected = invalidate(edges, 0, queue, seen, versions, 5);
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
