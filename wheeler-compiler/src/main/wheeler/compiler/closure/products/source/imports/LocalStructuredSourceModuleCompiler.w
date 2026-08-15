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
    region emptyTargets = new region(/* bytes= */ 1703936, /* allocations= */ 4);
    words importedRows = allocate(emptyTargets, /* length= */ 32768);
    words importedParameterRows = allocate(emptyTargets, /* length= */ 32768);
    bytes importedNames = allocateBytes(emptyTargets, /* length= */ 1048576);
    bytes importedIdentities = allocateBytes(emptyTargets, /* length= */ 131072);
    SourceProductArtifactPlan result = compileStructuredSourceModuleWithTargets(
      source,
      archiveSourceStart,
      moduleOwner,
      firstCallable,
      callableCount,
      /* importedTargetCount= */ 0,
      importedRows,
      importedParameterRows,
      importedNames,
      importedIdentities,
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
      output,
      identity
    );
    drop(importedIdentities);
    drop(importedNames);
    drop(importedParameterRows);
    drop(importedRows);
    drop(emptyTargets);
    return result;
  }
}
