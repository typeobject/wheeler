//! Resolves one seven-module direct constant star before canonical lowering.

module wheeler.compiler.compiler_graph_seven;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.chain;
import wheeler.compiler.graphs.seven.fork;
import wheeler.compiler.graphs.seven.mixed;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.seven.separate;
import wheeler.compiler.graphs.seven.wide_fork;
import wheeler.compiler.graphs.seven_plan_kinds;
import wheeler.compiler.module_linker;

classical class CompilerGraphSeven {
  private const long SEVEN_IMPORTS = 7;

  /// Carries private seven-module compilation bounds.
  public record SevenGraphCompilation(long length, long codeStart) {}

  private utf8 linkDirect(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planConstantImport(
      importedSource,
      rootSource,
      /* expectedImportCount= */ SEVEN_IMPORTS
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  /// Compiles seven direct scalar-constant imports in caller-supplied source order.
  private SevenGraphCompilation compileSevenDirectConstants(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 seventhImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLinkedSource = linkDirect(firstImportedSource, rootSource, firstArena);
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 secondLinkedSource = linkDirect(secondImportedSource, firstLinkedSource, secondArena);
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLinkedSource = linkDirect(thirdImportedSource, secondLinkedSource, thirdArena);
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fourthLinkedSource = linkDirect(fourthImportedSource, thirdLinkedSource, fourthArena);
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fifthLinkedSource = linkDirect(fifthImportedSource, fourthLinkedSource, fifthArena);
    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 sixthLinkedSource = linkDirect(sixthImportedSource, fifthLinkedSource, sixthArena);
    region seventhArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 seventhLinkedSource = linkDirect(seventhImportedSource, sixthLinkedSource, seventhArena);

    CoreCompilation compiled = compileMinimalCore(seventhLinkedSource, output);
    drop(seventhLinkedSource);
    drop(seventhArena);
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
    return new SevenGraphCompilation(compiled.length, compiled.codeStart);
  }

  /// Compiles one supported seven-module scalar-constant graph.
  public SevenGraphCompilation compileSevenConstantGraph(
    borrow utf8 firstImportedSource,
    borrow utf8 secondImportedSource,
    borrow utf8 thirdImportedSource,
    borrow utf8 fourthImportedSource,
    borrow utf8 fifthImportedSource,
    borrow utf8 sixthImportedSource,
    borrow utf8 seventhImportedSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    SevenGraphPlan plan = planSevenConstantGraph(
      firstImportedSource,
      secondImportedSource,
      thirdImportedSource,
      fourthImportedSource,
      fifthImportedSource,
      sixthImportedSource,
      seventhImportedSource,
      rootSource
    );
    assert(plan.valid);
    if (plan.topology == SEVEN_PLAN_DIRECT) {
      return compileSevenDirectConstants(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
    }

    if (plan.topology == SEVEN_PLAN_CHAIN) {
      SevenChainCompilation chain = compileSevenConstantChain(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(chain.length, chain.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_FORK) {
      SevenForkCompilation fork = compileSevenConstantFork(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(fork.length, fork.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_CHAIN_AND_DIRECTS) {
      SevenMixedCompilation mixed = compileSevenChainAndDirects(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(mixed.length, mixed.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_FORK_AND_DIRECTS) {
      SevenMixedCompilation mixedFork = compileSevenForkAndDirects(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(mixedFork.length, mixedFork.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_LONG_CHAIN_AND_DIRECTS) {
      SevenMixedCompilation longChain = compileSevenLongChainAndDirects(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(longChain.length, longChain.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_PAIRS_AND_DIRECTS) {
      SevenSeparateCompilation mixedPairs = compileSevenPairsAndDirects(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(mixedPairs.length, mixedPairs.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_THREE_CHAINS_AND_DIRECT) {
      SevenSeparateCompilation threeChains = compileSevenThreeChainsAndDirect(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(threeChains.length, threeChains.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_WIDE_FORK_AND_DIRECTS) {
      SevenWideForkCompilation wideFork = compileSevenWideForkAndDirects(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(wideFork.length, wideFork.codeStart);
    }

    if (plan.topology == SEVEN_PLAN_FIVE_LEAF_FORK_AND_DIRECT) {
      SevenWideForkCompilation fiveLeafFork = compileSevenFiveLeafForkAndDirect(
        plan,
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        sixthImportedSource,
        seventhImportedSource,
        rootSource,
        output
      );
      return new SevenGraphCompilation(fiveLeafFork.length, fiveLeafFork.codeStart);
    }

    assert(plan.topology == SEVEN_PLAN_DIRECT);
    return new SevenGraphCompilation(0, 0);
  }
}
