//! Resolves one validated five-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_five;

import wheeler.compiler.graphs.executor;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.plans;

classical class CompilerGraphFive {
  /// Carries private five-module compilation bounds.
  public record FiveGraphCompilation(long length, long codeStart) {}

  /// Compiles one validated five-module graph.
  public FiveGraphCompilation compileFiveConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planFiveConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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
      fifthSource,
      fifthSource,
      rootSource,
      output
    );
    assert(0 < execution.length);
    return new FiveGraphCompilation(execution.length, execution.codeStart);
  }
}
