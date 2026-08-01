//! Resolves the first shared-dependency four-module constant DAG.

module wheeler.compiler.compiler_graph_four_dag;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerGraphFourDag {
  /// Carries private four-module DAG compilation bounds.
  public record FourDagCompilation(long length, long codeStart) {}

  private FourDagCompilation compileDagSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new FourDagCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one exact planned diamond role order.
  public FourDagCompilation compileDiamondIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondDependentSource,
    borrow utf8 joinSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      leafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstLeafPlan.valid) {} else {
      return new FourDagCompilation(0, 0);
    }

    region firstDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstDependentBytes = allocateBytes(firstDependentArena, firstLeafPlan.linkedLength);
    long firstDependentWritten = writeConstantImport(
      leafSource,
      firstDependentSource,
      firstLeafPlan,
      firstDependentBytes
    );
    assert(firstDependentWritten == firstLeafPlan.linkedLength);
    utf8 linkedFirstDependentSource = freezeUtf8(firstDependentBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      leafSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    if (secondLeafPlan.valid) {} else {
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FourDagCompilation(0, 0);
    }

    region secondDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondDependentBytes = allocateBytes(secondDependentArena, secondLeafPlan.linkedLength);
    long secondDependentWritten = writeConstantImport(
      leafSource,
      secondDependentSource,
      secondLeafPlan,
      secondDependentBytes
    );
    assert(secondDependentWritten == secondLeafPlan.linkedLength);
    utf8 linkedSecondDependentSource = freezeUtf8(secondDependentBytes);

    LinkPlan firstJoinPlan = planPrivateResolvedConstantImport(
      linkedFirstDependentSource,
      joinSource,
      /* expectedImportCount= */ 2
    );
    if (firstJoinPlan.valid) {} else {
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FourDagCompilation(0, 0);
    }

    region joinArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes joinBytes = allocateBytes(joinArena, firstJoinPlan.linkedLength);
    long firstJoinWritten = writeConstantImport(
      linkedFirstDependentSource,
      joinSource,
      firstJoinPlan,
      joinBytes
    );
    assert(firstJoinWritten == firstJoinPlan.linkedLength);
    utf8 firstLinkedJoinSource = freezeUtf8(joinBytes);

    LinkPlan secondJoinPlan = planSharedResolvedConstantImport(
      linkedSecondDependentSource,
      firstLinkedJoinSource,
      /* expectedImportCount= */ 2
    );
    if (secondJoinPlan.valid) {} else {
      drop(firstLinkedJoinSource);
      drop(joinArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FourDagCompilation(0, 0);
    }

    region linkedJoinArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes linkedJoinBytes = allocateBytes(linkedJoinArena, secondJoinPlan.linkedLength);
    long secondJoinWritten = writeConstantImport(
      linkedSecondDependentSource,
      firstLinkedJoinSource,
      secondJoinPlan,
      linkedJoinBytes
    );
    assert(secondJoinWritten == secondJoinPlan.linkedLength);
    utf8 linkedJoinSource = freezeUtf8(linkedJoinBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedJoinSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedJoinSource);
      drop(linkedJoinArena);
      drop(firstLinkedJoinSource);
      drop(joinArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FourDagCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(linkedJoinSource, rootSource, rootPlan, rootBytes);
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    FourDagCompilation compiled = compileDagSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedJoinSource);
    drop(linkedJoinArena);
    drop(firstLinkedJoinSource);
    drop(joinArena);
    drop(linkedSecondDependentSource);
    drop(secondDependentArena);
    drop(linkedFirstDependentSource);
    drop(firstDependentArena);
    return compiled;
  }

}
