//! Resolves the first bounded five-module constant graph before canonical lowering.

module wheeler.compiler.compiler_graph_five;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.five_branches;
import wheeler.compiler.graphs.five_chain;
import wheeler.compiler.graphs.five_dag;
import wheeler.compiler.graphs.five_deep_mixed;
import wheeler.compiler.graphs.five_fork;
import wheeler.compiler.graphs.five_fork_mixed;
import wheeler.compiler.graphs.five_long_mixed;
import wheeler.compiler.graphs.five_mixed;
import wheeler.compiler.graphs.five_nested_fork;
import wheeler.compiler.graphs.five_nested_mixed;
import wheeler.compiler.graphs.five_pairs;
import wheeler.compiler.graphs.plans;
import wheeler.compiler.module_linker;

classical class CompilerGraphFive {
  private const long FIVE_IMPORTS = 5;
  private const long INVALID_COMPILATION_LENGTH = 0;
  private const long VALID_COMPILATION_LENGTH = 1;

  /// Carries private five-module compilation bounds.
  public record FiveGraphCompilation(long length, long codeStart) {}

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
      FiveForkCompilation fork = compileFiveConstantFork(
        plan,
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

    if (plan.topology == FIVE_PLAN_SHARED_DIAMOND) {
      FiveDagCompilation dag = compileFiveSharedDiamond(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < dag.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(dag.length, dag.codeStart);
    }

    if (plan.topology == FIVE_PLAN_NESTED_FORK) {
      FiveNestedForkCompilation nestedFork = compileFiveNestedFork(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < nestedFork.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(nestedFork.length, nestedFork.codeStart);
    }

    if (plan.topology == FIVE_PLAN_NESTED_FORK_AND_DIRECT) {
      FiveNestedMixedCompilation nestedMixed = compileFiveNestedForkAndDirect(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < nestedMixed.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(nestedMixed.length, nestedMixed.codeStart);
    }

    if (plan.topology == FIVE_PLAN_DEEP_CHAIN_AND_DIRECT) {
      FiveDeepMixedCompilation deepMixed = compileFiveDeepChainAndDirect(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < deepMixed.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(deepMixed.length, deepMixed.codeStart);
    }

    if (plan.topology == FIVE_PLAN_LONG_CHAIN_AND_DIRECTS) {
      FiveLongMixedCompilation longMixed = compileFiveLongChainAndDirects(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < longMixed.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(longMixed.length, longMixed.codeStart);
    }

    if (plan.topology == FIVE_PLAN_PAIRS_AND_DIRECT) {
      FivePairCompilation pairs = compileFivePairsAndDirect(
        firstSource,
        secondSource,
        thirdSource,
        fourthSource,
        fifthSource,
        rootSource,
        output
      );
      if (0 < pairs.length) {} else {
        assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
      }

      return new FiveGraphCompilation(pairs.length, pairs.codeStart);
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
      FiveChainCompilation chain = compileFiveConstantChain(
        plan,
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

      return new FiveGraphCompilation(chain.length, chain.codeStart);
    }

    assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    return new FiveGraphCompilation(0, 0);
  }
}
