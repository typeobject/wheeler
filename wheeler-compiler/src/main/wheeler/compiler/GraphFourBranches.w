//! Resolves bounded four-module trees with one short chain and two direct modules.

module wheeler.compiler.compiler_graph_four_branches;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerGraphFourBranches {
  /// Carries private branched four-module compilation bounds.
  public record BranchedFourCompilation(long length, long codeStart) {}

  private BranchedFourCompilation compileBranchedSource(
    borrow utf8 source,
    borrow mut bytes output
  ) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new BranchedFourCompilation(compiled.length, compiled.codeStart);
  }

  private BranchedFourCompilation compileChainAndTwoDirectIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new BranchedFourCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, leafPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      leafPlan,
      dependentBytes
    );
    assert(dependentWritten == leafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 3
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      return new BranchedFourCompilation(0, 0);
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
      /* expectedImportCount= */ 3
    );
    if (firstDirectPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new BranchedFourCompilation(0, 0);
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
      /* expectedImportCount= */ 3
    );
    if (secondDirectPlan.valid) {} else {
      drop(secondLinkedRootSource);
      drop(firstDirectArena);
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new BranchedFourCompilation(0, 0);
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
    BranchedFourCompilation compiled = compileBranchedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(firstDirectArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return compiled;
  }

  private BranchedFourCompilation compileFromPair(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BranchedFourCompilation compiled = compileChainAndTwoDirectIfOrdered(
      firstSource,
      secondSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileChainAndTwoDirectIfOrdered(
      secondSource,
      firstSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
  }

  /// Compiles one two-edge chain beside two direct root imports.
  public BranchedFourCompilation compileFourChainAndTwoDirect(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    BranchedFourCompilation compiled = compileFromPair(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromPair(
      firstSource,
      thirdSource,
      secondSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromPair(
      firstSource,
      fourthSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromPair(
      secondSource,
      thirdSource,
      firstSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromPair(
      secondSource,
      fourthSource,
      firstSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileFromPair(
      thirdSource,
      fourthSource,
      firstSource,
      secondSource,
      rootSource,
      output
    );
  }
}
