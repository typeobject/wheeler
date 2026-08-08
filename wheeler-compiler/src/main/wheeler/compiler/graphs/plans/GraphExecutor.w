//! Executes every validated bounded graph through one source table.

module wheeler.compiler.graphs.executor;

import wheeler.compiler.canonical_helper_linking;
import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.source_table;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class BoundedGraphPlanExecutor {
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;
  private const long ROOT_METADATA_ARENA_BYTES = 224;
  private const long SOURCE_BYTE_LIMIT = 32769;

  /// Carries one bounded graph-plan execution result.
  public record GraphPlanExecution(long length, long codeStart) {}

  private record RootDependencyLink(
    long length,
    long ownerStart,
    long ownerLength,
    long helperCount,
    boolean helper,
    boolean valid
  ) {}

  private GraphPlanExecution failedExecution() {
    return new GraphPlanExecution(0, 0);
  }

  private boolean genericGraphPlan(BoundedGraphPlan plan) {
    return plan.valid;
  }

  private boolean initializeExecutionTable(
    BoundedGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    return initializeSourceTable(
      plan.nodeCount,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      storage,
      lengths
    );
  }

  private utf8 copyExecutionSource(
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

  private long writeRootSource(borrow utf8 source, borrow mut bytes storage) {
    long length = bufferLength(source);
    assert(length < SOURCE_BYTE_LIMIT);
    long cursor = 0;
    while (cursor < length) limit MAX_LINKED_SOURCE_BYTES {
      assert(utf8Width(source, cursor) == 1);
      setByte(storage, cursor, utf8Scalar(source, cursor));
      cursor += 1;
    }

    return length;
  }

  private utf8 copyRootSource(borrow mut bytes storage, long length, borrow mut region arena) {
    assert(length < SOURCE_BYTE_LIMIT);
    bytes copied = allocateBytes(arena, length);
    long cursor = 0;
    while (cursor < length) limit MAX_LINKED_SOURCE_BYTES {
      setByte(copied, cursor, storage[cursor]);
      cursor += 1;
    }

    return freezeUtf8(copied);
  }

  private boolean linkDependency(
    BoundedGraphPlan plan,
    long dependencyNode,
    long dependentNode,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    region dependencyArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 dependencySource = copyExecutionSource(
      dependencyNode,
      tableCount,
      storage,
      lengths,
      dependencyArena
    );
    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 dependentSource = copyExecutionSource(
      dependentNode,
      tableCount,
      storage,
      lengths,
      dependentArena
    );
    LinkPlan link = planPrivateResolvedConstantImport(
      dependencySource,
      dependentSource,
      plannedIncomingCount(plan, dependentNode)
    );
    if (link.valid) {} else {
      link = planSharedResolvedConstantImport(
        dependencySource,
        dependentSource,
        plannedIncomingCount(plan, dependentNode)
      );
    }

    if (link.valid) {} else {
      drop(dependentSource);
      drop(dependentArena);
      drop(dependencySource);
      drop(dependencyArena);
      return false;
    }

    region linkedArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, link.linkedLength);
    long linkedLength = writeConstantImport(
      dependencySource,
      dependentSource,
      link,
      linkedBytes
    );
    assert(linkedLength == link.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    boolean replaced = replaceSourceTableSlot(
      dependentNode,
      tableCount,
      linkedSource,
      storage,
      lengths
    );
    drop(linkedSource);
    drop(linkedArena);
    drop(dependentSource);
    drop(dependentArena);
    drop(dependencySource);
    drop(dependencyArena);
    return replaced;
  }

  private long rootNodeAt(BoundedGraphPlan plan, long rank) {
    long node = 0;
    while (node < plan.nodeCount) limit MAX_GRAPH_NODES {
      if (plannedRootRankAt(plan, node) == rank) {
        return node;
      }

      node += 1;
    }

    return -1;
  }

  private RootDependencyLink linkRootDependency(
    BoundedGraphPlan plan,
    long dependencyNode,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut bytes rootStorage,
    long rootLength
  ) {
    region dependencyArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 dependencySource = copyExecutionSource(
      dependencyNode,
      tableCount,
      storage,
      lengths,
      dependencyArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 rootSource = copyRootSource(rootStorage, rootLength, rootArena);
    LinkPlan link = planResolvedConstantImport(dependencySource, rootSource, plan.rootCount);
    if (link.valid) {} else {
      link = planTrailingSharedResolvedPublicConstantImport(
        dependencySource,
        rootSource,
        plan.rootCount
      );
    }

    boolean helper = false;
    if (link.valid) {} else {
      link = planResolvedHelperImport(dependencySource, rootSource, plan.rootCount);
      helper = link.valid;
    }

    if (link.valid) {} else {
      link = planSharedResolvedHelperImport(dependencySource, rootSource, plan.rootCount);
      helper = link.valid;
    }

    if (link.valid) {} else {
      drop(rootSource);
      drop(rootArena);
      drop(dependencySource);
      drop(dependencyArena);
      return new RootDependencyLink(0, 0, 0, 0, false, false);
    }

    region linkedArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, link.linkedLength);
    long linkedLength = 0;
    if (helper) {
      linkedLength = writeCanonicalHelperImport(dependencySource, rootSource, link, linkedBytes);
    } else {
      linkedLength = writeConstantImport(dependencySource, rootSource, link, linkedBytes);
    }

    assert(linkedLength == link.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    long replacementLength = writeRootSource(linkedSource, rootStorage);
    RootDependencyLink result = new RootDependencyLink(
      replacementLength,
      link.linkedOwnerStart,
      link.linkedOwnerLength,
      link.importedHelperCount,
      helper,
      true
    );
    drop(linkedSource);
    drop(linkedArena);
    drop(rootSource);
    drop(rootArena);
    drop(dependencySource);
    drop(dependencyArena);
    return result;
  }

  private boolean rootDependencyIsHelper(
    BoundedGraphPlan plan,
    long node,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut bytes rootStorage,
    long rootLength
  ) {
    region dependencyArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 dependencySource = copyExecutionSource(
      node,
      tableCount,
      storage,
      lengths,
      dependencyArena
    );
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 rootSource = copyRootSource(rootStorage, rootLength, rootArena);
    LinkPlan helper = planResolvedHelperImport(dependencySource, rootSource, plan.rootCount);
    if (helper.valid) {} else {
      helper = planSharedResolvedHelperImport(dependencySource, rootSource, plan.rootCount);
    }

    boolean result = helper.valid;
    drop(rootSource);
    drop(rootArena);
    drop(dependencySource);
    drop(dependencyArena);
    return result;
  }

  private void sortOwnerColumns(
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words counts,
    long ownerCount
  ) {
    long index = 1;
    while (index < ownerCount) limit MAX_GRAPH_NODES {
      long cursor = index;
      while (0 < cursor) limit MAX_GRAPH_NODES {
        if (starts[cursor] < starts[cursor - 1]) {
          long start = starts[cursor];
          long length = lengths[cursor];
          long count = counts[cursor];
          set(starts, cursor, starts[cursor - 1]);
          set(lengths, cursor, lengths[cursor - 1]);
          set(counts, cursor, counts[cursor - 1]);
          set(starts, cursor - 1, start);
          set(lengths, cursor - 1, length);
          set(counts, cursor - 1, count);
        }

        cursor -= 1;
      }

      index += 1;
    }
  }

  private boolean rootDependencyReady(
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

  /// Executes one validated two- through seven-module graph.
  public GraphPlanExecution executeGraphPlan(
    BoundedGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    if (genericGraphPlan(plan)) {} else {
      return failedExecution();
    }

    region tableArena = new region(/* bytes= */ SOURCE_TABLE_ARENA_BYTES, /* allocations= */ 2);
    bytes storage = allocateBytes(tableArena, SOURCE_TABLE_BYTES);
    words lengths = allocate(tableArena, SOURCE_TABLE_LENGTH_WORDS);
    boolean initialized = initializeExecutionTable(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      storage,
      lengths
    );
    if (initialized) {} else {
      drop(lengths);
      drop(storage);
      drop(tableArena);
      return failedExecution();
    }

    long tableCount = plan.nodeCount;
    long position = 0;
    while (position < plan.nodeCount) limit MAX_GRAPH_NODES {
      long dependencyNode = plannedNodeAt(plan, position);
      long dependentNode = 0;
      while (dependentNode < plan.nodeCount) limit MAX_GRAPH_NODES {
        if (plannedEdge(plan, dependencyNode, dependentNode)) {
          if (
            linkDependency(plan, dependencyNode, dependentNode, tableCount, storage, lengths)
          ) {} else {
            drop(lengths);
            drop(storage);
            drop(tableArena);
            return failedExecution();
          }
        }

        dependentNode += 1;
      }

      position += 1;
    }

    region rootStorageArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes rootStorage = allocateBytes(rootStorageArena, MAX_LINKED_SOURCE_BYTES);
    long rootLength = writeRootSource(rootSource, rootStorage);
    region rootMetadataArena = new region(
      /* bytes= */ ROOT_METADATA_ARENA_BYTES,
      /* allocations= */ 4
    );
    words linkedRoots = allocate(rootMetadataArena, MAX_GRAPH_NODES);
    words ownerStarts = allocate(rootMetadataArena, MAX_GRAPH_NODES);
    words ownerLengths = allocate(rootMetadataArena, MAX_GRAPH_NODES);
    words ownerCounts = allocate(rootMetadataArena, MAX_GRAPH_NODES);
    long helperOwnerCount = 0;
    long linkedRootCount = 0;
    while (linkedRootCount < plan.rootCount) limit MAX_GRAPH_NODES {
      long selectedRootNode = -1;
      boolean selectedIsHelper = false;
      long rootRank = 0;
      while (rootRank < plan.rootCount) limit MAX_GRAPH_NODES {
        long candidateRootNode = rootNodeAt(plan, rootRank);
        if (0 < candidateRootNode + 1) {} else {
          drop(ownerCounts);
          drop(ownerLengths);
          drop(ownerStarts);
          drop(linkedRoots);
          drop(rootMetadataArena);
          drop(rootStorage);
          drop(rootStorageArena);
          drop(lengths);
          drop(storage);
          drop(tableArena);
          return failedExecution();
        }

        if (linkedRoots[candidateRootNode] == 0) {
          if (rootDependencyReady(plan, candidateRootNode, linkedRoots)) {
            boolean candidateIsHelper = rootDependencyIsHelper(
              plan,
              candidateRootNode,
              tableCount,
              storage,
              lengths,
              rootStorage,
              rootLength
            );
            if (candidateIsHelper) {
              selectedRootNode = candidateRootNode;
              selectedIsHelper = true;
            } else {
              if (selectedRootNode < 0) {
                if (selectedIsHelper == false) {
                  selectedRootNode = candidateRootNode;
                }
              }
            }
          }
        }

        rootRank += 1;
      }

      if (0 < selectedRootNode + 1) {} else {
        drop(ownerCounts);
        drop(ownerLengths);
        drop(ownerStarts);
        drop(linkedRoots);
        drop(rootMetadataArena);
        drop(rootStorage);
        drop(rootStorageArena);
        drop(lengths);
        drop(storage);
        drop(tableArena);
        return failedExecution();
      }

      RootDependencyLink rootLink = linkRootDependency(
        plan,
        selectedRootNode,
        tableCount,
        storage,
        lengths,
        rootStorage,
        rootLength
      );
      if (rootLink.valid) {
        rootLength = rootLink.length;
      } else {
        drop(ownerCounts);
        drop(ownerLengths);
        drop(ownerStarts);
        drop(linkedRoots);
        drop(rootMetadataArena);
        drop(rootStorage);
        drop(rootStorageArena);
        drop(lengths);
        drop(storage);
        drop(tableArena);
        return failedExecution();
      }

      if (rootLink.helper) {
        set(ownerStarts, helperOwnerCount, rootLink.ownerStart);
        set(ownerLengths, helperOwnerCount, rootLink.ownerLength);
        set(ownerCounts, helperOwnerCount, rootLink.helperCount);
        helperOwnerCount += 1;
      }

      set(linkedRoots, selectedRootNode, 1);
      linkedRootCount += 1;
    }

    sortOwnerColumns(ownerStarts, ownerLengths, ownerCounts, helperOwnerCount);
    HelperOwners owners = helperOwnersFromColumns(
      ownerStarts,
      ownerLengths,
      ownerCounts,
      helperOwnerCount
    );
    drop(ownerCounts);
    drop(ownerLengths);
    drop(ownerStarts);
    drop(linkedRoots);
    drop(rootMetadataArena);
    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 finalSource = copyRootSource(rootStorage, rootLength, finalArena);
    CoreCompilation core = compileMinimalCoreWithHelperOwners(finalSource, output, owners);
    GraphPlanExecution executed = new GraphPlanExecution(core.length, core.codeStart);
    drop(finalSource);
    drop(finalArena);
    drop(rootStorage);
    drop(rootStorageArena);
    drop(lengths);
    drop(storage);
    drop(tableArena);
    return executed;
  }
}
