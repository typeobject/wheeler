//! Owns source-table operations selected by one complete validated graph plan.

module wheeler.compiler.graphs.plan_sources;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.source_table;

classical class PlannedGraphSources {
  /// Copies every active physical source into one plan-counted table.
  public boolean initializePlannedSourceTable(
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
    if (plan.valid) {} else {
      return false;
    }

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

  /// Replaces one planned source only after complete source validation.
  public boolean replacePlannedSource(
    BoundedGraphPlan plan,
    long node,
    borrow utf8 replacement,
    borrow mut bytes storage,
    borrow mut words lengths
  ) {
    if (plan.valid) {} else {
      return false;
    }

    return replaceSourceTableSlot(node, plan.nodeCount, replacement, storage, lengths);
  }

  /// Copies one planned physical or linked source from the counted table.
  public utf8 copyPlannedTableSource(
    BoundedGraphPlan plan,
    long node,
    borrow mut bytes storage,
    borrow mut words lengths,
    borrow mut region arena
  ) {
    assert(plan.valid);
    long length = sourceTableSlotLength(node, plan.nodeCount, lengths);
    bytes copied = allocateBytes(arena, length);
    long written = copySourceTableSlot(node, plan.nodeCount, storage, lengths, copied);
    assert(written == length);
    return freezeUtf8(copied);
  }
}
