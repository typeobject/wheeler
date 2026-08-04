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

  /// Compiles one exact planned fork below one parent.
  public NestedFourCompilation compileForkThenParentIfOrdered(
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

    region firstArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region secondArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region parentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

  /// Compiles one exact planned uneven fork.
  public NestedFourCompilation compileUnevenForkIfOrdered(
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

    region middleArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region dependentArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region otherArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
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

}
