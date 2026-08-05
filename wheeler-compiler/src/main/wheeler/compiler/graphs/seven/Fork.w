//! Resolves one planned seven-module six-leaf scalar-constant fork.

module wheeler.compiler.graphs.seven.fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.seven.plans;
import wheeler.compiler.graphs.seven_plan_kinds;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SevenConstantFork {
  private const long SINGLE_IMPORT = 1;
  private const long SIX_IMPORTS = 6;

  /// Carries one seven-module fork compilation.
  public record SevenForkCompilation(long length, long codeStart) {}

  private utf8 linkLeaf(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ SIX_IMPORTS
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(leafSource, dependentSource, plan, linkedBytes);
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

  /// Compiles six planned leaves through one root-visible dependent.
  public SevenForkCompilation compileSevenConstantFork(
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
    assert(plan.topology == SEVEN_PLAN_FORK);

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 dependentSource = copySelectedSevenSource(
      plan.seventh,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      dependentArena
    );
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLeafSource = copySelectedSevenSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      firstLeafArena
    );
    region firstLinkedArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 firstLinkedSource = linkLeaf(firstLeafSource, dependentSource, firstLinkedArena);
    drop(firstLeafSource);
    drop(firstLeafArena);
    drop(dependentSource);
    drop(dependentArena);

    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLeafSource = copySelectedSevenSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      secondLeafArena
    );
    region secondLinkedArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 secondLinkedSource = linkLeaf(secondLeafSource, firstLinkedSource, secondLinkedArena);
    drop(secondLeafSource);
    drop(secondLeafArena);
    drop(firstLinkedSource);
    drop(firstLinkedArena);

    region thirdLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 thirdLeafSource = copySelectedSevenSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      thirdLeafArena
    );
    region thirdLinkedArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 thirdLinkedSource = linkLeaf(thirdLeafSource, secondLinkedSource, thirdLinkedArena);
    drop(thirdLeafSource);
    drop(thirdLeafArena);
    drop(secondLinkedSource);
    drop(secondLinkedArena);

    region fourthLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 fourthLeafSource = copySelectedSevenSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fourthLeafArena
    );
    region fourthLinkedArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 fourthLinkedSource = linkLeaf(fourthLeafSource, thirdLinkedSource, fourthLinkedArena);
    drop(fourthLeafSource);
    drop(fourthLeafArena);
    drop(thirdLinkedSource);
    drop(thirdLinkedArena);

    region fifthLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 fifthLeafSource = copySelectedSevenSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      fifthLeafArena
    );
    region fifthLinkedArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 fifthLinkedSource = linkLeaf(fifthLeafSource, fourthLinkedSource, fifthLinkedArena);
    drop(fifthLeafSource);
    drop(fifthLeafArena);
    drop(fourthLinkedSource);
    drop(fourthLinkedArena);

    region sixthLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 sixthLeafSource = copySelectedSevenSource(
      plan.sixth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      seventhSource,
      sixthLeafArena
    );
    region sixthLinkedArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    utf8 linkedDependentSource = linkLeaf(sixthLeafSource, fifthLinkedSource, sixthLinkedArena);
    drop(sixthLeafSource);
    drop(sixthLeafArena);
    drop(fifthLinkedSource);
    drop(fifthLinkedArena);

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkRoot(linkedDependentSource, rootSource, rootArena);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(sixthLinkedArena);
    return new SevenForkCompilation(compiled.length, compiled.codeStart);
  }
}
