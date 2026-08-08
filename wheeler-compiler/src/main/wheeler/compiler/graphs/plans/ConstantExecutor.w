//! Executes rooted constant forests through one counted source table.

module wheeler.compiler.graphs.constant_executor;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.source_table;
import wheeler.compiler.module_linker;

classical class BoundedConstantPlanExecutor {
  private const long MAX_GRAPH_NODES = 7;
  private const long MAX_LINKED_SOURCE_BYTES = 32768;

  /// Carries one bounded constant-plan execution result.
  public record ConstantPlanExecution(long length, long codeStart) {}

  private ConstantPlanExecution failedExecution() {
    return new ConstantPlanExecution(0, 0);
  }

  private boolean directOrForest(BoundedGraphPlan plan) {
    if (plan.valid) {} else {
      return false;
    }

    return plan.edgeCount + plan.rootCount == plan.nodeCount;
  }

  private boolean initializeExecutionTable(
    BoundedGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    if (plan.nodeCount == 2) {
      return initializeSourceTable(
        3,
        firstSource,
        secondSource,
        rootSource,
        rootSource,
        rootSource,
        rootSource,
        rootSource,
        storage,
        lengths
      );
    }

    if (plan.nodeCount == 3) {
      return initializeSourceTable(
        4,
        firstSource,
        secondSource,
        thirdSource,
        rootSource,
        rootSource,
        rootSource,
        rootSource,
        storage,
        lengths
      );
    }

    if (plan.nodeCount == 4) {
      return initializeSourceTable(
        5,
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        rootSource,
        rootSource,
        rootSource,
        storage,
        lengths
      );
    }

    return false;
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

  private boolean linkRootDependency(
    BoundedGraphPlan plan,
    long dependencyNode,
    long rootNode,
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
    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 rootSource = copyExecutionSource(rootNode, tableCount, storage, lengths, rootArena);
    LinkPlan link = planResolvedConstantImport(dependencySource, rootSource, plan.rootCount);
    if (link.valid) {} else {
      drop(rootSource);
      drop(rootArena);
      drop(dependencySource);
      drop(dependencyArena);
      return false;
    }

    region linkedArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, link.linkedLength);
    long linkedLength = writeConstantImport(dependencySource, rootSource, link, linkedBytes);
    assert(linkedLength == link.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    boolean replaced = replaceSourceTableSlot(
      rootNode,
      tableCount,
      linkedSource,
      storage,
      lengths
    );
    drop(linkedSource);
    drop(linkedArena);
    drop(rootSource);
    drop(rootArena);
    drop(dependencySource);
    drop(dependencyArena);
    return replaced;
  }

  /// Executes one rooted two- through four-module constant forest.
  public ConstantPlanExecution executeConstantPlan(
    BoundedGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    if (directOrForest(plan)) {} else {
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
      rootSource,
      storage,
      lengths
    );
    if (initialized) {} else {
      drop(lengths);
      drop(storage);
      drop(tableArena);
      return failedExecution();
    }

    long tableCount = plan.nodeCount + 1;
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

    long rootNode = plan.nodeCount;
    long rank = 0;
    while (rank < plan.rootCount) limit MAX_GRAPH_NODES {
      long rootDependencyNode = rootNodeAt(plan, rank);
      if (0 < rootDependencyNode + 1) {} else {
        drop(lengths);
        drop(storage);
        drop(tableArena);
        return failedExecution();
      }

      if (
        linkRootDependency(plan, rootDependencyNode, rootNode, tableCount, storage, lengths)
      ) {} else {
        drop(lengths);
        drop(storage);
        drop(tableArena);
        return failedExecution();
      }

      rank += 1;
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 finalSource = copyExecutionSource(rootNode, tableCount, storage, lengths, finalArena);
    CoreCompilation core = compileMinimalCore(finalSource, output);
    ConstantPlanExecution executed = new ConstantPlanExecution(core.length, core.codeStart);
    drop(finalSource);
    drop(finalArena);
    drop(lengths);
    drop(storage);
    drop(tableArena);
    return executed;
  }
}
