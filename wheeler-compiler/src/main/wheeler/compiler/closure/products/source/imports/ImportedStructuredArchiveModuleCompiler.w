//! Materializes dependency call targets before archive-owned structured compilation.

module wheeler.compiler.closure.imported_structured_archive_module_compiler;

import wheeler.compiler.closure.archive_structured_source_module_compiler;
import wheeler.compiler.closure.imported_call_qualifier_products;
import wheeler.compiler.closure.imported_source_call_targets;
import wheeler.compiler.closure.source_product_artifact;

classical class ImportedStructuredArchiveModuleCompiler {
  /// Publishes one archive module from closed value and direct-callable products.
  public SourceProductArtifactPlan compileStructuredArchiveModuleWithImportedTargets(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long moduleOwner,
    long firstCallable,
    long callableCount,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    long importedValueCount,
    borrow mut words importedValueRows,
    borrow byteview importedValueNames,
    borrow mut words importedValueNameStarts,
    long dependencyCount,
    borrow mut words dependencyRows,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words callableEffects,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow byteview callableIdentities,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    region targets = new region(/* bytes= */ 1703936, /* allocations= */ 4);
    words targetRows = allocate(targets, /* length= */ 32768);
    words targetParameterRows = allocate(targets, /* length= */ 32768);
    bytes targetNames = allocateBytes(targets, /* length= */ 1048576);
    bytes targetIdentities = allocateBytes(targets, /* length= */ 131072);
    ImportedSourceCallTargetPlan targetPlan = materializeImportedSourceCallTargets(
      dependencyCount,
      dependencyRows,
      callableNames,
      callableNameStarts,
      callableNameLengths,
      callableFirstParameters,
      callableParameterCounts,
      callableResultTypes,
      callableEffects,
      parameterTypes,
      parameterModes,
      callableIdentities,
      targetRows,
      targetParameterRows,
      targetNames,
      targetIdentities
    );
    assert(targetPlan.valid);
    SourceProductArtifactPlan result = compileStructuredArchiveModuleWithTargetView(
      archive,
      sourceStart,
      sourceLength,
      moduleOwner,
      firstCallable,
      callableCount,
      targetPlan.targetCount,
      targetRows,
      targetParameterRows,
      targetNames,
      targetIdentities,
      callableBodyStarts,
      callableBodyLengths,
      importedValueCount,
      importedValueRows,
      importedValueNames,
      importedValueNameStarts,
      callableFirstParameters,
      callableParameterCounts,
      callableResultTypes,
      parameterTypes,
      parameterModes,
      callableNames,
      callableNameStarts,
      callableNameLengths,
      artifact,
      identity
    );
    drop(targetIdentities);
    drop(targetNames);
    drop(targetParameterRows);
    drop(targetRows);
    drop(targets);
    return result;
  }
}
