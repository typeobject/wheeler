//! Resolves one validated six-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_six;

import wheeler.compiler.graphs.executor;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.six.plans;

classical class CompilerGraphSix {
  /// Carries private six-module compilation bounds.
  public record SixGraphCompilation(long length, long codeStart) {}

  /// Compiles one validated six-module graph.
  public SixGraphCompilation compileSixConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planSixConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
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
      sixthSource,
      rootSource,
      output
    );
    assert(0 < execution.length);
    return new SixGraphCompilation(execution.length, execution.codeStart);
  }
}
