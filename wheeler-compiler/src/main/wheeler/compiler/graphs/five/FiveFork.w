//! Resolves one planned five-module four-leaf scalar-constant fork.

module wheeler.compiler.graphs.five_fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.five_plan_kinds;
import wheeler.compiler.graphs.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class CompilerFiveFork {
  private const long SINGLE_IMPORT = 1;
  private const long FOUR_IMPORTS = 4;

  /// Carries one five-module fork compilation.
  public record FiveForkCompilation(long length, long codeStart) {}

  private utf8 linkLeaf(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ FOUR_IMPORTS
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

  /// Compiles four planned leaves through one root-visible dependent.
  public FiveForkCompilation compileFiveConstantFork(
    FiveGraphPlan plan,
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    assert(plan.valid);
    assert(plan.topology == FIVE_PLAN_FORK);

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 dependentSource = copySelectedFiveSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      dependentArena
    );
    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 firstLeafSource = copySelectedFiveSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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
    utf8 secondLeafSource = copySelectedFiveSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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
    utf8 thirdLeafSource = copySelectedFiveSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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
    utf8 fourthLeafSource = copySelectedFiveSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
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

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    utf8 linkedRootSource = linkRoot(fourthLinkedSource, rootSource, rootArena);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(fourthLinkedSource);
    drop(fourthLinkedArena);
    return new FiveForkCompilation(compiled.length, compiled.codeStart);
  }
}
