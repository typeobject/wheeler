//! Resolves one validated seven-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_seven;

import wheeler.compiler.graphs.executor;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.seven.plans;

classical class SevenGraphCoordinator {
  /// Carries private seven-module compilation bounds.
  public record SevenGraphCompilation(long length, long codeStart) {}

  /// Compiles one validated seven-module graph.
  public SevenGraphCompilation compileSevenConstantGraph(
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
    BoundedGraphPlan plan = planSevenBoundedGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource
    );
    assert(plan.valid);
    GraphPlanExecution execution = executeGraphPlan(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      rootSource,
      output
    );
    assert(0 < execution.length);
    return new SevenGraphCompilation(execution.length, execution.codeStart);
  }
}
