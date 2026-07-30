//! Links one six-module scalar-constant chain without source-order authority.

module wheeler.compiler.graphs.six.chain;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class SixConstantChain {
  /// Carries one attempted six-module chain compilation.
  public record SixChainCompilation(long length, long codeStart) {}

  private SixChainCompilation compileChainRoot(
    borrow utf8 linkedSixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan rootPlan = planResolvedConstantImport(
      linkedSixthSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      return new SixChainCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(linkedSixthSource, rootSource, rootPlan, rootBytes);
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    return new SixChainCompilation(compiled.length, compiled.codeStart);
  }

  private SixChainCompilation compileChainLast(
    borrow utf8 linkedFifthSource,
    borrow utf8 lastSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan lastPlan = planPrivateResolvedConstantImport(
      linkedFifthSource,
      lastSource,
      /* expectedImportCount= */ 1
    );
    if (lastPlan.valid) {} else {
      return new SixChainCompilation(0, 0);
    }

    region lastArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes lastBytes = allocateBytes(lastArena, lastPlan.linkedLength);
    long lastWritten = writeConstantImport(linkedFifthSource, lastSource, lastPlan, lastBytes);
    assert(lastWritten == lastPlan.linkedLength);
    utf8 linkedLastSource = freezeUtf8(lastBytes);
    SixChainCompilation compiled = compileChainRoot(linkedLastSource, rootSource, output);
    drop(linkedLastSource);
    drop(lastArena);
    return compiled;
  }

  private SixChainCompilation compileNextOfTwo(
    borrow utf8 linkedFourthSource,
    borrow utf8 nextSource,
    borrow utf8 lastSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan nextPlan = planPrivateResolvedConstantImport(
      linkedFourthSource,
      nextSource,
      /* expectedImportCount= */ 1
    );
    if (nextPlan.valid) {} else {
      return new SixChainCompilation(0, 0);
    }

    region nextArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes nextBytes = allocateBytes(nextArena, nextPlan.linkedLength);
    long nextWritten = writeConstantImport(linkedFourthSource, nextSource, nextPlan, nextBytes);
    assert(nextWritten == nextPlan.linkedLength);
    utf8 linkedNextSource = freezeUtf8(nextBytes);
    SixChainCompilation compiled = compileChainLast(
      linkedNextSource,
      lastSource,
      rootSource,
      output
    );
    drop(linkedNextSource);
    drop(nextArena);
    return compiled;
  }

  private SixChainCompilation compileTailTwo(
    borrow utf8 linkedFourthSource,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixChainCompilation compiled = compileNextOfTwo(
      linkedFourthSource,
      firstSource,
      secondSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileNextOfTwo(linkedFourthSource, secondSource, firstSource, rootSource, output);
  }

  private SixChainCompilation compileNextOfThree(
    borrow utf8 linkedThirdSource,
    borrow utf8 nextSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan nextPlan = planPrivateResolvedConstantImport(
      linkedThirdSource,
      nextSource,
      /* expectedImportCount= */ 1
    );
    if (nextPlan.valid) {} else {
      return new SixChainCompilation(0, 0);
    }

    region nextArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes nextBytes = allocateBytes(nextArena, nextPlan.linkedLength);
    long nextWritten = writeConstantImport(linkedThirdSource, nextSource, nextPlan, nextBytes);
    assert(nextWritten == nextPlan.linkedLength);
    utf8 linkedNextSource = freezeUtf8(nextBytes);
    SixChainCompilation compiled = compileTailTwo(
      linkedNextSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    drop(linkedNextSource);
    drop(nextArena);
    return compiled;
  }

  private SixChainCompilation compileTailThree(
    borrow utf8 linkedThirdSource,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixChainCompilation compiled = compileNextOfThree(
      linkedThirdSource,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileNextOfThree(
      linkedThirdSource,
      secondSource,
      firstSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileNextOfThree(
      linkedThirdSource,
      thirdSource,
      firstSource,
      secondSource,
      rootSource,
      output
    );
  }

  private SixChainCompilation compileNextOfFour(
    borrow utf8 linkedSecondSource,
    borrow utf8 nextSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan nextPlan = planPrivateResolvedConstantImport(
      linkedSecondSource,
      nextSource,
      /* expectedImportCount= */ 1
    );
    if (nextPlan.valid) {} else {
      return new SixChainCompilation(0, 0);
    }

    region nextArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes nextBytes = allocateBytes(nextArena, nextPlan.linkedLength);
    long nextWritten = writeConstantImport(linkedSecondSource, nextSource, nextPlan, nextBytes);
    assert(nextWritten == nextPlan.linkedLength);
    utf8 linkedNextSource = freezeUtf8(nextBytes);
    SixChainCompilation compiled = compileTailThree(
      linkedNextSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    drop(linkedNextSource);
    drop(nextArena);
    return compiled;
  }

  private SixChainCompilation compileTailFour(
    borrow utf8 linkedSecondSource,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixChainCompilation compiled = compileNextOfFour(
      linkedSecondSource,
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

    compiled = compileNextOfFour(
      linkedSecondSource,
      secondSource,
      firstSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileNextOfFour(
      linkedSecondSource,
      thirdSource,
      firstSource,
      secondSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileNextOfFour(
      linkedSecondSource,
      fourthSource,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
  }

  private SixChainCompilation compileFromDirectedPair(
    borrow utf8 leafSource,
    borrow utf8 secondSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 fourthRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan secondPlan = planPrivateConstantImport(
      leafSource,
      secondSource,
      /* expectedImportCount= */ 1
    );
    if (secondPlan.valid) {} else {
      return new SixChainCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(leafSource, secondSource, secondPlan, secondBytes);
    assert(secondWritten == secondPlan.linkedLength);
    utf8 linkedSecondSource = freezeUtf8(secondBytes);
    SixChainCompilation compiled = compileTailFour(
      linkedSecondSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    drop(linkedSecondSource);
    drop(secondArena);
    return compiled;
  }

  private SixChainCompilation compileFromLeaf(
    borrow utf8 leafSource,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixChainCompilation compiled = compileFromDirectedPair(
      leafSource,
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

    compiled = compileFromDirectedPair(
      leafSource,
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

    compiled = compileFromDirectedPair(
      leafSource,
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

    compiled = compileFromDirectedPair(
      leafSource,
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

    return compileFromDirectedPair(
      leafSource,
      fifthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
  }

  /// Compiles one six-module chain independent of source order.
  public SixChainCompilation compileSixConstantChain(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixChainCompilation compiled = compileFromLeaf(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromLeaf(
      secondSource,
      firstSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromLeaf(
      thirdSource,
      firstSource,
      secondSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromLeaf(
      fourthSource,
      firstSource,
      secondSource,
      thirdSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFromLeaf(
      fifthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      sixthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileFromLeaf(
      sixthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
  }
}
