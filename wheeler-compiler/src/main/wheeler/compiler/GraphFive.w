//! Resolves the first bounded five-module constant graph before canonical lowering.

module wheeler.compiler.compiler_graph_five;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.constant_executor;
import wheeler.compiler.graphs.five_mixed;
import wheeler.compiler.graphs.matrix;
import wheeler.compiler.graphs.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;
import wheeler.compiler.wide_imported_helpers;

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
      CoreCompilation compiledHelpers = compileFiveHelperOwners(
        firstImportedSource,
        secondImportedSource,
        thirdImportedSource,
        fourthImportedSource,
        fifthImportedSource,
        rootSource,
        output
      );
      return new FiveGraphCompilation(compiledHelpers.length, compiledHelpers.codeStart);
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
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (secondPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
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
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (thirdPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
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
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (fourthPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
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

    LinkPlan fifthPlan = planConstantImport(
      fifthImportedSource,
      fourthLinkedSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (fifthPlan.valid) {} else {
      assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    }

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

  private long singleEdgeSource(BoundedGraphPlan plan) {
    long node = 0;
    while (node < FIVE_IMPORTS) limit FIVE_IMPORTS {
      if (plannedOutgoingCount(plan, node) == 1) {
        return node;
      }

      node += 1;
    }

    return -1;
  }

  private long singleEdgeDependent(BoundedGraphPlan plan) {
    long node = 0;
    while (node < FIVE_IMPORTS) limit FIVE_IMPORTS {
      if (plannedIncomingCount(plan, node) == 1) {
        return node;
      }

      node += 1;
    }

    return -1;
  }

  private long otherRootAt(BoundedGraphPlan plan, long dependent, long rank) {
    long node = 0;
    long found = 0;
    while (node < FIVE_IMPORTS) limit FIVE_IMPORTS {
      if (plannedRootDirect(plan, node)) {
        if (node == dependent) {} else {
          if (found == rank) {
            return node;
          }

          found += 1;
        }
      }

      node += 1;
    }

    return -1;
  }

  private FiveGraphCompilation compileFiveHelperChain(
    BoundedGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    long source = singleEdgeSource(plan);
    long dependent = singleEdgeDependent(plan);
    assert(0 < source + 1);
    assert(0 < dependent + 1);
    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFirst = copySelectedSource(
      source,
      GRAPH_SOURCE_COUNT_FIVE,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthSource,
      fifthSource,
      firstArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedSecond = copySelectedSource(
      dependent,
      GRAPH_SOURCE_COUNT_FIVE,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthSource,
      fifthSource,
      secondArena
    );
    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedThird = copySelectedSource(
      otherRootAt(plan, dependent, 0),
      GRAPH_SOURCE_COUNT_FIVE,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthSource,
      fifthSource,
      thirdArena
    );
    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFourth = copySelectedSource(
      otherRootAt(plan, dependent, 1),
      GRAPH_SOURCE_COUNT_FIVE,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthSource,
      fifthSource,
      fourthArena
    );
    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 plannedFifth = copySelectedSource(
      otherRootAt(plan, dependent, 2),
      GRAPH_SOURCE_COUNT_FIVE,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthSource,
      fifthSource,
      fifthArena
    );
    FiveMixedCompilation mixed = compileFiveChainAndDirectsIfOrdered(
      plannedFirst,
      plannedSecond,
      plannedThird,
      plannedFourth,
      plannedFifth,
      rootSource,
      output
    );
    FiveGraphCompilation compiled = new FiveGraphCompilation(mixed.length, mixed.codeStart);

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
    assert(0 < compiled.length);
    return compiled;
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
    BoundedGraphPlan plan = planFiveConstantGraph(
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

    ConstantPlanExecution execution = executeConstantPlan(
      plan,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      fifthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < execution.length) {
      return new FiveGraphCompilation(execution.length, execution.codeStart);
    }

    if (plan.edgeCount == 0) {
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

    if (plan.edgeCount == 1) {
      if (plan.rootCount == 4) {
        return compileFiveHelperChain(
          plan,
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

    assert(INVALID_COMPILATION_LENGTH == VALID_COMPILATION_LENGTH);
    return compileFiveHelperChain(
      plan,
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
