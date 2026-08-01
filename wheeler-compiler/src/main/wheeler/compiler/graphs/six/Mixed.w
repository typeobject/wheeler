//! Resolves one constant edge beside four direct six-module root imports.

module wheeler.compiler.graphs.six.mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class SixMixedGraph {
  private const long FIVE_IMPORTS = 5;

  /// Carries one mixed six-module compilation.
  public record SixMixedCompilation(long length, long codeStart) {}

  /// Compiles one exact planned chain beside four direct imports.
  public SixMixedCompilation compileSixChainAndDirectsIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 fourthDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan dependentPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      return new SixMixedCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, dependentPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      dependentPlan,
      dependentBytes
    );
    assert(dependentWritten == dependentPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      return new SixMixedCompilation(0, 0);
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
    utf8 firstLinkedRootSource = freezeUtf8(rootBytes);

    LinkPlan firstDirectPlan = planConstantImport(
      firstDirectSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    assert(firstDirectPlan.valid);
    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstDirectPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstDirectSource,
      firstLinkedRootSource,
      firstDirectPlan,
      firstBytes
    );
    assert(firstWritten == firstDirectPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(firstBytes);

    LinkPlan secondDirectPlan = planConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    assert(secondDirectPlan.valid);
    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondDirectPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      secondDirectPlan,
      secondBytes
    );
    assert(secondWritten == secondDirectPlan.linkedLength);
    utf8 thirdLinkedRootSource = freezeUtf8(secondBytes);

    LinkPlan thirdDirectPlan = planConstantImport(
      thirdDirectSource,
      thirdLinkedRootSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    assert(thirdDirectPlan.valid);
    region thirdArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes thirdBytes = allocateBytes(thirdArena, thirdDirectPlan.linkedLength);
    long thirdWritten = writeConstantImport(
      thirdDirectSource,
      thirdLinkedRootSource,
      thirdDirectPlan,
      thirdBytes
    );
    assert(thirdWritten == thirdDirectPlan.linkedLength);
    utf8 fourthLinkedRootSource = freezeUtf8(thirdBytes);

    LinkPlan fourthDirectPlan = planConstantImport(
      fourthDirectSource,
      fourthLinkedRootSource,
      /* expectedImportCount= */ FIVE_IMPORTS
    );
    assert(fourthDirectPlan.valid);
    region fourthArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes fourthBytes = allocateBytes(fourthArena, fourthDirectPlan.linkedLength);
    long fourthWritten = writeConstantImport(
      fourthDirectSource,
      fourthLinkedRootSource,
      fourthDirectPlan,
      fourthBytes
    );
    assert(fourthWritten == fourthDirectPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(fourthBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(fourthArena);
    drop(fourthLinkedRootSource);
    drop(thirdArena);
    drop(thirdLinkedRootSource);
    drop(secondArena);
    drop(secondLinkedRootSource);
    drop(firstArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return new SixMixedCompilation(compiled.length, compiled.codeStart);
  }
}
