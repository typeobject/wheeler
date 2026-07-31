//! Resolves bounded four-module constant graphs before canonical lowering.

module wheeler.compiler.compiler_graph_four;

import wheeler.compiler.compiler_core;
import wheeler.compiler.compiler_graph_four_branches;
import wheeler.compiler.compiler_graph_four_dag;
import wheeler.compiler.compiler_graph_four_mixed;
import wheeler.compiler.compiler_graph_four_nested;
import wheeler.compiler.graphs.four_structures;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class CompilerGraphFour {
  /// Carries private four-module compilation bounds.
  public record FourGraphCompilation(long length, long codeStart) {}

  private FourGraphCompilation compileFourGraphSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new FourGraphCompilation(compiled.length, compiled.codeStart);
  }

  private FourGraphCompilation compileFourChainFromEdgeIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondDependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new FourGraphCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, leafPlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, leafPlan, middleBytes);
    assert(middleWritten == leafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    LinkPlan firstPlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstPlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(middleArena);
      return new FourGraphCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      linkedMiddleSource,
      firstDependentSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 linkedFirstSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planPrivateResolvedConstantImport(
      linkedFirstSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    if (secondPlan.valid) {} else {
      drop(linkedFirstSource);
      drop(firstArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new FourGraphCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      linkedFirstSource,
      secondDependentSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 linkedSecondSource = freezeUtf8(secondBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedSecondSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedSecondSource);
      drop(secondArena);
      drop(linkedFirstSource);
      drop(firstArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new FourGraphCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(linkedSecondSource, rootSource, rootPlan, rootBytes);
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    FourGraphCompilation compiled = compileFourGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedSecondSource);
    drop(secondArena);
    drop(linkedFirstSource);
    drop(firstArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

  private FourGraphCompilation compileThreeLeafForkIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 thirdLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ 3
    );
    if (firstPlan.valid) {} else {
      return new FourGraphCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstLeafSource,
      dependentSource,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedSource = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (secondPlan.valid) {} else {
      drop(firstLinkedSource);
      drop(firstArena);
      return new FourGraphCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedSource,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedSource = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planPrivateConstantImport(
      thirdLeafSource,
      secondLinkedSource,
      /* expectedImportCount= */ 3
    );
    if (thirdPlan.valid) {} else {
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new FourGraphCompilation(0, 0);
    }

    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdLeafSource,
      secondLinkedSource,
      thirdPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(thirdBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(thirdArena);
      drop(secondLinkedSource);
      drop(secondArena);
      drop(firstLinkedSource);
      drop(firstArena);
      return new FourGraphCompilation(0, 0);
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
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    FourGraphCompilation compiled = compileFourGraphSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  private FourGraphCompilation compilePlannedFourChain(
    FourGraphStructure structure,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedFirst = copySelectedFourSource(
      structure.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedSecond = copySelectedFourSource(
      structure.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedThird = copySelectedFourSource(
      structure.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedFourth = copySelectedFourSource(
      structure.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fourthArena
    );
    FourGraphCompilation compiled = compileFourChainFromEdgeIfOrdered(
      plannedFirst,
      plannedSecond,
      plannedThird,
      plannedFourth,
      rootSource,
      output
    );
    drop(plannedFourth);
    drop(fourthArena);
    drop(plannedThird);
    drop(thirdArena);
    drop(plannedSecond);
    drop(secondArena);
    drop(plannedFirst);
    drop(firstArena);
    return compiled;
  }

  private FourGraphCompilation compilePlannedThreeLeafFork(
    FourGraphStructure structure,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedFirst = copySelectedFourSource(
      structure.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedSecond = copySelectedFourSource(
      structure.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedThird = copySelectedFourSource(
      structure.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 plannedFourth = copySelectedFourSource(
      structure.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fourthArena
    );
    FourGraphCompilation compiled = compileThreeLeafForkIfOrdered(
      plannedFirst,
      plannedSecond,
      plannedThird,
      plannedFourth,
      rootSource,
      output
    );
    drop(plannedFourth);
    drop(fourthArena);
    drop(plannedThird);
    drop(thirdArena);
    drop(plannedSecond);
    drop(secondArena);
    drop(plannedFirst);
    drop(firstArena);
    return compiled;
  }

  private FourGraphCompilation compileFourDirect(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ 4
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
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
      /* expectedImportCount= */ 4
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
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
      /* expectedImportCount= */ 4
    );
    if (thirdPlan.valid) {} else {
      assert(0 == 1);
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
      /* expectedImportCount= */ 4
    );
    if (fourthPlan.valid) {} else {
      assert(0 == 1);
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
    FourGraphCompilation compiled = compileFourGraphSource(fourthLinkedSource, output);
    drop(fourthLinkedSource);
    drop(fourthArena);
    drop(thirdLinkedSource);
    drop(thirdArena);
    drop(secondLinkedSource);
    drop(secondArena);
    drop(firstLinkedSource);
    drop(firstArena);
    return compiled;
  }

  /// Compiles one root with one exact four-module constant graph plan.
  public FourGraphCompilation compileFourConstantGraph(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FourGraphStructure structure = planFourStructure(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource
    );
    if (structure.valid) {} else {
      assert(0 == 1);
    }

    if (structure.topology == FOUR_STRUCTURE_SHARED_DIAMOND) {
      FourDagCompilation diamond = compileFourConstantDiamond(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < diamond.length);
      return new FourGraphCompilation(diamond.length, diamond.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_CHAIN) {
      FourGraphCompilation chain = compilePlannedFourChain(
        structure,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < chain.length);
      return chain;
    }

    if (structure.topology == FOUR_STRUCTURE_FORK_THEN_PARENT) {
      NestedFourCompilation forkThenParent = compileFourForkThenParent(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < forkThenParent.length);
      return new FourGraphCompilation(forkThenParent.length, forkThenParent.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_UNEVEN_FORK) {
      NestedFourCompilation unevenFork = compileFourUnevenFork(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < unevenFork.length);
      return new FourGraphCompilation(unevenFork.length, unevenFork.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_FORK_AND_DIRECT) {
      BranchedFourCompilation forkAndDirect = compileFourForkAndDirect(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < forkAndDirect.length);
      return new FourGraphCompilation(forkAndDirect.length, forkAndDirect.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_TWO_CHAINS) {
      BranchedFourCompilation paired = compileFourTwoChains(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < paired.length);
      return new FourGraphCompilation(paired.length, paired.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_CHAIN_AND_DIRECTS) {
      BranchedFourCompilation branched = compileFourChainAndTwoDirect(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < branched.length);
      return new FourGraphCompilation(branched.length, branched.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_CHAIN_AND_DIRECT) {
      MixedFourCompilation mixed = compileFourChainAndDirect(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < mixed.length);
      return new FourGraphCompilation(mixed.length, mixed.codeStart);
    }

    if (structure.topology == FOUR_STRUCTURE_FORK) {
      FourGraphCompilation fork = compilePlannedThreeLeafFork(
        structure,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      assert(0 < fork.length);
      return fork;
    }

    assert(structure.topology == FOUR_STRUCTURE_DIRECT);
    return compileFourDirect(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource,
      output
    );
  }
}
