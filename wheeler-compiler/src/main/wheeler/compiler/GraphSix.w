//! Resolves the first six-module constant graph before canonical lowering.

module wheeler.compiler.compiler_graph_six;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.six.chain;
import wheeler.compiler.graphs.six.fork;
import wheeler.compiler.graphs.six.mixed;
import wheeler.compiler.graphs.six.nested;
import wheeler.compiler.graphs.six.pairs;
import wheeler.compiler.graphs.six.plans;
import wheeler.compiler.graphs.six.separate;
import wheeler.compiler.graphs.six.uneven;
import wheeler.compiler.graphs.six_graph_kinds;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;
import wheeler.compiler.six_imported_helpers;

classical class CompilerGraphSix {
  private const long SIX_IMPORTS = 6;

  /// Carries private six-module compilation bounds.
  public record SixGraphCompilation(long length, long codeStart) {}

  private SixGraphCompilation compileSixDirectConstants(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstPlan = planConstantImport(
      firstImportedSource,
      rootSource,
      /* expectedImportCount= */ SIX_IMPORTS
    );
    if (firstPlan.valid) {} else {
      CoreCompilation compiledHelpers = compileSixHelperOwners(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        rootSource,
        output
      );
      return new SixGraphCompilation(compiledHelpers.length, compiledHelpers.codeStart);
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
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(secondPlan.valid);
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
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(thirdPlan.valid);
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
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(fourthPlan.valid);
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

    LinkPlan fifthPlan = planConstantImport(
      fifthImportedSource,
      fourthLinkedSource,
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(fifthPlan.valid);
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes fifthBytes = allocateBytes(fifthArena, fifthPlan.linkedLength);
    long fifthWritten = writeConstantImport(
      fifthImportedSource,
      fourthLinkedSource,
      fifthPlan,
      fifthBytes
    );
    assert(fifthWritten == fifthPlan.linkedLength);
    utf8 fifthLinkedSource = freezeUtf8(fifthBytes);

    LinkPlan sixthPlan = planConstantImport(
      sixthImportedSource,
      fifthLinkedSource,
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(sixthPlan.valid);
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes sixthBytes = allocateBytes(sixthArena, sixthPlan.linkedLength);
    long sixthWritten = writeConstantImport(
      sixthImportedSource,
      fifthLinkedSource,
      sixthPlan,
      sixthBytes
    );
    assert(sixthWritten == sixthPlan.linkedLength);
    utf8 sixthLinkedSource = freezeUtf8(sixthBytes);

    CoreCompilation compiled = compileMinimalCore(sixthLinkedSource, output);
    drop(sixthLinkedSource);
    drop(sixthArena);
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
    return new SixGraphCompilation(compiled.length, compiled.codeStart);
  }

  private SixGraphCompilation compilePlannedSixRootBranches(
    SixGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFirst = copySelectedSource(
      plan.first,
      GRAPH_SOURCE_COUNT_SIX,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedSecond = copySelectedSource(
      plan.second,
      GRAPH_SOURCE_COUNT_SIX,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedThird = copySelectedSource(
      plan.third,
      GRAPH_SOURCE_COUNT_SIX,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFourth = copySelectedSource(
      plan.fourth,
      GRAPH_SOURCE_COUNT_SIX,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthSource,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFifth = copySelectedSource(
      plan.fifth,
      GRAPH_SOURCE_COUNT_SIX,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthSource,
      fifthArena
    );
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedSixth = copySelectedSource(
      plan.sixth,
      GRAPH_SOURCE_COUNT_SIX,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      sixthSource,
      sixthArena
    );
    SixMixedCompilation mixed = new SixMixedCompilation(0, 0);
    if (plan.topology == SIX_PLAN_CHAIN_AND_DIRECTS) {
      mixed = compileSixChainAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
    }

    if (plan.topology == SIX_PLAN_FORK_AND_DIRECTS) {
      mixed = compileSixForkAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
    }

    if (plan.topology == SIX_PLAN_PAIRS_AND_DIRECTS) {
      SixPairCompilation pairs = compileSixPairsAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
      mixed = new SixMixedCompilation(pairs.length, pairs.codeStart);
    }

    if (plan.topology == SIX_PLAN_LONG_CHAIN_AND_DIRECTS) {
      mixed = compileSixLongChainAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
    }

    if (plan.topology == SIX_PLAN_DEEP_CHAIN_AND_DIRECTS) {
      mixed = compileSixDeepChainAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
    }

    if (plan.topology == SIX_PLAN_THREE_LEAF_FORK_AND_DIRECTS) {
      mixed = compileSixThreeLeafForkAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
    }

    if (plan.topology == SIX_PLAN_NESTED_FORK_AND_DIRECTS) {
      SixNestedCompilation nested = compileSixNestedForkAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
      mixed = new SixMixedCompilation(nested.length, nested.codeStart);
    }

    if (plan.topology == SIX_PLAN_UNEVEN_TREE_AND_DIRECTS) {
      SixUnevenCompilation uneven = compileSixUnevenTreeAndDirectsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
      mixed = new SixMixedCompilation(uneven.length, uneven.codeStart);
    }

    if (plan.topology == SIX_PLAN_FORK_CHAIN_AND_DIRECT) {
      SixSeparateCompilation forkChain = compileSixForkChainAndDirectIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
      mixed = new SixMixedCompilation(forkChain.length, forkChain.codeStart);
    }

    if (plan.topology == SIX_PLAN_THREE_CHAINS) {
      SixSeparateCompilation threeChains = compileSixThreeChainsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
      mixed = new SixMixedCompilation(threeChains.length, threeChains.codeStart);
    }

    if (plan.topology == SIX_PLAN_LONG_AND_SHORT_CHAINS) {
      SixSeparateCompilation longShort = compileSixLongAndShortChainsIfOrdered(
        plannedFirst,
        plannedSecond,
        plannedThird,
        plannedFourth,
        plannedFifth,
        plannedSixth,
        rootSource,
        output
      );
      mixed = new SixMixedCompilation(longShort.length, longShort.codeStart);
    }

    drop(plannedSixth);
    drop(sixthArena);
    drop(plannedFifth);
    drop(fifthArena);
    drop(plannedFourth);
    drop(fourthArena);
    drop(plannedThird);
    drop(thirdArena);
    drop(plannedSecond);
    drop(secondArena);
    drop(plannedFirst);
    drop(firstArena);
    assert(0 < mixed.length);
    return new SixGraphCompilation(mixed.length, mixed.codeStart);
  }

  /// Compiles one supported six-module scalar-constant graph.
  public SixGraphCompilation compileSixConstantGraph(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SixGraphPlan plan = planSixConstantGraph(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource
    );
    if (plan.valid) {} else {
      assert(0 == 1);
    }

    ConstantPlanExecution execution = executeConstantPlan(
      plan.bounded,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      rootSource,
      output
    );
    if (0 < execution.length) {
      return new SixGraphCompilation(execution.length, execution.codeStart);
    }

    if (plan.topology == SIX_PLAN_DIRECT) {
      return compileSixDirectConstants(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource,
        output
      );
    }

    if (SIX_PLAN_FORK < plan.topology) {
      if (plan.topology < SIX_ROOT_BRANCH_PLAN_LIMIT) {
        return compilePlannedSixRootBranches(
          plan,
          firstSource,
          secondSource,
          thirdSource,
          fourthSource,
          fifthSource,
          sixthSource,
          rootSource,
          output
        );
      }
    }

    if (plan.topology == SIX_PLAN_CHAIN) {
      SixChainCompilation chain = compileSixConstantChain(
        plan,
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource,
        output
      );
      if (0 < chain.length) {} else {
        assert(0 == 1);
      }

      return new SixGraphCompilation(chain.length, chain.codeStart);
    }

    if (plan.topology == SIX_PLAN_FORK) {
      SixForkCompilation fork = compileSixConstantFork(
        plan,
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        sixthSource,
        rootSource,
        output
      );
      if (0 < fork.length) {} else {
        assert(0 == 1);
      }

      return new SixGraphCompilation(fork.length, fork.codeStart);
    }

    assert(0 == 1);
    return new SixGraphCompilation(0, 0);
  }
}
