//! Resolves two independent constant edges beside one direct root module.

module wheeler.compiler.graphs.five_pairs;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFivePairs {
  private const long THREE_IMPORTS = 3;

  /// Carries private paired-branch compilation bounds.
  public record FivePairCompilation(long length, long codeStart) {}

  /// Compiles one exact planned pair of chains beside one direct import.
  public FivePairCompilation compileFivePairsAndDirectIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondLeafSource,
    borrow utf8 secondDependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstLeafPlan.valid) {} else {
      return new FivePairCompilation(0, 0);
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
      return new FivePairCompilation(0, 0);
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
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (firstRootPlan.valid) {} else {
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FivePairCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, firstRootPlan.linkedLength);
    long firstRootWritten = writeConstantImport(
      linkedFirstDependentSource,
      rootSource,
      firstRootPlan,
      rootBytes
    );
    assert(firstRootWritten == firstRootPlan.linkedLength);
    utf8 firstLinkedRootSource = freezeUtf8(rootBytes);

    LinkPlan secondRootPlan = planResolvedConstantImport(
      linkedSecondDependentSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (secondRootPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FivePairCompilation(0, 0);
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

    LinkPlan directPlan = planConstantImport(
      directSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (directPlan.valid) {} else {
      drop(secondLinkedRootSource);
      drop(secondRootArena);
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedSecondDependentSource);
      drop(secondDependentArena);
      drop(linkedFirstDependentSource);
      drop(firstDependentArena);
      return new FivePairCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      secondLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(secondRootArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedSecondDependentSource);
    drop(secondDependentArena);
    drop(linkedFirstDependentSource);
    drop(firstDependentArena);
    return new FivePairCompilation(compiled.length, compiled.codeStart);
  }

}
