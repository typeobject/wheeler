//! Resolves bounded module graphs before canonical lowering.

module wheeler.compiler.compiler_graphs;

import wheeler.compiler.compiler_core;
import wheeler.compiler.compiler_graph_five;
import wheeler.compiler.compiler_graph_four;
import wheeler.compiler.compiler_graph_seven;
import wheeler.compiler.compiler_graph_six;
import wheeler.compiler.graphs.executor;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.small_structures;
import wheeler.compiler.helper_owners;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class CompilerGraphs {
  /// Carries private graph-compilation bounds across the driver boundary.
  public record GraphCompilation(long length, long codeStart) {}

  private GraphCompilation compileGraphSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  private GraphCompilation compileGraphSourceWithHelperImport(
    borrow utf8 source,
    borrow mut bytes output,
    LinkPlan plan
  ) {
    HelperOwner imported = importedHelperOwner(
      plan.linkedOwnerStart,
      plan.linkedOwnerLength,
      plan.importedHelperCount
    );
    CoreCompilation compiled = compileMinimalCoreWithHelperOwners(
      source,
      output,
      oneHelperOwner(imported)
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one root with one direct scalar-constant or scalar-helper module.
  public GraphCompilation compileGraphWithConstantImport(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan plan = planConstantImport(importedSource, rootSource, /* expectedImportCount= */ 1);
    boolean importedHelpers = false;
    if (plan.valid) {} else {
      plan = planResolvedHelperImport(importedSource, rootSource, /* expectedImportCount= */ 1);
      importedHelpers = plan.valid;
    }

    assert(plan.valid);
    region linkedArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes linkedBytes = allocateBytes(linkedArena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    utf8 linkedSource = freezeUtf8(linkedBytes);
    GraphCompilation compiled = new GraphCompilation(0, 0);
    if (importedHelpers) {
      compiled = compileGraphSourceWithHelperImport(linkedSource, output, plan);
    } else {
      compiled = compileGraphSource(linkedSource, output);
    }

    drop(linkedSource);
    drop(linkedArena);
    return compiled;
  }

  /// Compiles one complete validated two-module graph without topology dispatch.
  public GraphCompilation compileGraphWithConstantImports(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planTwoGraph(firstSource, secondSource, rootSource);
    assert(plan.valid);
    GraphPlanExecution execution = executeGraphPlan(
      plan,
      firstSource,
      secondSource,
      secondSource,
      secondSource,
      secondSource,
      secondSource,
      secondSource,
      rootSource,
      output
    );
    assert(0 < execution.length);
    return new GraphCompilation(execution.length, execution.codeStart);
  }

  /// Compiles one complete validated three-module graph without topology dispatch.
  public GraphCompilation compileGraphWithThreeConstantImports(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BoundedGraphPlan plan = planThreeGraph(firstSource, secondSource, thirdSource, rootSource);
    assert(plan.valid);
    GraphPlanExecution execution = executeGraphPlan(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      thirdSource,
      thirdSource,
      thirdSource,
      thirdSource,
      rootSource,
      output
    );
    assert(0 < execution.length);
    return new GraphCompilation(execution.length, execution.codeStart);
  }

  /// Compiles one validated six-module graph and its root.
  public GraphCompilation compileGraphWithSixConstantImports(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixGraphCompilation compiled = compileSixConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one validated seven-module graph and its root.
  public GraphCompilation compileGraphWithSevenConstantImports(
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
    SevenGraphCompilation compiled = compileSevenConstantGraph(
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
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one validated five-module graph and its root.
  public GraphCompilation compileGraphWithFiveConstantImports(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveGraphCompilation compiled = compileFiveConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one validated four-module graph and its root.
  public GraphCompilation compileGraphWithFourConstantImports(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FourGraphCompilation compiled = compileFourConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    return new GraphCompilation(compiled.length, compiled.codeStart);
  }
}
