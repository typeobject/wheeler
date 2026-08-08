//! Selects canonical bounded dependency and root execution order.

module wheeler.compiler.graphs.execution_order;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.source_table;
import wheeler.compiler.module_headers;

classical class GraphExecutionOrder {
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;

  private utf8 copySource(
    long node,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut region arena
  ) {
    long length = sourceTableSlotLength(node, tableCount, lengths);
    bytes copied = allocateBytes(arena, length);
    long written = copySourceTableSlot(node, tableCount, storage, lengths, copied);
    assert(written == length);
    return freezeUtf8(copied);
  }

  /// Selects one dependency by its validated dependent-header import rank.
  public long dependencyNodeAtRank(
    BoundedGraphPlan plan,
    long dependentNode,
    long rank,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    long selected = -1;
    long dependencyNode = 0;
    while (dependencyNode < plan.nodeCount) limit MAX_GRAPH_NODES {
      if (plannedEdge(plan, dependencyNode, dependentNode)) {
        region dependencyArena = new region(
          /* bytes= */ MAX_LINKED_SOURCE_BYTES,
          /* allocations= */ 1
        );
        utf8 dependencySource = copySource(
          dependencyNode,
          tableCount,
          storage,
          lengths,
          dependencyArena
        );
        region dependentArena = new region(
          /* bytes= */ MAX_LINKED_SOURCE_BYTES,
          /* allocations= */ 1
        );
        utf8 dependentSource = copySource(
          dependentNode,
          tableCount,
          storage,
          lengths,
          dependentArena
        );
        HeaderDependency dependency = moduleDependency(dependencySource, dependentSource);
        if (dependency.valid) {
          if (dependency.importsCandidate) {
            if (dependency.candidateImportRank == rank) {
              assert(selected < 0);
              selected = dependencyNode;
            }
          }
        }

        drop(dependentSource);
        drop(dependentArena);
        drop(dependencySource);
        drop(dependencyArena);
      }

      dependencyNode += 1;
    }

    return selected;
  }

  /// Propagates physical executable kinds through every planned dependency edge.
  public void writeExecutableSources(
    BoundedGraphPlan plan,
    borrow mut words executableKinds,
    borrow mut words executableSources
  ) {
    long node = 0;
    while (node < plan.nodeCount) limit MAX_GRAPH_NODES {
      set(executableSources, node, executableKinds[node]);
      node += 1;
    }

    long position = 0;
    while (position < plan.nodeCount) limit MAX_GRAPH_NODES {
      long dependency = plannedNodeAt(plan, position);
      if (executableSources[dependency] == 1) {
        long dependent = 0;
        while (dependent < plan.nodeCount) limit MAX_GRAPH_NODES {
          if (plannedEdge(plan, dependency, dependent)) {
            set(executableSources, dependent, 1);
          }

          dependent += 1;
        }
      }

      position += 1;
    }
  }

  /// Selects one direct root dependency by canonical root-import rank.
  public long rootNodeAt(BoundedGraphPlan plan, long rank) {
    long node = 0;
    while (node < plan.nodeCount) limit MAX_GRAPH_NODES {
      if (plannedRootRankAt(plan, node) == rank) {
        return node;
      }

      node += 1;
    }

    return -1;
  }

  /// Requires every redundant direct prerequisite before linking one root source.
  public boolean rootDependencyReady(
    BoundedGraphPlan plan,
    long node,
    borrow mut words linkedRoots
  ) {
    long dependency = 0;
    while (dependency < plan.nodeCount) limit MAX_GRAPH_NODES {
      if (plannedEdge(plan, dependency, node)) {
        if (plannedRootDirect(plan, dependency)) {
          if (linkedRoots[dependency] == 1) {} else {
            return false;
          }
        }
      }

      dependency += 1;
    }

    return true;
  }
}
