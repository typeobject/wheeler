//! Resolves a two-leaf constant fork beside two direct root modules.

module wheeler.compiler.graphs.five_fork_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveForkMixed {
  private const long TWO_IMPORTS = 2;
  private const long THREE_IMPORTS = 3;

  /// Carries private fork-and-direct compilation bounds.
  public record FiveForkMixedCompilation(long length, long codeStart) {}

  private FiveForkMixedCompilation compileIfOrdered(
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

    region firstLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
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

    region secondLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
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

    region firstDirectArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
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

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
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

  private FiveForkMixedCompilation compileWithDependent(
    borrow utf8 dependentSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 fourthRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveForkMixedCompilation compiled = compileIfOrdered(
      firstRemainingSource,
      secondRemainingSource,
      dependentSource,
      thirdRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileIfOrdered(
      firstRemainingSource,
      thirdRemainingSource,
      dependentSource,
      secondRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileIfOrdered(
      firstRemainingSource,
      fourthRemainingSource,
      dependentSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileIfOrdered(
      secondRemainingSource,
      thirdRemainingSource,
      dependentSource,
      firstRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileIfOrdered(
      secondRemainingSource,
      fourthRemainingSource,
      dependentSource,
      firstRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileIfOrdered(
      thirdRemainingSource,
      fourthRemainingSource,
      dependentSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
  }

  /// Compiles a two-leaf fork beside two direct root imports.
  public FiveForkMixedCompilation compileFiveForkAndTwoDirects(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveForkMixedCompilation compiled = compileWithDependent(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileWithDependent(
      secondSource,
      firstSource,
      thirdSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileWithDependent(
      thirdSource,
      firstSource,
      secondSource,
      fourthSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileWithDependent(
      fourthSource,
      firstSource,
      secondSource,
      thirdSource,
      fifthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileWithDependent(
      fifthSource,
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
  }
}
