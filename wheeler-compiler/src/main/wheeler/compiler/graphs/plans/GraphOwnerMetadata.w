//! Carries executable-owner order through bounded graph linking.

module wheeler.compiler.graphs.owner_metadata;

import wheeler.compiler.graphs.matrix;

classical class GraphOwnerMetadata {
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_LINKED_SOURCE_BYTES = 36864;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long OWNER_MARKER_BYTES = 4;
  private const long SOURCE_BYTE_LIMIT = 36865;

  /// Marks dependency owners not yet present in one dependent source.
  public long writeUniqueSlotOwners(
    long dependencyNode,
    long dependentNode,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words ownerKeep
  ) {
    long kept = 0;
    long owner = 0;
    while (owner < slotOwnerCounts[dependencyNode]) limit MAX_GRAPH_NODES {
      long candidate = slotOwnerNodes[dependencyNode * MAX_GRAPH_NODES + owner];
      boolean present = false;
      long dependentOwner = 0;
      while (dependentOwner < slotOwnerCounts[dependentNode]) limit MAX_GRAPH_NODES {
        if (
          slotOwnerNodes[dependentNode * MAX_GRAPH_NODES + dependentOwner] == candidate
        ) {
          present = true;
        }

        dependentOwner += 1;
      }

      if (present) {
        set(ownerKeep, owner, 0);
      } else {
        set(ownerKeep, owner, 1);
        kept += 1;
      }

      owner += 1;
    }

    return kept;
  }

  /// Marks source owners not yet present in the synthetic root.
  public long writeUniqueRootOwners(
    long node,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words rootOwnerCount,
    borrow mut words rootOwnerNodes,
    borrow mut words ownerKeep
  ) {
    long kept = 0;
    long owner = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      long candidate = slotOwnerNodes[node * MAX_GRAPH_NODES + owner];
      boolean present = false;
      long rootOwner = 0;
      while (rootOwner < rootOwnerCount[0]) limit MAX_GRAPH_NODES {
        if (rootOwnerNodes[rootOwner] == candidate) {
          present = true;
        }

        rootOwner += 1;
      }

      if (present) {
        set(ownerKeep, owner, 0);
      } else {
        set(ownerKeep, owner, 1);
        kept += 1;
      }

      owner += 1;
    }

    return kept;
  }

  /// Counts helpers removed by one exact owner-identity filter.
  public long removedOwnerHelperCount(
    long node,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words helperCounts,
    borrow mut words ownerKeep
  ) {
    long removed = 0;
    long owner = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      if (ownerKeep[owner] == 0) {
        removed += helperCounts[slotOwnerNodes[node * MAX_GRAPH_NODES + owner]];
      }

      owner += 1;
    }

    return removed;
  }

  /// Compresses one source owner row after exact helper-member filtering.
  public void filterOwnerOrder(
    long node,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words ownerKeep
  ) {
    long written = 0;
    long owner = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      if (ownerKeep[owner] == 1) {
        set(
          slotOwnerNodes,
          node * MAX_GRAPH_NODES + written,
          slotOwnerNodes[node * MAX_GRAPH_NODES + owner]
        );
        written += 1;
      }

      owner += 1;
    }

    long kept = written;
    while (written < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      set(slotOwnerNodes, node * MAX_GRAPH_NODES + written, 0);
      written += 1;
    }

    set(slotOwnerCounts, node, kept);
  }

  /// Counts helpers imported ahead of one physical dependent's own members.
  public long slotImportedHelperCount(
    BoundedGraphPlan plan,
    long node,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words helperCounts
  ) {
    long count = 0;
    long owner = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      long ownerNode = slotOwnerNodes[node * MAX_GRAPH_NODES + owner];
      if (plannedExecutable(plan, node)) {
        if (ownerNode == node) {
          return count;
        }
      }

      count += helperCounts[ownerNode];
      owner += 1;
    }

    return count;
  }

  /// Inserts one dependency's retained owners before the dependent's own members.
  public boolean mergeUniqueOwnerOrders(
    BoundedGraphPlan plan,
    long dependencyNode,
    long dependentNode,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words ownerKeep
  ) {
    long kept = 0;
    long owner = 0;
    while (owner < slotOwnerCounts[dependencyNode]) limit MAX_GRAPH_NODES {
      kept += ownerKeep[owner];
      owner += 1;
    }

    long dependentCount = slotOwnerCounts[dependentNode];
    if (kept + dependentCount < MAX_GRAPH_NODES + 1) {} else {
      return false;
    }

    long insertAt = dependentCount;
    if (plannedExecutable(plan, dependentNode)) {
      if (0 < dependentCount) {
        if (
          slotOwnerNodes[dependentNode * MAX_GRAPH_NODES + dependentCount - 1] == dependentNode
        ) {
          insertAt = dependentCount - 1;
        }
      }
    }

    long shifted = dependentCount;
    while (insertAt < shifted) limit MAX_GRAPH_NODES {
      set(
        slotOwnerNodes,
        dependentNode * MAX_GRAPH_NODES + kept + shifted - 1,
        slotOwnerNodes[dependentNode * MAX_GRAPH_NODES + shifted - 1]
      );
      shifted -= 1;
    }

    long written = 0;
    owner = 0;
    while (owner < slotOwnerCounts[dependencyNode]) limit MAX_GRAPH_NODES {
      if (ownerKeep[owner] == 1) {
        set(
          slotOwnerNodes,
          dependentNode * MAX_GRAPH_NODES + insertAt + written,
          slotOwnerNodes[dependencyNode * MAX_GRAPH_NODES + owner]
        );
        written += 1;
      }

      owner += 1;
    }

    set(slotOwnerCounts, dependentNode, kept + dependentCount);
    return true;
  }

  /// Appends one linked root's exact owner order to the synthetic root order.
  public boolean appendRootOwnerOrder(
    long node,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words rootOwnerCount,
    borrow mut words rootOwnerNodes
  ) {
    long added = slotOwnerCounts[node];
    long existing = rootOwnerCount[0];
    if (added + existing < MAX_GRAPH_NODES + 1) {} else {
      return false;
    }

    long source = 0;
    while (source < added) limit MAX_GRAPH_NODES {
      long owner = slotOwnerNodes[node * MAX_GRAPH_NODES + source];
      long target = 0;
      while (target < existing) limit MAX_GRAPH_NODES {
        if (rootOwnerNodes[target] == owner) {
          return false;
        }

        target += 1;
      }

      set(rootOwnerNodes, existing + source, owner);
      source += 1;
    }

    set(rootOwnerCount, 0, added + existing);
    return true;
  }

  /// Counts helpers already linked before the root's own executable members.
  public long rootImportedHelperCount(
    borrow mut words rootOwnerCount,
    borrow mut words rootOwnerNodes,
    borrow mut words helperCounts
  ) {
    long count = 0;
    long owner = 0;
    while (owner < rootOwnerCount[0]) limit MAX_GRAPH_NODES {
      count += helperCounts[rootOwnerNodes[owner]];
      owner += 1;
    }

    return count;
  }

  /// Adds inert canonical-name markers for helper owners private to the root graph.
  public long markPrivateHelperOwners(
    borrow mut bytes sourceStorage,
    long sourceLength,
    borrow mut bytes tableStorage,
    borrow mut words moduleStarts,
    borrow mut words moduleLengths,
    borrow mut words rootModuleStarts,
    borrow mut words rootModuleLengths,
    borrow mut words rootOwnerCount,
    borrow mut words rootOwnerNodes
  ) {
    long prefixLength = 0;
    long owner = 0;
    long node = 0;
    while (owner < rootOwnerCount[0]) limit MAX_GRAPH_NODES {
      node = rootOwnerNodes[owner];
      if (rootModuleLengths[node] == 0) {
        prefixLength += moduleLengths[node] + OWNER_MARKER_BYTES;
      }

      owner += 1;
    }

    if (sourceLength + prefixLength < SOURCE_BYTE_LIMIT) {} else {
      return -1;
    }

    long shifted = sourceLength;
    while (0 < shifted) limit MAX_LINKED_SOURCE_BYTES {
      setByte(sourceStorage, prefixLength + shifted - 1, sourceStorage[shifted - 1]);
      shifted -= 1;
    }

    owner = 0;
    while (owner < rootOwnerCount[0]) limit MAX_GRAPH_NODES {
      node = rootOwnerNodes[owner];
      if (0 < rootModuleLengths[node]) {
        set(rootModuleStarts, node, rootModuleStarts[node] + prefixLength);
      }

      owner += 1;
    }

    long cursor = 0;
    owner = 0;
    while (owner < rootOwnerCount[0]) limit MAX_GRAPH_NODES {
      node = rootOwnerNodes[owner];
      if (rootModuleLengths[node] == 0) {
        setByte(sourceStorage, cursor, 47);
        setByte(sourceStorage, cursor + 1, 42);
        long moduleCursor = 0;
        while (moduleCursor < moduleLengths[node]) limit MAX_SOURCE_BYTES {
          setByte(
            sourceStorage,
            cursor + 2 + moduleCursor,
            tableStorage[node * MAX_SOURCE_BYTES + moduleStarts[node] + moduleCursor]
          );
          moduleCursor += 1;
        }

        set(rootModuleStarts, node, cursor + 2);
        set(rootModuleLengths, node, moduleLengths[node]);
        cursor += moduleLengths[node] + OWNER_MARKER_BYTES;
        setByte(sourceStorage, cursor - 2, 42);
        setByte(sourceStorage, cursor - 1, 47);
      }

      owner += 1;
    }

    assert(cursor == prefixLength);
    return sourceLength + prefixLength;
  }

  /// Writes compiler owner columns in exact synthetic helper order.
  public void writeOwnerColumns(
    borrow mut words rootOwnerCount,
    borrow mut words rootOwnerNodes,
    borrow mut words helperCounts,
    borrow mut words rootModuleStarts,
    borrow mut words rootModuleLengths,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words counts
  ) {
    long owner = 0;
    while (owner < rootOwnerCount[0]) limit MAX_GRAPH_NODES {
      long node = rootOwnerNodes[owner];
      assert(0 < rootModuleLengths[node]);
      assert(0 < helperCounts[node]);
      set(starts, owner, rootModuleStarts[node]);
      set(lengths, owner, rootModuleLengths[node]);
      set(counts, owner, helperCounts[node]);
      owner += 1;
    }
  }
}
