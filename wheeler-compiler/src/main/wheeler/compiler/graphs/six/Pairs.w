//! Resolves two independent constant edges beside two direct root modules.

module wheeler.compiler.graphs.six.pairs;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class SixPairGraph {
  private const long FOUR_IMPORTS = 4;

  /// Carries one paired six-module compilation.
  public record SixPairCompilation(long length, long codeStart) {}

  /// Compiles one exact planned pair of chains beside two direct imports.
  public SixPairCompilation compileSixPairsAndDirectsIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondDependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstLeafPlan.valid) {} else {
      return new SixPairCompilation(0, 0);
    }

    region firstDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstDependentBytes = allocateBytes(firstDependentArena, firstLeafPlan.linkedLength);
    long firstDependentWritten = writeConstantImport(
      firstLeafSource,
      firstDependentSource,
      firstLeafPlan,
      firstDependentBytes
    );
    assert(firstDependentWritten == firstLeafPlan.linkedLength);
    utf8 linkedFirstDependentSource = freezeUtf8(firstDependentBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    if (secondLeafPlan.valid) {} else {
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new SixPairCompilation(0, 0);
    }

    region secondDependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondDependentBytes = allocateBytes(secondDependentArena, secondLeafPlan.linkedLength);
    long secondDependentWritten = writeConstantImport(
      secondLeafSource,
      secondDependentSource,
      secondLeafPlan,
      secondDependentBytes
    );
    assert(secondDependentWritten == secondLeafPlan.linkedLength);
    utf8 linkedSecondDependentSource = freezeUtf8(secondDependentBytes);

    LinkPlan firstRootPlan = planResolvedConstantImport(
      linkedFirstDependentSource,
      rootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (firstRootPlan.valid) {} else {
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new SixPairCompilation(0, 0);
    }

    region firstRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstRootBytes = allocateBytes(firstRootArena, firstRootPlan.linkedLength);
    long firstRootWritten = writeConstantImport(
      linkedFirstDependentSource,
      rootSource,
      firstRootPlan,
      firstRootBytes
    );
    assert(firstRootWritten == firstRootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(firstRootBytes);

    LinkPlan secondRootPlan = planResolvedConstantImport(
      linkedSecondDependentSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (secondRootPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(firstRootArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new SixPairCompilation(0, 0);
    }

    region secondRootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondRootBytes = allocateBytes(secondRootArena, secondRootPlan.linkedLength);
    long secondRootWritten = writeConstantImport(
      linkedSecondDependentSource,
      firstLinkedRootSource,
      secondRootPlan,
      secondRootBytes
    );
    assert(secondRootWritten == secondRootPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(secondRootBytes);

    LinkPlan firstDirectPlan = planConstantImport(
      firstDirectSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (firstDirectPlan.valid) {} else {
      drop(secondLinkedRootSource);
      drop(secondRootArena);
      drop(firstLinkedRootSource);
      drop(firstRootArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new SixPairCompilation(0, 0);
    }

    region firstDirectArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstDirectBytes = allocateBytes(firstDirectArena, firstDirectPlan.linkedLength);
    long firstDirectWritten = writeConstantImport(
      firstDirectSource,
      secondLinkedRootSource,
      firstDirectPlan,
      firstDirectBytes
    );
    assert(firstDirectWritten == firstDirectPlan.linkedLength);
    utf8 thirdLinkedRootSource = freezeUtf8(firstDirectBytes);

    LinkPlan secondDirectPlan = planConstantImport(
      secondDirectSource,
      thirdLinkedRootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (secondDirectPlan.valid) {} else {
      drop(thirdLinkedRootSource);
      drop(firstDirectArena);
      drop(secondLinkedRootSource);
      drop(secondRootArena);
      drop(firstLinkedRootSource);
      drop(firstRootArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new SixPairCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, secondDirectPlan.linkedLength);
    long finalWritten = writeConstantImport(
      secondDirectSource,
      thirdLinkedRootSource,
      secondDirectPlan,
      finalBytes
    );
    assert(finalWritten == secondDirectPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(thirdLinkedRootSource);
    drop(firstDirectArena);
    drop(secondLinkedRootSource);
    drop(secondRootArena);
    drop(firstLinkedRootSource);
    drop(firstRootArena);
    drop(linkedSecondDependentSource);
    drop(secondDependentArena);
    drop(linkedFirstDependentSource);
    drop(firstDependentArena);
    return new SixPairCompilation(compiled.length, compiled.codeStart);
  }
}
