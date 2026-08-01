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

  /// Compiles one exact planned chain beside two direct imports.
  public BranchedFourCompilation compileChainAndTwoDirectIfOrdered(
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

  /// Compiles one exact planned pair of chains.
  public BranchedFourCompilation compileTwoChainsIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondDependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstLeafPlan.valid) {} else {
      return new BranchedFourCompilation(0, 0);
    }

    region firstDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstDependentBytes = allocateBytes(firstDependentArena, firstLeafPlan.linkedLength);
    long firstDependentWritten = writeConstantImport(
      firstLeafSource,
      firstDependentSource,
      firstLeafPlan,
      firstDependentBytes
    );
    assert(firstDependentWritten == firstLeafPlan.linkedLength);
    utf8 linkedFirstDependentSource = freezeUtf8(firstDependentBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    if (secondLeafPlan.valid) {} else {
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new BranchedFourCompilation(0, 0);
    }

    region secondDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondDependentBytes = allocateBytes(secondDependentArena, secondLeafPlan.linkedLength);
    long secondDependentWritten = writeConstantImport(
      secondLeafSource,
      secondDependentSource,
      secondLeafPlan,
      secondDependentBytes
    );
    assert(secondDependentWritten == secondLeafPlan.linkedLength);
    utf8 linkedSecondDependentSource = freezeUtf8(secondDependentBytes);

    LinkPlan firstRootPlan = planResolvedConstantImport(
      linkedFirstDependentSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (firstRootPlan.valid) {} else {
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new BranchedFourCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, firstRootPlan.linkedLength);
    long firstRootWritten = writeConstantImport(
      linkedFirstDependentSource,
      rootSource,
      firstRootPlan,
      rootBytes
    );
    assert(firstRootWritten == firstRootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(rootBytes);

    LinkPlan secondRootPlan = planResolvedConstantImport(
      linkedSecondDependentSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ 2
    );
    if (secondRootPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new BranchedFourCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, secondRootPlan.linkedLength);
    long finalWritten = writeConstantImport(
      linkedSecondDependentSource,
      firstLinkedRootSource,
      secondRootPlan,
      finalBytes
    );
    assert(finalWritten == secondRootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    BranchedFourCompilation compiled = compileBranchedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedSecondDependentSource);
    drop(secondDependentArena);
    drop(linkedFirstDependentSource);
    drop(firstDependentArena);
    return compiled;
  }

  /// Compiles one exact planned fork beside one direct import.
  public BranchedFourCompilation compileForkAndDirectIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ 2
    );
    if (firstLeafPlan.valid) {} else {
      return new BranchedFourCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstLeafPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstLeafSource,
      dependentSource,
      firstLeafPlan,
      firstBytes
    );
    assert(firstWritten == firstLeafPlan.linkedLength);
    utf8 firstLinkedDependentSource = freezeUtf8(firstBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedDependentSource,
      /* expectedImportCount= */ 2
    );
    if (secondLeafPlan.valid) {} else {
      drop(firstLinkedDependentSource);
      drop(firstArena);
      return new BranchedFourCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondLeafPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedDependentSource,
      secondLeafPlan,
      secondBytes
    );
    assert(secondWritten == secondLeafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(secondBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 2
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(secondArena);
      drop(firstLinkedDependentSource);
      drop(firstArena);
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

    LinkPlan directPlan = planConstantImport(
      directSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ 2
    );
    if (directPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(secondArena);
      drop(firstLinkedDependentSource);
      drop(firstArena);
      return new BranchedFourCompilation(0, 0);
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
    BranchedFourCompilation compiled = compileBranchedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(secondArena);
    drop(firstLinkedDependentSource);
    drop(firstArena);
    return compiled;
  }

}
