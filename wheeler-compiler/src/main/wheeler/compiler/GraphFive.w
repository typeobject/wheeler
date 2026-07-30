//! Resolves the first bounded five-module constant graph before canonical lowering.

module wheeler.compiler.compiler_graph_five;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.five_branches;
import wheeler.compiler.graphs.five_fork;
import wheeler.compiler.graphs.five_fork_mixed;
import wheeler.compiler.graphs.five_mixed;
import wheeler.compiler.graphs.plans;
import wheeler.compiler.module_linker;

classical class CompilerGraphFive {
  private const long FIVE_IMPORTS = 5;
  private const long INVALID_COMPILATION_LENGTH = 0;
  private const long VALID_COMPILATION_LENGTH = 1;

  /// Carries private five-module compilation bounds.
  public record FiveGraphCompilation(long length, long codeStart) {}

  private FiveGraphCompilation compileFiveChainTailIfOrdered(
    borrow utf8 linkedSecondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan thirdPlan = planPrivateResolvedConstantImport(
      linkedSecondSource,
      thirdSource,
      /* expectedImportCount= */ 1
    );
    if (thirdPlan.valid) {} else {
      return new FiveGraphCompilation(0, 0);
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

    LinkPlan fourthPlan = planPrivateResolvedConstantImport(
      linkedThirdSource,
      fourthSource,
      /* expectedImportCount= */ 1
    );
    if (fourthPlan.valid) {} else {
      drop(linkedThirdSource);
      drop(thirdArena);
      return new FiveGraphCompilation(0, 0);
    }

    region fourthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeConstantImport(
      linkedThirdSource,
      fourthSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 linkedFourthSource = freezeUtf8(fourthBytes);

    LinkPlan fifthPlan = planPrivateResolvedConstantImport(
      linkedFourthSource,
      fifthSource,
      /* expectedImportCount= */ 1
    );
    if (fifthPlan.valid) {} else {
      drop(linkedFourthSource);
      drop(fourthArena);
      drop(linkedThirdSource);
      drop(thirdArena);
      return new FiveGraphCompilation(0, 0);
    }

    region fifthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeConstantImport(
      linkedFourthSource,
      fifthSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 linkedFifthSource = freezeUtf8(fifthBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedFifthSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedFifthSource);
      drop(fifthArena);
      drop(linkedFourthSource);
      drop(fourthArena);
      drop(linkedThirdSource);
      drop(thirdArena);
      return new FiveGraphCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(linkedFifthSource, rootSource, rootPlan, rootBytes);
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedFifthSource);
    drop(fifthArena);
    drop(linkedFourthSource);
    drop(fourthArena);
    drop(linkedThirdSource);
    drop(thirdArena);
    return new FiveGraphCompilation(compiled.length, compiled.codeStart);
  }

  private FiveGraphCompilation compileFiveChainFromDirectedPair(
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
      return new FiveGraphCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(leafSource, secondSource, secondPlan, secondBytes);
    assert(secondWritten == secondPlan.linkedLength);
    utf8 linkedSecondSource = freezeUtf8(secondBytes);

    FiveGraphCompilation compiled = compileFiveChainTailIfOrdered(
      linkedSecondSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {} else {
      compiled = compileFiveChainTailIfOrdered(
        linkedSecondSource,
        firstRemainingSource,
        thirdRemainingSource,
        secondRemainingSource,
        rootSource,
        output
      );
    }

    if (0 < compiled.length) {} else {
      compiled = compileFiveChainTailIfOrdered(
        linkedSecondSource,
        secondRemainingSource,
        firstRemainingSource,
        thirdRemainingSource,
        rootSource,
        output
      );
    }

    if (0 < compiled.length) {} else {
      compiled = compileFiveChainTailIfOrdered(
        linkedSecondSource,
        secondRemainingSource,
        thirdRemainingSource,
        firstRemainingSource,
        rootSource,
        output
      );
    }

    if (0 < compiled.length) {} else {
      compiled = compileFiveChainTailIfOrdered(
        linkedSecondSource,
        thirdRemainingSource,
        firstRemainingSource,
        secondRemainingSource,
        rootSource,
        output
      );
    }

    if (0 < compiled.length) {} else {
      compiled = compileFiveChainTailIfOrdered(
        linkedSecondSource,
        thirdRemainingSource,
        secondRemainingSource,
        firstRemainingSource,
        rootSource,
        output
      );
    }

    drop(linkedSecondSource);
    drop(secondArena);
    return compiled;
  }

  private FiveGraphCompilation compileFiveChainFromPair(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveGraphCompilation compiled = compileFiveChainFromDirectedPair(
      firstSource,
      secondSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileFiveChainFromDirectedPair(
      secondSource,
      firstSource,
      firstRemainingSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
  }

  private FiveGraphCompilation compileFiveDirectConstants(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (firstPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstImportedSource,
      rootSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondImportedSource,
      firstLinkedSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (secondPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondImportedSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planConstantImport(
      thirdImportedSource,
      secondLinkedSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (thirdPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdImportedSource,
      secondLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 thirdLinkedSource = freezeUtf8(thirdBytes);

    LinkPlan fourthPlan = planConstantImport(
      fourthImportedSource,
      thirdLinkedSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (fourthPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

    region fourthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthPlan.linkedLength);
    long fourthWritten = writeConstantImport(
      fourthImportedSource,
      thirdLinkedSource,
      fourthPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthPlan.linkedLength);
    utf8 fourthLinkedSource = freezeUtf8(fourthBytes);

    LinkPlan fifthPlan = planConstantImport(
      fifthImportedSource,
      fourthLinkedSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (fifthPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

    region fifthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeConstantImport(
      fifthImportedSource,
      fourthLinkedSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 fifthLinkedSource = freezeUtf8(fifthBytes);
    CoreCompilation compiled = compileMinimalCore(fifthLinkedSource, output);
    drop(fifthLinkedSource);
    drop(fifthArena);
    drop(fourthLinkedSource);
    drop(fourthArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return new FiveGraphCompilation(compiled.length, compiled.codeStart);
  }

  private FiveGraphCompilation compileFiveChain(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveGraphCompilation compiled = compileFiveChainFromPair(
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

    compiled = compileFiveChainFromPair(
      firstSource,
      thirdSource,
      secondSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      firstSource,
      fourthSource,
      secondSource,
      thirdSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      firstSource,
      fifthSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      secondSource,
      thirdSource,
      firstSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      secondSource,
      fourthSource,
      firstSource,
      thirdSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      secondSource,
      fifthSource,
      firstSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      thirdSource,
      fourthSource,
      firstSource,
      secondSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      thirdSource,
      fifthSource,
      firstSource,
      secondSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileFiveChainFromPair(
      fourthSource,
      fifthSource,
      firstSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return new FiveGraphCompilation(0, 0);
  }

  /// Compiles one root through one validated five-module graph plan.
  public FiveGraphCompilation compileFiveConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveGraphPlan plan = planFiveConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource
    );
    if (plan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

    if (plan.topology == FIVE_PLAN_DIRECT) {
      return compileFiveDirectConstants(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
    }

    if (plan.topology == FIVE_PLAN_FORK) {
      FiveForkCompilation fork = compileFourLeafConstantFork(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < fork.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(fork.length, fork.codeStart);
    }

    if (plan.topology == FIVE_PLAN_FORK_AND_DIRECT) {
      FiveBranchCompilation branch = compileFiveForkAndDirect(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < branch.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(branch.length, branch.codeStart);
    }

    if (plan.topology == FIVE_PLAN_FORK_AND_TWO_DIRECTS) {
      FiveForkMixedCompilation mixedFork = compileFiveForkAndTwoDirects(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < mixedFork.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(mixedFork.length, mixedFork.codeStart);
    }

    if (plan.topology == FIVE_PLAN_CHAIN_AND_DIRECTS) {
      FiveMixedCompilation mixed = compileFiveChainAndDirects(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < mixed.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(mixed.length, mixed.codeStart);
    }

    if (plan.topology == FIVE_PLAN_CHAIN) {
      FiveGraphCompilation chain = compileFiveChain(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < chain.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return chain;
    }

    assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    return new FiveGraphCompilation(0, 0);
  }
}
