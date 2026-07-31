//! Resolves one planned six-module five-leaf scalar-constant fork.

module wheeler.compiler.graphs.six.fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.graphs.six.plans;
import wheeler.compiler.graphs.sources;
import wheeler.compiler.module_linker;

classical class SixConstantFork {
  private const long SINGLE_IMPORT = 1;
  private const long FIVE_IMPORTS = 5;

  /// Carries one six-module fork compilation.
  public record SixForkCompilation(long length, long codeStart) {}

  private utf8 linkLeaf(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ FIVE_IMPORTS
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

  /// Compiles five planned leaves through one root-visible dependent.
  public SixForkCompilation compileSixConstantFork(
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
    assert(plan.valid);
    assert(plan.topology == SIX_PLAN_FORK);

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 dependentSource = copySelectedSixSource(
      plan.sixth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      dependentArena
    );
    region firstLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 firstLeafSource = copySelectedSixSource(
      plan.first,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      firstLeafArena
    );
    region firstLinkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 firstLinkedSource = linkLeaf(firstLeafSource, dependentSource, firstLinkedArena);
    drop(firstLeafSource);
    drop(firstLeafArena);
    drop(dependentSource);
    drop(dependentArena);

    region secondLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 secondLeafSource = copySelectedSixSource(
      plan.second,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      secondLeafArena
    );
    region secondLinkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 secondLinkedSource = linkLeaf(secondLeafSource, firstLinkedSource, secondLinkedArena);
    drop(secondLeafSource);
    drop(secondLeafArena);
    drop(firstLinkedSource);
    drop(firstLinkedArena);

    region thirdLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 thirdLeafSource = copySelectedSixSource(
      plan.third,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      thirdLeafArena
    );
    region thirdLinkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 thirdLinkedSource = linkLeaf(thirdLeafSource, secondLinkedSource, thirdLinkedArena);
    drop(thirdLeafSource);
    drop(thirdLeafArena);
    drop(secondLinkedSource);
    drop(secondLinkedArena);

    region fourthLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 fourthLeafSource = copySelectedSixSource(
      plan.fourth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      fourthLeafArena
    );
    region fourthLinkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 fourthLinkedSource = linkLeaf(fourthLeafSource, thirdLinkedSource, fourthLinkedArena);
    drop(fourthLeafSource);
    drop(fourthLeafArena);
    drop(thirdLinkedSource);
    drop(thirdLinkedArena);

    region fifthLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 fifthLeafSource = copySelectedSixSource(
      plan.fifth,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      sixthSource,
      fifthLeafArena
    );
    region fifthLinkedArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 fifthLinkedSource = linkLeaf(fifthLeafSource, fourthLinkedSource, fifthLinkedArena);
    drop(fifthLeafSource);
    drop(fifthLeafArena);
    drop(fourthLinkedSource);
    drop(fourthLinkedArena);

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    utf8 linkedRootSource = linkRoot(fifthLinkedSource, rootSource, rootArena);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(fifthLinkedSource);
    drop(fifthLinkedArena);
    return new SixForkCompilation(compiled.length, compiled.codeStart);
  }
}
