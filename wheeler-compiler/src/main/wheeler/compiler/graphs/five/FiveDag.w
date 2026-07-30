//! Resolves a shared constant diamond with one side leaf at the join.

module wheeler.compiler.graphs.five_dag;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveDag {
  private const long THREE_IMPORTS = 3;

  /// Carries private five-module DAG compilation bounds.
  public record FiveDagCompilation(long length, long codeStart) {}

  private FiveDagCompilation compileIfOrdered(
    borrow utf8 sharedLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondDependentSource,
    borrow utf8 joinSource,
    borrow utf8 sideLeafSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      sharedLeafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstLeafPlan.valid) {} else {
      return new FiveDagCompilation(0, 0);
    }

    region firstDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstDependentBytes = allocateBytes(firstDependentArena, firstLeafPlan.linkedLength);
    long firstDependentWritten = writeConstantImport(
      sharedLeafSource,
      firstDependentSource,
      firstLeafPlan,
      firstDependentBytes
    );
    assert(firstDependentWritten == firstLeafPlan.linkedLength);
    utf8 linkedFirstDependentSource = freezeUtf8(firstDependentBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      sharedLeafSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    if (secondLeafPlan.valid) {} else {
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FiveDagCompilation(0, 0);
    }

    region secondDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondDependentBytes = allocateBytes(secondDependentArena, secondLeafPlan.linkedLength);
    long secondDependentWritten = writeConstantImport(
      sharedLeafSource,
      secondDependentSource,
      secondLeafPlan,
      secondDependentBytes
    );
    assert(secondDependentWritten == secondLeafPlan.linkedLength);
    utf8 linkedSecondDependentSource = freezeUtf8(secondDependentBytes);

    LinkPlan firstJoinPlan = planPrivateResolvedConstantImport(
      linkedFirstDependentSource,
      joinSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (firstJoinPlan.valid) {} else {
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FiveDagCompilation(0, 0);
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
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (secondJoinPlan.valid) {} else {
      drop(firstLinkedJoinSource);
      drop(joinArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FiveDagCompilation(0, 0);
    }

    region secondJoinArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondJoinBytes = allocateBytes(secondJoinArena, secondJoinPlan.linkedLength);
    long secondJoinWritten = writeConstantImport(
      linkedSecondDependentSource,
      firstLinkedJoinSource,
      secondJoinPlan,
      secondJoinBytes
    );
    assert(secondJoinWritten == secondJoinPlan.linkedLength);
    utf8 secondLinkedJoinSource = freezeUtf8(secondJoinBytes);

    LinkPlan sideLeafPlan = planPrivateConstantImport(
      sideLeafSource,
      secondLinkedJoinSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (sideLeafPlan.valid) {} else {
      drop(secondLinkedJoinSource);
      drop(secondJoinArena);
      drop(firstLinkedJoinSource);
      drop(joinArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FiveDagCompilation(0, 0);
    }

    region linkedJoinArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes linkedJoinBytes = allocateBytes(linkedJoinArena, sideLeafPlan.linkedLength);
    long sideLeafWritten = writeConstantImport(
      sideLeafSource,
      secondLinkedJoinSource,
      sideLeafPlan,
      linkedJoinBytes
    );
    assert(sideLeafWritten == sideLeafPlan.linkedLength);
    utf8 linkedJoinSource = freezeUtf8(linkedJoinBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedJoinSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedJoinSource);
      drop(linkedJoinArena);
      drop(secondLinkedJoinSource);
      drop(secondJoinArena);
      drop(firstLinkedJoinSource);
      drop(joinArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FiveDagCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(linkedJoinSource, rootSource, rootPlan, rootBytes);
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedJoinSource);
    drop(linkedJoinArena);
    drop(secondLinkedJoinSource);
    drop(secondJoinArena);
    drop(firstLinkedJoinSource);
    drop(joinArena);
    drop(linkedSecondDependentSource);
    drop(secondDependentArena);
    drop(linkedFirstDependentSource);
    drop(firstDependentArena);
    return new FiveDagCompilation(compiled.length, compiled.codeStart);
  }

  private FiveDagCompilation compileRemainder(
    borrow utf8 sharedLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondDependentSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveDagCompilation compiled = compileIfOrdered(
      sharedLeafSource,
      firstDependentSource,
      secondDependentSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileIfOrdered(
      sharedLeafSource,
      firstDependentSource,
      secondDependentSource,
      secondRemainingSource,
      firstRemainingSource,
      rootSource,
      output
    );
  }

  private FiveDagCompilation compileWithSharedLeaf(
    borrow utf8 sharedLeafSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 fourthRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveDagCompilation compiled = compileRemainder(
      sharedLeafSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      sharedLeafSource,
      firstRemainingSource,
      thirdRemainingSource,
      secondRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      sharedLeafSource,
      firstRemainingSource,
      fourthRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      sharedLeafSource,
      secondRemainingSource,
      thirdRemainingSource,
      firstRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      sharedLeafSource,
      secondRemainingSource,
      fourthRemainingSource,
      firstRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileRemainder(
      sharedLeafSource,
      thirdRemainingSource,
      fourthRemainingSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
  }

  /// Compiles a shared diamond with one direct side leaf at its join.
  public FiveDagCompilation compileFiveSharedDiamond(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveDagCompilation compiled = compileWithSharedLeaf(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileWithSharedLeaf(
      secondSource,
      firstSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileWithSharedLeaf(
      thirdSource,
      firstSource,
      secondSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileWithSharedLeaf(
      fourthSource,
      firstSource,
      secondSource,
      thirdSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileWithSharedLeaf(
      fifthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
  }
}
