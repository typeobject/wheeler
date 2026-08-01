//! Resolves a three-module constant chain beside two direct root modules.

module wheeler.compiler.graphs.five_long_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveLongMixed {
  private const long THREE_IMPORTS = 3;

  /// Carries private long-branch compilation bounds.
  public record FiveLongMixedCompilation(long length, long codeStart) {}

  private FiveLongMixedCompilation compileTailIfOrdered(
    borrow utf8 linkedMiddleSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan dependentPlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      return new FiveLongMixedCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, dependentPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      dependentPlan,
      dependentBytes
    );
    assert(dependentWritten == dependentPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveLongMixedCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(
      linkedDependentSource,
      rootSource,
      rootPlan,
      rootBytes
    );
    assert(rootWritten == rootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(rootBytes);

    LinkPlan firstDirectPlan = planConstantImport(
      firstDirectSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (firstDirectPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveLongMixedCompilation(0, 0);
    }

    region firstDirectArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstDirectBytes = allocateBytes(firstDirectArena, firstDirectPlan.linkedLength);
    long firstDirectWritten = writeConstantImport(
      firstDirectSource,
      firstLinkedRootSource,
      firstDirectPlan,
      firstDirectBytes
    );
    assert(firstDirectWritten == firstDirectPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(firstDirectBytes);

    LinkPlan secondDirectPlan = planConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (secondDirectPlan.valid) {} else {
      drop(secondLinkedRootSource);
      drop(firstDirectArena);
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveLongMixedCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, secondDirectPlan.linkedLength);
    long finalWritten = writeConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      secondDirectPlan,
      finalBytes
    );
    assert(finalWritten == secondDirectPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(firstDirectArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return new FiveLongMixedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one exact planned chain beside direct imports.
  public FiveLongMixedCompilation compileFiveLongChainAndDirectsIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan middlePlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (middlePlan.valid) {} else {
      return new FiveLongMixedCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, middlePlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, middlePlan, middleBytes);
    assert(middleWritten == middlePlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    FiveLongMixedCompilation compiled = compileTailIfOrdered(
      linkedMiddleSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );

    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

}
