//! Resolves a two-leaf constant fork beside two direct root modules.

module wheeler.compiler.graphs.five_fork_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveForkMixed {
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;

  /// Carries private fork-and-direct compilation bounds.
  public record FiveForkMixedCompilation(long length, long codeStart) {}

  /// Compiles one exact planned fork beside two direct imports.
  public FiveForkMixedCompilation compileFiveForkAndTwoDirectsIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      dependentSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (firstLeafPlan.valid) {} else {
      return new FiveForkMixedCompilation(0, 0);
    }

    region firstLeafArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstLeafBytes = allocateBytes(firstLeafArena, firstLeafPlan.linkedLength);
    long firstLeafWritten = writeConstantImport(
      firstLeafSource,
      dependentSource,
      firstLeafPlan,
      firstLeafBytes
    );
    assert(firstLeafWritten == firstLeafPlan.linkedLength);
    utf8 firstLinkedDependentSource = freezeUtf8(firstLeafBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedDependentSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (secondLeafPlan.valid) {} else {
      drop(firstLinkedDependentSource);
      drop(firstLeafArena);
      return new FiveForkMixedCompilation(0, 0);
    }

    region secondLeafArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes secondLeafBytes = allocateBytes(secondLeafArena, secondLeafPlan.linkedLength);
    long secondLeafWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedDependentSource,
      secondLeafPlan,
      secondLeafBytes
    );
    assert(secondLeafWritten == secondLeafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(secondLeafBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(secondLeafArena);
      drop(firstLinkedDependentSource);
      drop(firstLeafArena);
      return new FiveForkMixedCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (firstDirectPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(secondLeafArena);
      drop(firstLinkedDependentSource);
      drop(firstLeafArena);
      return new FiveForkMixedCompilation(0, 0);
    }

    region firstDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes firstDirectBytes = allocateBytes(firstDirectArena, firstDirectPlan.linkedLength);
    long firstDirectWritten = writeConstantImport(
      firstDirectSource,
      firstLinkedRootSource,
      firstDirectPlan,
      firstDirectBytes
    );
    assert(firstDirectWritten == firstDirectPlan.linkedLength);
    utf8 secondLinkedRootSource = freezeUtf8(firstDirectBytes);

    LinkPlan secondDirectPlan = planConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      /* expectedImportCount= */ THREE_IMPORTS
    );
    if (secondDirectPlan.valid) {} else {
      drop(secondLinkedRootSource);
      drop(firstDirectArena);
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(secondLeafArena);
      drop(firstLinkedDependentSource);
      drop(firstLeafArena);
      return new FiveForkMixedCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, secondDirectPlan.linkedLength);
    long finalWritten = writeConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      secondDirectPlan,
      finalBytes
    );
    assert(finalWritten == secondDirectPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(secondLinkedRootSource);
    drop(firstDirectArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(secondLeafArena);
    drop(firstLinkedDependentSource);
    drop(firstLeafArena);
    return new FiveForkMixedCompilation(compiled.length, compiled.codeStart);
  }

}
