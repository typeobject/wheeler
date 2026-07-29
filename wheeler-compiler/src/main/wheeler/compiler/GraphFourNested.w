//! Resolves the two nested four-module constant trees.

module wheeler.compiler.compiler_graph_four_nested;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerGraphFourNested {
  /// Carries private nested four-module compilation bounds.
  public record NestedFourCompilation(long length, long codeStart) {}

  private NestedFourCompilation compileNestedSource(borrow utf8 source, borrow mut bytes output) {
    CoreCompilation compiled = compileMinimalCore(source, output);
    return new NestedFourCompilation(compiled.length, compiled.codeStart);
  }

  private NestedFourCompilation compileForkThenParentIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 forkSource,
    borrow utf8 parentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      forkSource,
      /* expectedImportCount= */ 2
    );
    if (firstLeafPlan.valid) {} else {
      return new NestedFourCompilation(0, 0);
    }

    region firstArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes firstBytes = allocateBytes(firstArena, firstLeafPlan.linkedLength);
    long firstWritten = writeConstantImport(
      firstLeafSource,
      forkSource,
      firstLeafPlan,
      firstBytes
    );
    assert(firstWritten == firstLeafPlan.linkedLength);
    utf8 firstLinkedForkSource = freezeUtf8(firstBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      secondLeafSource,
      firstLinkedForkSource,
      /* expectedImportCount= */ 2
    );
    if (secondLeafPlan.valid) {} else {
      drop(firstLinkedForkSource);
      drop(firstArena);
      return new NestedFourCompilation(0, 0);
    }

    region secondArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes secondBytes = allocateBytes(secondArena, secondLeafPlan.linkedLength);
    long secondWritten = writeConstantImport(
      secondLeafSource,
      firstLinkedForkSource,
      secondLeafPlan,
      secondBytes
    );
    assert(secondWritten == secondLeafPlan.linkedLength);
    utf8 linkedForkSource = freezeUtf8(secondBytes);

    LinkPlan parentPlan = planPrivateResolvedConstantImport(
      linkedForkSource,
      parentSource,
      /* expectedImportCount= */ 1
    );
    if (parentPlan.valid) {} else {
      drop(linkedForkSource);
      drop(secondArena);
      drop(firstLinkedForkSource);
      drop(firstArena);
      return new NestedFourCompilation(0, 0);
    }

    region parentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes parentBytes = allocateBytes(parentArena, parentPlan.linkedLength);
    long parentWritten = writeConstantImport(
      linkedForkSource,
      parentSource,
      parentPlan,
      parentBytes
    );
    assert(parentWritten == parentPlan.linkedLength);
    utf8 linkedParentSource = freezeUtf8(parentBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedParentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedParentSource);
      drop(parentArena);
      drop(linkedForkSource);
      drop(secondArena);
      drop(firstLinkedForkSource);
      drop(firstArena);
      return new NestedFourCompilation(0, 0);
    }

    region rootArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, rootPlan.linkedLength);
    long rootWritten = writeConstantImport(linkedParentSource, rootSource, rootPlan, rootBytes);
    assert(rootWritten == rootPlan.linkedLength);
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    NestedFourCompilation compiled = compileNestedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedParentSource);
    drop(parentArena);
    drop(linkedForkSource);
    drop(secondArena);
    drop(firstLinkedForkSource);
    drop(firstArena);
    return compiled;
  }

  private NestedFourCompilation compileForkThenParentFromPair(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    NestedFourCompilation compiled = compileForkThenParentIfOrdered(
      firstLeafSource,
      secondLeafSource,
      firstSource,
      secondSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileForkThenParentIfOrdered(
      firstLeafSource,
      secondLeafSource,
      secondSource,
      firstSource,
      rootSource,
      output
    );
  }

  /// Compiles a two-leaf fork below one parent and the root.
  public NestedFourCompilation compileFourForkThenParent(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    NestedFourCompilation compiled = compileForkThenParentFromPair(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileForkThenParentFromPair(
      firstSource,
      thirdSource,
      secondSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileForkThenParentFromPair(
      firstSource,
      fourthSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileForkThenParentFromPair(
      secondSource,
      thirdSource,
      firstSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileForkThenParentFromPair(
      secondSource,
      fourthSource,
      firstSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileForkThenParentFromPair(
      thirdSource,
      fourthSource,
      firstSource,
      secondSource,
      rootSource,
      output
    );
  }

  private NestedFourCompilation compileUnevenForkIfOrdered(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 otherLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan leafPlan = planPrivateConstantImport(
      leafSource,
      middleSource,
      /* expectedImportCount= */ 1
    );
    if (leafPlan.valid) {} else {
      return new NestedFourCompilation(0, 0);
    }

    region middleArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes middleBytes = allocateBytes(middleArena, leafPlan.linkedLength);
    long middleWritten = writeConstantImport(leafSource, middleSource, leafPlan, middleBytes);
    assert(middleWritten == leafPlan.linkedLength);
    utf8 linkedMiddleSource = freezeUtf8(middleBytes);

    LinkPlan middlePlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ 2
    );
    if (middlePlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(middleArena);
      return new NestedFourCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, middlePlan.linkedLength);
    long dependentWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      middlePlan,
      dependentBytes
    );
    assert(dependentWritten == middlePlan.linkedLength);
    utf8 firstLinkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan otherLeafPlan = planPrivateConstantImport(
      otherLeafSource,
      firstLinkedDependentSource,
      /* expectedImportCount= */ 2
    );
    if (otherLeafPlan.valid) {} else {
      drop(firstLinkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new NestedFourCompilation(0, 0);
    }

    region otherArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes otherBytes = allocateBytes(otherArena, otherLeafPlan.linkedLength);
    long otherWritten = writeConstantImport(
      otherLeafSource,
      firstLinkedDependentSource,
      otherLeafPlan,
      otherBytes
    );
    assert(otherWritten == otherLeafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(otherBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(otherArena);
      drop(firstLinkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(middleArena);
      return new NestedFourCompilation(0, 0);
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
    utf8 linkedRootSource = freezeUtf8(rootBytes);
    NestedFourCompilation compiled = compileNestedSource(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(otherArena);
    drop(firstLinkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(middleArena);
    return compiled;
  }

  private NestedFourCompilation compileUnevenFromDirectedPair(
    borrow utf8 leafSource,
    borrow utf8 middleSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    NestedFourCompilation compiled = compileUnevenForkIfOrdered(
      leafSource,
      middleSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileUnevenForkIfOrdered(
      leafSource,
      middleSource,
      secondRemainingSource,
      firstRemainingSource,
      rootSource,
      output
    );
  }

  private NestedFourCompilation compileUnevenFromPair(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 firstRemainingSource,
    borrow utf8 secondRemainingSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    NestedFourCompilation compiled = compileUnevenFromDirectedPair(
      firstSource,
      secondSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileUnevenFromDirectedPair(
      secondSource,
      firstSource,
      firstRemainingSource,
      secondRemainingSource,
      rootSource,
      output
    );
  }

  /// Compiles a two-leaf fork whose first arm has one intermediate module.
  public NestedFourCompilation compileFourUnevenFork(
    borrow utf8 firstSource,
    borrow utf8 secondSource,
    borrow utf8 thirdSource,
    borrow utf8 fourthSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    NestedFourCompilation compiled = compileUnevenFromPair(
      firstSource,
      secondSource,
      thirdSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileUnevenFromPair(
      firstSource,
      thirdSource,
      secondSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileUnevenFromPair(
      firstSource,
      fourthSource,
      secondSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileUnevenFromPair(
      secondSource,
      thirdSource,
      firstSource,
      fourthSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    compiled = compileUnevenFromPair(
      secondSource,
      fourthSource,
      firstSource,
      thirdSource,
      rootSource,
      output
    );
    if (0 < compiled.length) {
      return compiled;
    }

    return compileUnevenFromPair(
      thirdSource,
      fourthSource,
      firstSource,
      secondSource,
      rootSource,
      output
    );
  }
}
