//! Resolves one planned seven-module scalar-constant chain.

module wheeler.compiler.graphs.seven.chain;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.plan_shapes;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.seven_plan_kinds;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenConstantChain {
  private const long SINGLE_IMPORT = 1;

  /// Carries one seven-module chain compilation.
  public record SevenChainCompilation(long length, long codeStart) {}

  private utf8 linkPrivateLeaf(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ SINGLE_IMPORT
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(leafSource, dependentSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  private utf8 linkPrivateResolved(
    borrow utf8 linkedSource,
    borrow utf8 dependentSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateResolvedConstantImport(
      linkedSource,
      dependentSource,
      /* expectedImportCount= */ SINGLE_IMPORT
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(linkedSource, dependentSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  private utf8 linkRoot(
    borrow utf8 linkedSource,
    borrow utf8 rootSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planResolvedConstantImport(
      linkedSource,
      rootSource,
      /* expectedImportCount= */ SINGLE_IMPORT
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(linkedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  /// Compiles one exact leaf-to-root chain order selected by the closed plan.
  public SevenChainCompilation compileSevenConstantChain(
    SevenGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 sixthSource,
    borrow utf8 seventhSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    assert(plan.valid);
    assert(plan.topology == SEVEN_PLAN_CHAIN);

    region leafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 leafSource = copySelectedSevenSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      leafArena
    );
    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 orderedSecondSource = copySelectedSevenSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      secondArena
    );
    region linkedSecondArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSecondSource = linkPrivateLeaf(leafSource, orderedSecondSource, linkedSecondArena);
    drop(orderedSecondSource);
    drop(secondArena);
    drop(leafSource);
    drop(leafArena);

    region thirdArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 orderedThirdSource = copySelectedSevenSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdArena
    );
    region linkedThirdArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedThirdSource = linkPrivateResolved(
      linkedSecondSource,
      orderedThirdSource,
      linkedThirdArena
    );
    drop(orderedThirdSource);
    drop(thirdArena);
    drop(linkedSecondSource);
    drop(linkedSecondArena);

    region fourthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 orderedFourthSource = copySelectedSevenSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthArena
    );
    region linkedFourthArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFourthSource = linkPrivateResolved(
      linkedThirdSource,
      orderedFourthSource,
      linkedFourthArena
    );
    drop(orderedFourthSource);
    drop(fourthArena);
    drop(linkedThirdSource);
    drop(linkedThirdArena);

    region fifthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 orderedFifthSource = copySelectedSevenSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthArena
    );
    region linkedFifthArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedFifthSource = linkPrivateResolved(
      linkedFourthSource,
      orderedFifthSource,
      linkedFifthArena
    );
    drop(orderedFifthSource);
    drop(fifthArena);
    drop(linkedFourthSource);
    drop(linkedFourthArena);

    region sixthArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 orderedSixthSource = copySelectedSevenSource(
      plan.sixth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthArena
    );
    region linkedSixthArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSixthSource = linkPrivateResolved(
      linkedFifthSource,
      orderedSixthSource,
      linkedSixthArena
    );
    drop(orderedSixthSource);
    drop(sixthArena);
    drop(linkedFifthSource);
    drop(linkedFifthArena);

    region seventhArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 orderedSeventhSource = copySelectedSevenSource(
      plan.seventh,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      seventhArena
    );
    region linkedSeventhArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedSeventhSource = linkPrivateResolved(
      linkedSixthSource,
      orderedSeventhSource,
      linkedSeventhArena
    );
    drop(orderedSeventhSource);
    drop(seventhArena);
    drop(linkedSixthSource);
    drop(linkedSixthArena);

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkRoot(linkedSeventhSource, rootSource, rootArena);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedSeventhSource);
    drop(linkedSeventhArena);
    return new SevenChainCompilation(compiled.length, compiled.codeStart);
  }
}
