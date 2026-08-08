//! Resolves one validated four-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_four;

import wheeler.compiler.graphs.executor;
import wheeler.compiler.graphs.four_structures;
import wheeler.compiler.graphs.matrix;

classical class CompilerGraphFour {
  /// Carries private four-module compilation bounds.
  public record FourGraphCompilation(long length, long codeStart) {}

  /// Compiles one validated four-module graph.
  public FourGraphCompilation compileFourConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planFourGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource
    );
    assert(plan.valid);
    GraphPlanExecution execution = executeGraphPlan(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fourthSource,
      fourthSource,
      fourthSource,
      rootSource,
      output
    );
    assert(0 < execution.length);
    return new FourGraphCompilation(execution.length, execution.codeStart);
  }
}
