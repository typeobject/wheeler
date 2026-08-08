//! Resolves one validated six-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_six;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.six.plans;
import wheeler.compiler.six_imported_helpers;

classical class CompilerGraphSix {
  /// Carries private six-module compilation bounds.
  public record SixGraphCompilation(long length, long codeStart) {}

  private SixGraphCompilation compileSixDirectHelpers(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    CoreCompilation compiled = compileSixHelperOwners(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    return new SixGraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one validated six-module constant graph or direct helper set.
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
    ConstantPlanExecution execution = executeConstantPlan(
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
    if (0 < execution.length) {
      return new SixGraphCompilation(execution.length, execution.codeStart);
    }

    if (plan.edgeCount == 0) {
      return compileSixDirectHelpers(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource,
        output
      );
    }

    assert(plan.valid == false);
    return compileSixDirectHelpers(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
  }
}
