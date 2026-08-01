//! Resolves a four-module constant chain beside one direct root module.

module wheeler.compiler.graphs.five_deep_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveDeepMixed {
  private const long TWO_IMPORTS = 2;

  /// Carries private deep-branch compilation bounds.
  public record FiveDeepMixedCompilation(long length, long codeStart) {}

  private FiveDeepMixedCompilation compileTailIfOrdered(
    borrow utf8 linkedSecondSource,
    borrow utf8 thirdSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan thirdPlan = planPrivateResolvedConstantImport(
      linkedSecondSource,
      thirdSource,
      /* expectedImportCount= */ 1
    );
    if (thirdPlan.valid) {} else {
      return new FiveDeepMixedCompilation(0, 0);
    }

    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      linkedSecondSource,
      thirdSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 linkedThirdSource = freezeUtf8(thirdBytes);

    LinkPlan dependentPlan = planPrivateResolvedConstantImport(
      linkedThirdSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      drop(linkedThirdSource);
      drop(thirdArena);
      return new FiveDeepMixedCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, dependentPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedThirdSource,
      dependentSource,
      dependentPlan,
      dependentBytes
    );
    assert(dependentWritten == dependentPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedThirdSource);
      drop(thirdArena);
      return new FiveDeepMixedCompilation(0, 0);
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

    LinkPlan directPlan = planConstantImport(
      directSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (directPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedThirdSource);
      drop(thirdArena);
      return new FiveDeepMixedCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      firstLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    drop(linkedThirdSource);
    drop(thirdArena);
    return new FiveDeepMixedCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one exact planned chain beside direct imports.
  public FiveDeepMixedCompilation compileFiveDeepChainAndDirectIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 secondSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan secondPlan = planPrivateConstantImport(
      leafSource,
      secondSource,
      /* expectedImportCount= */ 1
    );
    if (secondPlan.valid) {} else {
      return new FiveDeepMixedCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(leafSource, secondSource, secondPlan, secondBytes);
    assert(secondWritten == secondPlan.linkedLength);
    utf8 linkedSecondSource = freezeUtf8(secondBytes);

    FiveDeepMixedCompilation compiled = compileTailIfOrdered(
      linkedSecondSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );

    drop(linkedSecondSource);
    drop(secondArena);
    return compiled;
  }

}
