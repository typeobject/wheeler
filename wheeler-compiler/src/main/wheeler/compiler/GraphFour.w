//! Resolves one validated four-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_four;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.four_structures;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.multiple_imported_helpers;

classical class CompilerGraphFour {
  /// Carries private four-module compilation bounds.
  public record FourGraphCompilation(long length, long codeStart) {}

  private FourGraphCompilation compileFourDirectHelpers(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    CoreCompilation compiled = compileFourHelperOwners(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    return new FourGraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one validated four-module constant graph or direct helper set.
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
    ConstantPlanExecution execution = executeConstantPlan(
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
    if (0 < execution.length) {
      return new FourGraphCompilation(execution.length, execution.codeStart);
    }

    if (plan.edgeCount == 0) {
      return compileFourDirectHelpers(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        rootSource,
        output
      );
    }

    assert(plan.valid == false);
    return compileFourDirectHelpers(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
  }
}
