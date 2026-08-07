//! Links one public constant leaf shared by two direct constant dependents.

module wheeler.compiler.graphs.shared.three_direct_leaf;

import wheeler.compiler.compiler_core;
import wheeler.compiler.module_linker;

classical class ThreeDirectLeafGraph {
  /// Carries one shared three-module graph compilation result.
  public record ThreeDirectLeafCompilation(long length, long codeStart) {}

  /// Compiles two root-ordered constant dependents after exact shared-leaf deduplication.
  public ThreeDirectLeafCompilation compileThreeDirectLeafGraph(
    borrow utf8 leafSource,
    borrow utf8 firstDependentSource,
    borrow utf8 secondDependentSource,
    borrow utf8 rootSource,
    borrow mut bytes output
  ) {
    LinkPlan firstLeafPlan = planPrivateConstantImport(
      leafSource,
      firstDependentSource,
      /* expectedImportCount= */ 1
    );
    if (firstLeafPlan.valid) {} else {
      assert(0 == 1);
    }

    region firstDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes firstDependentBytes = allocateBytes(firstDependentArena, firstLeafPlan.linkedLength);
    long firstDependentWritten = writeConstantImport(
      leafSource,
      firstDependentSource,
      firstLeafPlan,
      firstDependentBytes
    );
    assert(firstDependentWritten == firstLeafPlan.linkedLength);
    utf8 linkedFirstDependent = freezeUtf8(firstDependentBytes);

    LinkPlan secondLeafPlan = planPrivateConstantImport(
      leafSource,
      secondDependentSource,
      /* expectedImportCount= */ 1
    );
    if (secondLeafPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondDependentArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes secondDependentBytes = allocateBytes(secondDependentArena, secondLeafPlan.linkedLength);
    long secondDependentWritten = writeConstantImport(
      leafSource,
      secondDependentSource,
      secondLeafPlan,
      secondDependentBytes
    );
    assert(secondDependentWritten == secondLeafPlan.linkedLength);
    utf8 linkedSecondDependent = freezeUtf8(secondDependentBytes);

    LinkPlan leafPlan = planConstantImport(leafSource, rootSource, /* expectedImportCount= */ 3);
    if (leafPlan.valid) {} else {
      assert(0 == 1);
    }

    region rootArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes rootBytes = allocateBytes(rootArena, leafPlan.linkedLength);
    long rootWritten = writeConstantImport(leafSource, rootSource, leafPlan, rootBytes);
    assert(rootWritten == leafPlan.linkedLength);
    utf8 linkedRoot = freezeUtf8(rootBytes);

    LinkPlan secondPlan = planTrailingSharedResolvedPublicConstantImport(
      linkedSecondDependent,
      linkedRoot,
      /* expectedImportCount= */ 3
    );
    if (secondPlan.valid) {} else {
      assert(0 == 1);
    }

    region secondRootArena = new region(
      /* bytes= */ MAX_LINKED_SOURCE_BYTES,
      /* allocations= */ 1
    );
    bytes secondRootBytes = allocateBytes(secondRootArena, secondPlan.linkedLength);
    long secondRootWritten = writeConstantImport(
      linkedSecondDependent,
      linkedRoot,
      secondPlan,
      secondRootBytes
    );
    assert(secondRootWritten == secondPlan.linkedLength);
    utf8 rootWithSecond = freezeUtf8(secondRootBytes);

    LinkPlan firstPlan = planTrailingSharedResolvedPublicConstantImport(
      linkedFirstDependent,
      rootWithSecond,
      /* expectedImportCount= */ 3
    );
    if (firstPlan.valid) {} else {
      assert(0 == 1);
    }

    region finalArena = new region(/* bytes= */ MAX_LINKED_SOURCE_BYTES, /* allocations= */ 1);
    bytes finalBytes = allocateBytes(finalArena, firstPlan.linkedLength);
    long finalWritten = writeConstantImport(
      linkedFirstDependent,
      rootWithSecond,
      firstPlan,
      finalBytes
    );
    assert(finalWritten == firstPlan.linkedLength);
    utf8 finalSource = freezeUtf8(finalBytes);
    CoreCompilation core = compileMinimalCore(finalSource, output);
    ThreeDirectLeafCompilation compiled = new ThreeDirectLeafCompilation(
      core.length,
      core.codeStart
    );

    drop(finalSource);
    drop(finalArena);
    drop(rootWithSecond);
    drop(secondRootArena);
    drop(linkedRoot);
    drop(rootArena);
    drop(linkedSecondDependent);
    drop(secondDependentArena);
    drop(linkedFirstDependent);
    drop(firstDependentArena);
    return compiled;
  }
}
