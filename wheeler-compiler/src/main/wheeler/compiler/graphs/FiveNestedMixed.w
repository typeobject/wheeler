//! Resolves a two-leaf fork through one dependent beside a direct root module.

module wheeler.compiler.graphs.five_nested_mixed;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveNestedMixed {
  private const long TWO_IMPORTS = 2;

  /// Carries private nested-branch compilation bounds.
  public record FiveNestedMixedCompilation(long length, long codeStart) {}

  private FiveNestedMixedCompilation compileIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 middleSource,
    borrow utf8 dependentSource,
    borrow utf8 directSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      middleSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (firstLeafPlan.valid) {} else {
      return new FiveNestedMixedCompilation(0, 0);
    }

    region firstLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstLeafBytes = allocateBytes(firstLeafArena, firstLeafPlan.linkedLength);
    long firstLeafWritten = writeConstantImport(
      firstLeafSource,
      middleSource,
      firstLeafPlan,
      firstLeafBytes
    );
    assert(firstLeafWritten == firstLeafPlan.linkedLength);
    utf8 firstLinkedMiddleSource = freezeUtf8(firstLeafBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedMiddleSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (secondLeafPlan.valid) {} else {
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedMixedCompilation(0, 0);
    }

    region secondLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondLeafBytes = allocateBytes(secondLeafArena, secondLeafPlan.linkedLength);
    long secondLeafWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedMiddleSource,
      secondLeafPlan,
      secondLeafBytes
    );
    assert(secondLeafWritten == secondLeafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(secondLeafBytes);

    LinkPlan dependentPlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 1
    );
    if (dependentPlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(secondLeafArena);
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedMixedCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, dependentPlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      dependentPlan,
      dependentBytes
    );
    assert(dependentWritten == dependentPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(secondLeafArena);
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedMixedCompilation(0, 0);
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

    LinkPlan directPlan = planConstantImport(
      directSource,
      firstLinkedRootSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (directPlan.valid) {} else {
      drop(firstLinkedRootSource);
      drop(rootArena);
      drop(linkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(secondLeafArena);
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedMixedCompilation(0, 0);
    }

    region finalArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, directPlan.linkedLength);
    long finalWritten = writeConstantImport(
      directSource,
      firstLinkedRootSource,
      directPlan,
      finalBytes
    );
    assert(finalWritten == directPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(finalBytes);
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(finalArena);
    drop(firstLinkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(secondLeafArena);
    drop(firstLinkedMiddleSource);
    drop(firstLeafArena);
    return new FiveNestedMixedCompilation(compiled.length, compiled.codeStart);
  }

  private FiveNestedMixedCompilation compileRemainder(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 middleSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveNestedMixedCompilation compiled = compileIfOrdered(
      firstLeafSource,
      secondLeafSource,
      middleSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileIfOrdered(
      firstLeafSource,
      secondLeafSource,
      middleSource,
      secondRemainingSource,
      firstRemainingSource,
      rootSource,
      output
    );
  }

  private FiveNestedMixedCompilation compileWithMiddle(
    borrow utf8 middleSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 thirdRemainingSource,
    borrow utf8 fourthRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveNestedMixedCompilation compiled = compileRemainder(
      firstRemainingSource,
      secondRemainingSource,
      middleSource,
      thirdRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      firstRemainingSource,
      thirdRemainingSource,
      middleSource,
      secondRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      firstRemainingSource,
      fourthRemainingSource,
      middleSource,
      secondRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      secondRemainingSource,
      thirdRemainingSource,
      middleSource,
      firstRemainingSource,
      fourthRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileRemainder(
      secondRemainingSource,
      fourthRemainingSource,
      middleSource,
      firstRemainingSource,
      thirdRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileRemainder(
      thirdRemainingSource,
      fourthRemainingSource,
      middleSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
  }

  /// Compiles a two-leaf fork through a dependent beside one direct import.
  public FiveNestedMixedCompilation compileFiveNestedForkAndDirect(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 fifthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    FiveNestedMixedCompilation compiled = compileWithMiddle(
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

    compiled = compileWithMiddle(
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

    compiled = compileWithMiddle(
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

    compiled = compileWithMiddle(
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

    return compileWithMiddle(
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
