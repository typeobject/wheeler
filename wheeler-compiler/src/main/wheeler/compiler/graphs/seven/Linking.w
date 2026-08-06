//! Applies one validated seven-module constant edge.

module wheeler.compiler.graphs.seven.linking;

import wheeler.compiler.module_linker;

classical class SevenGraphLinking {
  /// Links one private dependency into a dependent source.
  public utf8 linkSevenPrivateConstant(
    borrow utf8 importedSource,
    borrow utf8 dependentSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateConstantImport(
      importedSource,
      dependentSource,
      expectedImportCount
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, dependentSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  /// Links one resolved private dependency into its dependent source.
  public utf8 linkSevenPrivateResolvedConstant(
    borrow utf8 importedSource,
    borrow utf8 dependentSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planPrivateResolvedConstantImport(
      importedSource,
      dependentSource,
      expectedImportCount
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, dependentSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  /// Links one resolved dependency while deduplicating its shared declarations.
  public utf8 linkSevenSharedResolvedConstant(
    borrow utf8 importedSource,
    borrow utf8 dependentSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planSharedResolvedConstantImport(
      importedSource,
      dependentSource,
      expectedImportCount
    );
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, dependentSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  /// Links one resolved dependency into a root source.
  public utf8 linkSevenResolvedConstant(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planResolvedConstantImport(importedSource, rootSource, expectedImportCount);
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }

  /// Links one direct dependency into a root source.
  public utf8 linkSevenDirectConstant(
    borrow utf8 importedSource,
    borrow utf8 rootSource,
    long expectedImportCount,
    borrow mut region arena
  ) {
    LinkPlan plan = planConstantImport(importedSource, rootSource, expectedImportCount);
    assert(plan.valid);
    bytes linkedBytes = allocateBytes(arena, plan.linkedLength);
    long written = writeConstantImport(importedSource, rootSource, plan, linkedBytes);
    assert(written == plan.linkedLength);
    return freezeUtf8(linkedBytes);
  }
}
