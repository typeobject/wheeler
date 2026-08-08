//! Resolves bounded four-module constant graphs before canonical lowering.

module wheeler.compiler.compiler_graph_four;

import wheeler.compiler.compiler_core;
import wheeler.compiler.compiler_graph_four_branches;
import wheeler.compiler.compiler_graph_four_dag;
import wheeler.compiler.compiler_graph_four_mixed;
import wheeler.compiler.compiler_graph_four_nested;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.four_plan_sources;
import wheeler.compiler.graphs.four_structures;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.plan_sources;
import wheeler.compiler.graphs.source_table;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;
import wheeler.compiler.multiple_imported_helpers;

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

    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

  private FourGraphCompilation compilePlannedFourGraph(
    BoundedGraphPlan plan,
    FourSourceOrder sources,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region sourceTableArena = new region(
      /* bytes= */ SOURCE_TABLE_ARENA_BYTES,
      /* allocations= */ 2
    );
    bytes sourceStorage = allocateBytes(sourceTableArena, SOURCE_TABLE_BYTES);
    words sourceLengths = allocate(sourceTableArena, SOURCE_TABLE_LENGTH_WORDS);
    boolean initialized = initializePlannedSourceTable(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fourthSource,
      fourthSource,
      fourthSource,
      sourceStorage,
      sourceLengths
    );
    assert(initialized);
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFirst = copyPlannedTableSource(
      plan,
      sources.first,
      sourceStorage,
      sourceLengths,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedSecond = copyPlannedTableSource(
      plan,
      sources.second,
      sourceStorage,
      sourceLengths,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedThird = copyPlannedTableSource(
      plan,
      sources.third,
      sourceStorage,
      sourceLengths,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFourth = copyPlannedTableSource(
      plan,
      sources.fourth,
      sourceStorage,
      sourceLengths,
      fourthArena
    );
    drop(sourceLengths);
    drop(sourceStorage);
    drop(sourceTableArena);
    FourGraphCompilation compiled = new FourGraphCompilation(0, 0);
    if (plan.edgeCount == 0) {
      compiled = compileFourDirect(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        rootSource,
        output
      );
    }

    if (plan.edgeCount == 1) {
      BranchedFourCompilation branchedChain = compileChainAndTwoDirectIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        rootSource,
        output
      );
      compiled = new FourGraphCompilation(branchedChain.length, branchedChain.codeStart);
    }

    if (plan.edgeCount == 2) {
      long maximumIncoming = fourMaximumIncoming(plan);
      if (maximumIncoming == 2) {
        BranchedFourCompilation branchedFork = compileForkAndDirectIfOrdered(
          plannedFirst,
          plannedSecond,
          plannedThird,
          plannedFourth,
          rootSource,
          output
        );
        compiled = new FourGraphCompilation(branchedFork.length, branchedFork.codeStart);
      } else {
        if (fourHasMiddle(plan)) {
          MixedFourCompilation mixedChain = compileChainAndDirectIfOrdered(
            plannedFirst,
            plannedSecond,
            plannedThird,
            plannedFourth,
            rootSource,
            output
          );
          compiled = new FourGraphCompilation(mixedChain.length, mixedChain.codeStart);
        } else {
          BranchedFourCompilation branchedPairs = compileTwoChainsIfOrdered(
            plannedFirst,
            plannedSecond,
            plannedThird,
            plannedFourth,
            rootSource,
            output
          );
          compiled = new FourGraphCompilation(branchedPairs.length, branchedPairs.codeStart);
        }
      }
    }

    if (plan.edgeCount == 3) {
      long treeMaximumIncoming = fourMaximumIncoming(plan);
      if (treeMaximumIncoming == 3) {
        compiled = compileThreeLeafForkIfOrdered(
          plannedFirst,
          plannedSecond,
          plannedThird,
          plannedFourth,
          rootSource,
          output
        );
      } else {
        if (treeMaximumIncoming == 2) {
          if (fourRootIncoming(plan) == 1) {
            NestedFourCompilation nestedParent = compileForkThenParentIfOrdered(
              plannedFirst,
              plannedSecond,
              plannedThird,
              plannedFourth,
              rootSource,
              output
            );
            compiled = new FourGraphCompilation(nestedParent.length, nestedParent.codeStart);
          } else {
            NestedFourCompilation nestedUneven = compileUnevenForkIfOrdered(
              plannedFirst,
              plannedSecond,
              plannedThird,
              plannedFourth,
              rootSource,
              output
            );
            compiled = new FourGraphCompilation(nestedUneven.length, nestedUneven.codeStart);
          }
        } else {
          compiled = compileFourChainFromEdgeIfOrdered(
            plannedFirst,
            plannedSecond,
            plannedThird,
            plannedFourth,
            rootSource,
            output
          );
        }
      }
    }

    if (plan.edgeCount == GRAPH_SOURCE_COUNT_FOUR) {
      FourDagCompilation sharedDiamond = compileDiamondIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        rootSource,
        output
      );
      compiled = new FourGraphCompilation(sharedDiamond.length, sharedDiamond.codeStart);
    }

    drop(plannedFourth);
    drop(fourthArena);
    drop(plannedThird);
    drop(thirdArena);
    drop(plannedSecond);
    drop(secondArena);
    drop(plannedFirst);
    drop(firstArena);
    assert(0 < compiled.length);
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
      CoreCompilation compiledHelpers = compileFourHelperOwners(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        rootSource,
        output
      );
      return new FourGraphCompilation(compiledHelpers.length, compiledHelpers.codeStart);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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
    BoundedGraphPlan plan = planFourGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource
    );
    if (plan.valid) {} else {
      assert(0 == 1);
    }

    ConstantPlanExecution execution = executeConstantPlan(
      plan,
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource,
      output
    );
    if (0 < execution.length) {
      return new FourGraphCompilation(execution.length, execution.codeStart);
    }

    FourSourceOrder sources = planFourSources(plan);
    if (sources.valid) {} else {
      assert(0 == 1);
    }

    return compilePlannedFourGraph(
      plan,
      sources,
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      rootSource,
      output
    );
  }
}
