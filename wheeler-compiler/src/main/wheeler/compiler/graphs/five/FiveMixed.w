//! Resolves one constant edge beside three direct root modules.

module wheeler.compiler.graphs.five_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.imported_helpers;
import wheeler.compiler.module_linker;

classical class CompilerFiveMixed {
  private const long FOUR_IMPORTS = 4;

  /// Carries private mixed five-module compilation bounds.
  public record FiveMixedCompilation(long length, long codeStart) {}

  private FiveMixedCompilation compileHelperChainAndDirectConstants(
    borrow utf8 linkedHelperSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan helperPlan = planResolvedHelperImport(
      linkedHelperSource,
      rootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (helperPlan.valid) {} else {
      return new FiveMixedCompilation(0, 0);
    }

    region helperArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes helperBytes = allocateBytes(helperArena, helperPlan.linkedLength);
    long helperWritten = writeConstantImport(
      linkedHelperSource,
      rootSource,
      helperPlan,
      helperBytes
    );
    assert(helperWritten == helperPlan.linkedLength);
    utf8 helperLinkedRoot = freezeUtf8(helperBytes);

    LinkPlan firstPlan = planConstantImport(
      firstDirectSource,
      helperLinkedRoot,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (firstPlan.valid) {} else {
      drop(helperLinkedRoot);
      drop(helperArena);
      return new FiveMixedCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstDirectSource,
      helperLinkedRoot,
      firstPlan,
      firstBytes
    );
    assert(firstWritten == firstPlan.linkedLength);
    utf8 firstLinkedRoot = freezeUtf8(firstBytes);

    LinkPlan secondPlan = planConstantImport(
      secondDirectSource,
      firstLinkedRoot,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (secondPlan.valid) {} else {
      drop(firstLinkedRoot);
      drop(firstArena);
      drop(helperLinkedRoot);
      drop(helperArena);
      return new FiveMixedCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondDirectSource,
      firstLinkedRoot,
      secondPlan,
      secondBytes
    );
    assert(secondWritten == secondPlan.linkedLength);
    utf8 secondLinkedRoot = freezeUtf8(secondBytes);

    LinkPlan thirdPlan = planConstantImport(
      thirdDirectSource,
      secondLinkedRoot,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (thirdPlan.valid) {} else {
      drop(secondLinkedRoot);
      drop(secondArena);
      drop(firstLinkedRoot);
      drop(firstArena);
      drop(helperLinkedRoot);
      drop(helperArena);
      return new FiveMixedCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, thirdPlan.linkedLength);
    long finalWritten = writeConstantImport(
      thirdDirectSource,
      secondLinkedRoot,
      thirdPlan,
      finalBytes
    );
    assert(finalWritten == thirdPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(finalBytes);
    CoreCompilation core = compileMinimalCoreWithHelperOwner(
      linkedRoot,
      output,
      helperPlan.linkedOwnerStart,
      helperPlan.linkedOwnerLength,
      helperPlan.importedHelperCount
    );
    drop(linkedRoot);
    drop(finalArena);
    drop(secondLinkedRoot);
    drop(secondArena);
    drop(firstLinkedRoot);
    drop(firstArena);
    drop(helperLinkedRoot);
    drop(helperArena);
    return new FiveMixedCompilation(core.length, core.codeStart);
  }

  /// Compiles one exact planned chain beside three direct imports.
  public FiveMixedCompilation compileFiveChainAndDirectsIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 dependentSource,
    borrow utf8 firstDirectSource,
    borrow utf8 secondDirectSource,
    borrow utf8 thirdDirectSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan dependentPlan = planPrivateConstantImport(
      leafSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      return new FiveMixedCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, dependentPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      leafSource,
      dependentSource,
      dependentPlan,
      dependentBytes
    );
    assert(dependentWritten == dependentPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan helperProbe = planResolvedHelperImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (helperProbe.valid) {
      FiveMixedCompilation helperCompilation = compileHelperChainAndDirectConstants(
        linkedDependentSource,
        firstDirectSource,
        secondDirectSource,
        thirdDirectSource,
        rootSource,
        output
      );
      drop(linkedDependentSource);
      drop(dependentArena);
      return helperCompilation;
    }

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveMixedCompilation(0, 0);
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
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (firstDirectPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveMixedCompilation(0, 0);
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
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (secondDirectPlan.valid) {} else {
      drop(secondLinkedRootSource);
      drop(firstDirectArena);
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveMixedCompilation(0, 0);
    }

    region secondDirectArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes secondDirectBytes = allocateBytes(secondDirectArena, secondDirectPlan.linkedLength);
    long secondDirectWritten = writeConstantImport(
      secondDirectSource,
      secondLinkedRootSource,
      secondDirectPlan,
      secondDirectBytes
    );
    assert(secondDirectWritten == secondDirectPlan.linkedLength);
    utf8 thirdLinkedRootSource = freezeUtf8(secondDirectBytes);

    LinkPlan thirdDirectPlan = planConstantImport(
      thirdDirectSource,
      thirdLinkedRootSource,
      /* expectedImportCount= */ FOUR_IMPORTS
    );
    if (thirdDirectPlan.valid) {} else {
      drop(thirdLinkedRootSource);
      drop(secondDirectArena);
      drop(secondLinkedRootSource);
      drop(firstDirectArena);
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      return new FiveMixedCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, thirdDirectPlan.linkedLength);
    long finalWritten = writeConstantImport(
      thirdDirectSource,
      thirdLinkedRootSource,
      thirdDirectPlan,
      finalBytes
    );
    assert(finalWritten == thirdDirectPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(thirdLinkedRootSource);
    drop(secondDirectArena);
    drop(secondLinkedRootSource);
    drop(firstDirectArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    return new FiveMixedCompilation(compiled.length, compiled.codeStart);
  }

}
