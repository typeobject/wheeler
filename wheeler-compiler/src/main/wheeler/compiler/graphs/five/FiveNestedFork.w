//! Resolves one two-leaf fork through a second two-input dependent.

module wheeler.compiler.graphs.five_nested_fork;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class CompilerFiveNestedFork {
  private const long TWO_IMPORTS = 2;

  /// Carries private nested-fork compilation bounds.
  public record FiveNestedForkCompilation(long length, long codeStart) {}

  /// Compiles one exact planned pair of nested fork levels.
  public FiveNestedForkCompilation compileFiveNestedForkIfOrdered(
    borrow utf8 firstLeafSource,
    borrow utf8 secondLeafSource,
    borrow utf8 middleSource,
    borrow utf8 sideLeafSource,
    borrow utf8 dependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      firstLeafSource,
      middleSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (firstLeafPlan.valid) {} else {
      return new FiveNestedForkCompilation(0, 0);
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
      return new FiveNestedForkCompilation(0, 0);
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

    LinkPlan middlePlan = planPrivateResolvedConstantImport(
      linkedMiddleSource,
      dependentSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (middlePlan.valid) {} else {
      drop(linkedMiddleSource);
      drop(secondLeafArena);
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedForkCompilation(0, 0);
    }

    region dependentArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes dependentBytes = allocateBytes(dependentArena, middlePlan.linkedLength);
    long middleWritten = writeConstantImport(
      linkedMiddleSource,
      dependentSource,
      middlePlan,
      dependentBytes
    );
    assert(middleWritten == middlePlan.linkedLength);
    utf8 firstLinkedDependentSource = freezeUtf8(dependentBytes);

    LinkPlan sideLeafPlan = planPrivateConstantImport(
      sideLeafSource,
      firstLinkedDependentSource,
      /* expectedImportCount= */ TWO_IMPORTS
    );
    if (sideLeafPlan.valid) {} else {
      drop(firstLinkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(secondLeafArena);
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedForkCompilation(0, 0);
    }

    region sideLeafArena = new region(/* bytes= */ 16384, /* allocations= */ 1);
    bytes sideLeafBytes = allocateBytes(sideLeafArena, sideLeafPlan.linkedLength);
    long sideLeafWritten = writeConstantImport(
      sideLeafSource,
      firstLinkedDependentSource,
      sideLeafPlan,
      sideLeafBytes
    );
    assert(sideLeafWritten == sideLeafPlan.linkedLength);
    utf8 linkedDependentSource = freezeUtf8(sideLeafBytes);

    LinkPlan rootPlan = planResolvedConstantImport(
      linkedDependentSource,
      rootSource,
      /* expectedImportCount= */ 1
    );
    if (rootPlan.valid) {} else {
      drop(linkedDependentSource);
      drop(sideLeafArena);
      drop(firstLinkedDependentSource);
      drop(dependentArena);
      drop(linkedMiddleSource);
      drop(secondLeafArena);
      drop(firstLinkedMiddleSource);
      drop(firstLeafArena);
      return new FiveNestedForkCompilation(0, 0);
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
    CoreCompilation compiled = compileMinimalCore(linkedRootSource, output);
    drop(linkedRootSource);
    drop(rootArena);
    drop(linkedDependentSource);
    drop(sideLeafArena);
    drop(firstLinkedDependentSource);
    drop(dependentArena);
    drop(linkedMiddleSource);
    drop(secondLeafArena);
    drop(firstLinkedMiddleSource);
    drop(firstLeafArena);
    return new FiveNestedForkCompilation(compiled.length, compiled.codeStart);
  }

}
