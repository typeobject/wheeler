//! Resolves bounded four-module trees with one transitive chain beside one direct module.

module wheeler.compiler.compiler_graph_four_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerGraphFourMixed {
  /// Carries private mixed four-module compilation bounds.
  public record MixedFourCompilation(long length, long codeStart) {}

  private MixedFourCompilation compileMixedSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new MixedFourCompilation(compiled.length, compiled.codeStart);
  }

  private MixedFourCompilation compileChainAndDirectIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new MixedFourCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, leafPlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, leafPlan, middleBytes);
    assert(middleWritten == leafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    LinkPlan dependentPlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(middleArena);
      return new MixedFourCompilation(0, 0);
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
      /* expectedImportCount= */ 2
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new MixedFourCompilation(0, 0);
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
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new MixedFourCompilation(0, 0);
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
    MixedFourCompilation compiled = compileMixedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

  private MixedFourCompilation compileFromDirectedPair(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    MixedFourCompilation compiled = compileChainAndDirectIfOrdered(
      leafSource,
      middleSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileChainAndDirectIfOrdered(
      leafSource,
      middleSource,
      secondRemainingSource,
      firstRemainingSource,
      rootSource,
      output
    );
  }

  private MixedFourCompilation compileFromPair(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    MixedFourCompilation compiled = compileFromDirectedPair(
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

    return compileFromDirectedPair(
      secondSource,
      firstSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
  }

  /// Compiles one three-edge chain beside one direct root import.
  public MixedFourCompilation compileFourChainAndDirect(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    MixedFourCompilation compiled = compileFromPair(
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
