//! Executes bounded constant and private-helper graphs through one source table.

module wheeler.compiler.graphs.executor;

import wheeler.compiler.canonical_helper_linking;
import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.executable_owner_kinds;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.owner_metadata;
import wheeler.compiler.graphs.source_table;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;

classical class BoundedGraphPlanExecutor {
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;
  private const long OWNER_METADATA_ARENA_BYTES = 1392;
  private const long SOURCE_BYTE_LIMIT = 32769;

  /// Carries one bounded graph-plan execution result.
  public record GraphPlanExecution(long length, long codeStart) {}

  private record DependencyLink(long helperCount, boolean valid) {}

  private record RootDependencyLink(
    long length,
    long ownerStart,
    long ownerLength,
    long helperCount,
    boolean helper,
    boolean valid
  ) {}

  private record ExecutableOwnerProbe(
    long helperCount,
    long moduleStart,
    long moduleLength,
    boolean executable
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

  private long firstDependentNode(BoundedGraphPlan plan, long node) {
    long dependent = 0;
    while (dependent < plan.nodeCount) limit MAX_GRAPH_NODES {
      if (plannedEdge(plan, node, dependent)) {
        return dependent;
      }

      dependent += 1;
    }

    return -1;
  }

  private long dependencyNodeAtRank(
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
        utf8 dependencySource = copyExecutionSource(
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
        utf8 dependentSource = copyExecutionSource(
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

  private ExecutableOwnerProbe probeExecutableOwner(
    BoundedGraphPlan plan,
    long node,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut bytes rootStorage,
    long rootLength
  ) {
    region sourceArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 source = copyExecutionSource(node, tableCount, storage, lengths, sourceArena);
    LinkPlan helper = new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
    long dependent = firstDependentNode(plan, node);
    if (0 < dependent + 1) {
      region dependencyTargetArena = new region(
        /* bytes= */ MAX_LINKED_SOURCE_BYTES,
        /* allocations= */ 1
      );
      utf8 dependencyTarget = copyExecutionSource(
        dependent,
        tableCount,
        storage,
        lengths,
        dependencyTargetArena
      );
      helper = planResolvedHelperImport(
        source,
        dependencyTarget,
        plannedIncomingCount(plan, dependent)
      );
      drop(dependencyTarget);
      drop(dependencyTargetArena);
    } else {
      region rootTargetArena = new region(
        /* bytes= */ MAX_LINKED_SOURCE_BYTES,
        /* allocations= */ 1
      );
      utf8 rootTarget = copyRootSource(rootStorage, rootLength, rootTargetArena);
      helper = planResolvedHelperImport(source, rootTarget, plan.rootCount);
      drop(rootTarget);
      drop(rootTargetArena);
    }

    ExecutableOwnerProbe result = new ExecutableOwnerProbe(0, 0, 0, false);
    if (helper.valid) {
      result = new ExecutableOwnerProbe(
        helper.importedHelperCount,
        helper.importedModuleStart,
        helper.importedModuleLength,
        true
      );
    } else {
      ExecutableOwnerKind kind = classifyExecutableOwner(source);
      if (kind.valid) {
        if (kind.executable) {
          result = new ExecutableOwnerProbe(
            /* helperCount= */ 0,
            kind.moduleStart,
            kind.moduleLength,
            true
          );
        }
      }
    }

    drop(source);
    drop(sourceArena);
    return result;
  }

  private BoundedGraphPlan classifyExecutableOwners(
    BoundedGraphPlan plan,
    long tableCount,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut bytes rootStorage,
    long rootLength,
    borrow mut words executableKinds,
    borrow mut words helperCounts,
    borrow mut words moduleStarts,
    borrow mut words moduleLengths,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes
  ) {
    long node = 0;
    while (node < plan.nodeCount) limit MAX_GRAPH_NODES {
      ExecutableOwnerProbe probe = probeExecutableOwner(
        plan,
        node,
        tableCount,
        storage,
        lengths,
        rootStorage,
        rootLength
      );
      if (probe.executable) {
        set(executableKinds, node, 1);
        set(helperCounts, node, probe.helperCount);
        set(moduleStarts, node, probe.moduleStart);
        set(moduleLengths, node, probe.moduleLength);
        set(slotOwnerCounts, node, 1);
        set(slotOwnerNodes, node * MAX_GRAPH_NODES, node);
      }

      node += 1;
    }

    return planExecutableOwners(plan, executableKinds);
  }

  private boolean linearExecutableOwners(BoundedGraphPlan plan) {
    long node = 0;
    while (node < plan.nodeCount) limit MAX_GRAPH_NODES {
      if (plannedExecutable(plan, node)) {
        long outgoing = plannedOutgoingCount(plan, node);
        if (1 < outgoing) {
          return false;
        }

        if (plannedRootDirect(plan, node)) {
          if (0 < outgoing) {
            return false;
          }
        }
      }

      node += 1;
    }

    return true;
  }

  private void writeExecutableSources(
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

  private boolean recordOwnHelperCount(
    BoundedGraphPlan plan,
    long node,
    long totalHelperCount,
    borrow mut words slotOwnerCounts,
    borrow mut words slotOwnerNodes,
    borrow mut words helperCounts
  ) {
    if (0 < totalHelperCount) {} else {
      return false;
    }

    long knownCount = 0;
    boolean ownsHelpers = false;
    long owner = 0;
    while (owner < slotOwnerCounts[node]) limit MAX_GRAPH_NODES {
      long ownerNode = slotOwnerNodes[node * MAX_GRAPH_NODES + owner];
      if (ownerNode == node) {
        ownsHelpers = true;
      } else {
        knownCount += helperCounts[ownerNode];
      }

      owner += 1;
    }

    if (plannedExecutable(plan, node)) {
      if (ownsHelpers) {} else {
        return false;
      }

      long ownCount = totalHelperCount - knownCount;
      if (0 < ownCount) {} else {
        return false;
      }

      if (helperCounts[node] == 0) {
        set(helperCounts, node, ownCount);
      } else {
        if (helperCounts[node] == ownCount) {} else {
          return false;
        }
      }

      return true;
    }

    return totalHelperCount == knownCount;
  }

  private DependencyLink linkDependency(
    BoundedGraphPlan plan,
    long dependencyNode,
    long dependentNode,
    boolean executableSource,
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
    long incomingCount = plannedIncomingCount(plan, dependentNode);
    LinkPlan link = new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
    if (executableSource) {
      link = planResolvedHelperImport(dependencySource, dependentSource, incomingCount);
      if (link.valid) {} else {
        link = planSharedResolvedHelperImport(dependencySource, dependentSource, incomingCount);
      }
    } else {
      link = planPrivateResolvedConstantImport(dependencySource, dependentSource, incomingCount);
      if (link.valid) {} else {
        link = planSharedResolvedConstantImport(dependencySource, dependentSource, incomingCount);
      }
    }

    if (link.valid) {} else {
      drop(dependentSource);
      drop(dependentArena);
      drop(dependencySource);
      drop(dependencyArena);
      return new DependencyLink(0, false);
    }

    region linkedArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, link.linkedLength);
    long linkedLength = 0;
    if (executableSource) {
      linkedLength = writeCanonicalHelperImport(
        dependencySource,
        dependentSource,
        link,
        linkedBytes
      );
    } else {
      linkedLength = writeConstantImport(dependencySource, dependentSource, link, linkedBytes);
    }

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
    long helperCount = 0;
    if (executableSource) {
      helperCount = link.importedHelperCount;
    }

    return new DependencyLink(helperCount, replaced);
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
    boolean executableSource,
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
    LinkPlan link = new LinkPlan(0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, false, false);
    if (executableSource) {
      link = planResolvedHelperImport(dependencySource, rootSource, plan.rootCount);
      if (link.valid) {} else {
        link = planSharedResolvedHelperImport(dependencySource, rootSource, plan.rootCount);
      }
    } else {
      link = planResolvedConstantImport(dependencySource, rootSource, plan.rootCount);
      if (link.valid) {} else {
        link = planTrailingSharedResolvedPublicConstantImport(
          dependencySource,
          rootSource,
          plan.rootCount
        );
      }
    }

    boolean helper = executableSource;

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

  /// Executes one supported validated two- through seven-module graph.
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

    region rootStorageArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes rootStorage = allocateBytes(rootStorageArena, MAX_LINKED_SOURCE_BYTES);
    long rootLength = writeRootSource(rootSource, rootStorage);
    region ownerArena = new region(/* bytes= */ OWNER_METADATA_ARENA_BYTES, /* allocations= */ 15);
    words executableKinds = allocate(ownerArena, MAX_GRAPH_NODES);
    words executableSources = allocate(ownerArena, MAX_GRAPH_NODES);
    words helperCounts = allocate(ownerArena, MAX_GRAPH_NODES);
    words moduleStarts = allocate(ownerArena, MAX_GRAPH_NODES);
    words moduleLengths = allocate(ownerArena, MAX_GRAPH_NODES);
    words slotOwnerCounts = allocate(ownerArena, MAX_GRAPH_NODES);
    words slotOwnerNodes = allocate(ownerArena, MAX_GRAPH_NODES * MAX_GRAPH_NODES);
    words rootModuleStarts = allocate(ownerArena, MAX_GRAPH_NODES);
    words rootModuleLengths = allocate(ownerArena, MAX_GRAPH_NODES);
    words rootOwnerCount = allocate(ownerArena, 1);
    words rootOwnerNodes = allocate(ownerArena, MAX_GRAPH_NODES);
    words linkedRoots = allocate(ownerArena, MAX_GRAPH_NODES);
    words ownerStarts = allocate(ownerArena, MAX_GRAPH_NODES);
    words ownerLengths = allocate(ownerArena, MAX_GRAPH_NODES);
    words ownerCounts = allocate(ownerArena, MAX_GRAPH_NODES);
    long tableCount = plan.nodeCount;
    BoundedGraphPlan executablePlan = classifyExecutableOwners(
      plan,
      tableCount,
      storage,
      lengths,
      rootStorage,
      rootLength,
      executableKinds,
      helperCounts,
      moduleStarts,
      moduleLengths,
      slotOwnerCounts,
      slotOwnerNodes
    );
    assert(linearExecutableOwners(executablePlan));
    writeExecutableSources(executablePlan, executableKinds, executableSources);

    boolean executableSource = false;
    DependencyLink dependencyLink = new DependencyLink(0, false);
    long dependencyNode = 0;
    long dependentNode = 0;
    long incomingCount = 0;
    long reverseRank = 0;
    long dependencyRank = 0;
    long position = 0;
    while (position < executablePlan.nodeCount) limit MAX_GRAPH_NODES {
      dependencyNode = plannedNodeAt(executablePlan, position);
      if (executableSources[dependencyNode] == 0) {
        dependentNode = 0;
        while (dependentNode < executablePlan.nodeCount) limit MAX_GRAPH_NODES {
          if (plannedEdge(executablePlan, dependencyNode, dependentNode)) {
            dependencyLink = linkDependency(
              executablePlan,
              dependencyNode,
              dependentNode,
              /* executableSource= */ false,
              tableCount,
              storage,
              lengths
            );
            assert(dependencyLink.valid);
          }

          dependentNode += 1;
        }
      }

      position += 1;
    }

    position = 0;
    while (position < executablePlan.nodeCount) limit MAX_GRAPH_NODES {
      dependentNode = plannedNodeAt(executablePlan, position);
      incomingCount = plannedIncomingCount(executablePlan, dependentNode);
      reverseRank = 0;
      while (reverseRank < incomingCount) limit MAX_GRAPH_NODES {
        dependencyRank = incomingCount - reverseRank - 1;
        dependencyNode = dependencyNodeAtRank(
          executablePlan,
          dependentNode,
          dependencyRank,
          tableCount,
          storage,
          lengths
        );
        assert(0 < dependencyNode + 1);
        if (executableSources[dependencyNode] == 1) {
          assert(0 < slotOwnerCounts[dependencyNode]);
          assert(
            mergeOwnerOrders(dependencyNode, dependentNode, slotOwnerCounts, slotOwnerNodes)
          );
          dependencyLink = linkDependency(
            executablePlan,
            dependencyNode,
            dependentNode,
            /* executableSource= */ true,
            tableCount,
            storage,
            lengths
          );
          assert(dependencyLink.valid);
          assert(
            recordOwnHelperCount(
              executablePlan,
              dependencyNode,
              dependencyLink.helperCount,
              slotOwnerCounts,
              slotOwnerNodes,
              helperCounts
            )
          );
        }

        reverseRank += 1;
      }

      position += 1;
    }

    long linkedRootCount = 0;
    while (linkedRootCount < executablePlan.rootCount) limit MAX_GRAPH_NODES {
      long selectedRootNode = -1;
      boolean selectedIsHelper = false;
      long rootRank = 0;
      while (rootRank < executablePlan.rootCount) limit MAX_GRAPH_NODES {
        long candidateRootNode = rootNodeAt(executablePlan, rootRank);
        assert(0 < candidateRootNode + 1);
        if (linkedRoots[candidateRootNode] == 0) {
          if (rootDependencyReady(executablePlan, candidateRootNode, linkedRoots)) {
            boolean candidateIsHelper = 0 < slotOwnerCounts[candidateRootNode];
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

      assert(0 < selectedRootNode + 1);
      executableSource = 0 < slotOwnerCounts[selectedRootNode];
      RootDependencyLink rootLink = linkRootDependency(
        executablePlan,
        selectedRootNode,
        executableSource,
        tableCount,
        storage,
        lengths,
        rootStorage,
        rootLength
      );
      assert(rootLink.valid);
      assert(rootLink.helper == executableSource);
      rootLength = rootLink.length;
      if (rootLink.helper) {
        assert(
          recordOwnHelperCount(
            executablePlan,
            selectedRootNode,
            rootLink.helperCount,
            slotOwnerCounts,
            slotOwnerNodes,
            helperCounts
          )
        );
        if (plannedExecutable(executablePlan, selectedRootNode)) {
          set(rootModuleStarts, selectedRootNode, rootLink.ownerStart);
          set(rootModuleLengths, selectedRootNode, rootLink.ownerLength);
        }

        assert(
          prependRootOwnerOrder(
            selectedRootNode,
            slotOwnerCounts,
            slotOwnerNodes,
            rootOwnerCount,
            rootOwnerNodes
          )
        );
      }

      set(linkedRoots, selectedRootNode, 1);
      linkedRootCount += 1;
    }

    rootLength = markPrivateHelperOwners(
      rootStorage,
      rootLength,
      storage,
      moduleStarts,
      moduleLengths,
      rootModuleStarts,
      rootModuleLengths,
      rootOwnerCount,
      rootOwnerNodes
    );
    assert(-1 < rootLength);
    writeOwnerColumns(
      rootOwnerCount,
      rootOwnerNodes,
      helperCounts,
      rootModuleStarts,
      rootModuleLengths,
      ownerStarts,
      ownerLengths,
      ownerCounts
    );
    HelperOwners owners = helperOwnersFromColumns(
      ownerStarts,
      ownerLengths,
      ownerCounts,
      rootOwnerCount[0]
    );
    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 finalSource = copyRootSource(rootStorage, rootLength, finalArena);
    CoreCompilation core = compileMinimalCoreWithHelperOwners(finalSource, output, owners);
    GraphPlanExecution executed = new GraphPlanExecution(core.length, core.codeStart);
    drop(finalSource);
    drop(finalArena);
    drop(ownerCounts);
    drop(ownerLengths);
    drop(ownerStarts);
    drop(linkedRoots);
    drop(rootOwnerNodes);
    drop(rootOwnerCount);
    drop(rootModuleLengths);
    drop(rootModuleStarts);
    drop(slotOwnerNodes);
    drop(slotOwnerCounts);
    drop(moduleLengths);
    drop(moduleStarts);
    drop(helperCounts);
    drop(executableSources);
    drop(executableKinds);
    drop(ownerArena);
    drop(rootStorage);
    drop(rootStorageArena);
    drop(lengths);
    drop(storage);
    drop(tableArena);
    return executed;
  }
}
