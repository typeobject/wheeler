//! Copies one source selected by a complete validated graph plan.

module wheeler.compiler.graphs.plan_sources;

import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.sources;

classical class PlannedGraphSources {
  /// Copies one node into caller-owned bounded storage.
  public utf8 copyPlannedSource(
    BoundedGraphPlan plan,
    long node,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow mut region arena
  ) {
    assert(plan.valid);
    return copySelectedSource(
      node,
      plan.nodeCount,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      arena
    );
  }
}
