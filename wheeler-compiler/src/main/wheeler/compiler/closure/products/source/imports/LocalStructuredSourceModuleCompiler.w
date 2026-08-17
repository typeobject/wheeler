//! Supplies the empty imported-target view for local structured compilation.

module wheeler.compiler.closure.local_structured_source_module_compiler;

import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.structured_source_module_compiler;

classical class LocalStructuredSourceModuleCompiler {
  /// Publishes one verified local-only artifact without scalar-helper reparsing.
  public SourceProductArtifactPlan compileStructuredSourceModule(
    borrow utf8 source,
    long archiveSourceStart,
    long moduleOwner,
    long firstCallable,
    long callableCount,
    borrow mut words bodyStarts,
    borrow mut words bodyLengths,
    long symbolCount,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolTypes,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    long signatureTypeCount,
    borrow mut words signatureTypes,
    borrow mut words parameterCounts,
    borrow byteview strings,
    long stringBytes,
    long stringCount,
    borrow mut words stringStarts,
    borrow mut words stringLengths,
    borrow mut words functionNameIds,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    region emptyTargets = new region(/* bytes= */ 32832, /* allocations= */ 8);
    words importedRows = allocate(emptyTargets, /* length= */ 1);
    words importedParameterRows = allocate(emptyTargets, /* length= */ 1);
    bytes importedNames = allocateBytes(emptyTargets, /* length= */ 1);
    bytes importedIdentities = allocateBytes(emptyTargets, /* length= */ 1);
    region emptyRelocations = new region(/* bytes= */ 16384, /* allocations= */ 3);
    words relocationRows = allocate(emptyRelocations, /* length= */ 768);
    words relocationOwners = allocate(emptyRelocations, /* length= */ 256);
    bytes relocationIdentities = allocateBytes(emptyRelocations, /* length= */ 8192);
    words qualifierNameStarts = allocate(emptyTargets, /* length= */ 1);
    words qualifierNameLengths = allocate(emptyTargets, /* length= */ 1);
    words qualifierRanks = allocate(emptyTargets, /* length= */ 1);
    words callableEffects = allocate(emptyTargets, /* length= */ 4096);
    SourceProductArtifactPlan result = compileStructuredSourceModuleWithTargets(
      source,
      archiveSourceStart,
      moduleOwner,
      firstCallable,
      callableCount,
      callableEffects,
      /* importedTargetCount= */ 0,
      importedRows,
      importedParameterRows,
      importedNames,
      importedIdentities,
      importedNames,
      qualifierNameStarts,
      qualifierNameLengths,
      qualifierRanks,
      bodyStarts,
      bodyLengths,
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved,
      signatureTypeCount,
      signatureTypes,
      parameterCounts,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      functionNameIds,
      relocationRows,
      relocationOwners,
      relocationIdentities,
      output,
      identity
    );
    drop(relocationIdentities);
    drop(relocationOwners);
    drop(relocationRows);
    drop(emptyRelocations);
    drop(callableEffects);
    drop(qualifierRanks);
    drop(qualifierNameLengths);
    drop(qualifierNameStarts);
    drop(importedIdentities);
    drop(importedNames);
    drop(importedParameterRows);
    drop(importedRows);
    drop(emptyTargets);
    return result;
  }
}
