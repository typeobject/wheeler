//! Resolves one validated seven-module graph without topology dispatch.

module wheeler.compiler.compiler_graph_seven;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.seven_imported_helpers;

classical class CompilerGraphSeven {
  /// Carries private seven-module compilation bounds.
  public record SevenGraphCompilation(long length, long codeStart) {}

  private SevenGraphCompilation compileSevenDirectHelpers(
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
    CoreCompilation compiled = compileSevenHelperOwners(
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
    return new SevenGraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one validated seven-module constant graph or direct helper set.
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
    ConstantPlanExecution execution = executeConstantPlan(
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
    if (0 < execution.length) {
      return new SevenGraphCompilation(execution.length, execution.codeStart);
    }

    if (plan.edgeCount == 0) {
      return compileSevenDirectHelpers(
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
    }

    assert(plan.valid == false);
    return compileSevenDirectHelpers(
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
  }
}
