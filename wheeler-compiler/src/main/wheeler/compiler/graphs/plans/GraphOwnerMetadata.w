//! Carries executable-owner order through bounded graph linking.

module wheeler.compiler.graphs.owner_metadata;

classical class GraphOwnerMetadata {
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;
  private const long OWNER_MARKER_BYTES = 4;
  private const long SOURCE_BYTE_LIMIT = 32769;

  /// Prepends one dependency's owner order to its dependent source order.
  public boolean mergeOwnerOrders(
    long dependencyNode,
    long dependentNode,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes
  ) {
    long dependencyCount = slotOwnerCounts[dependencyNode];
    long dependentCount = slotOwnerCounts[dependentNode];
    if (dependencyCount + dependentCount < MAX_GRAPH_NODES + 1) {} else {
      return false;
    }

    long dependency = 0;
    while (dependency < dependencyCount) limit MAX_GRAPH_NODES {
      long dependencyOwner = slotOwnerNodes[dependencyNode * MAX_GRAPH_NODES + dependency];
      long dependent = 0;
      while (dependent < dependentCount) limit MAX_GRAPH_NODES {
        if (
          slotOwnerNodes[dependentNode * MAX_GRAPH_NODES + dependent] == dependencyOwner
        ) {
          return false;
        }

        dependent += 1;
      }

      dependency += 1;
    }

    long shifted = dependentCount;
    while (0 < shifted) limit MAX_GRAPH_NODES {
      set(
        slotOwnerNodes,
        dependentNode * MAX_GRAPH_NODES + dependencyCount + shifted - 1,
        slotOwnerNodes[dependentNode * MAX_GRAPH_NODES + shifted - 1]
      );
      shifted -= 1;
    }

    dependency = 0;
    while (dependency < dependencyCount) limit MAX_GRAPH_NODES {
      set(
        slotOwnerNodes,
        dependentNode * MAX_GRAPH_NODES + dependency,
        slotOwnerNodes[dependencyNode * MAX_GRAPH_NODES + dependency]
      );
      dependency += 1;
    }

    set(slotOwnerCounts, dependentNode, dependencyCount + dependentCount);
    return true;
  }

  /// Prepends one linked root's exact owner order to the synthetic root order.
  public boolean prependRootOwnerOrder(
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

      source += 1;
    }

    long shifted = existing;
    while (0 < shifted) limit MAX_GRAPH_NODES {
      set(rootOwnerNodes, added + shifted - 1, rootOwnerNodes[shifted - 1]);
      shifted -= 1;
    }

    source = 0;
    while (source < added) limit MAX_GRAPH_NODES {
      set(rootOwnerNodes, source, slotOwnerNodes[node * MAX_GRAPH_NODES + source]);
      source += 1;
    }

    set(rootOwnerCount, 0, added + existing);
    return true;
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
        while (moduleCursor < moduleLengths[node]) limit MAX_LINKED_SOURCE_BYTES {
          setByte(
            sourceStorage,
            cursor + 2 + moduleCursor,
            tableStorage[node * MAX_LINKED_SOURCE_BYTES + moduleStarts[node] + moduleCursor]
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
