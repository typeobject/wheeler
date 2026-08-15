//! Materializes dependency call targets before archive-owned structured compilation.

module wheeler.compiler.closure.imported_structured_archive_module_compiler;

import wheeler.compiler.closure.archive_structured_source_module_compiler;
import wheeler.compiler.closure.compiled_function_products;
import wheeler.compiler.closure.imported_call_qualifier_products;
import wheeler.compiler.closure.imported_source_call_targets;
import wheeler.compiler.closure.qualified_source_call_products;
import wheeler.compiler.closure.source_call_relocation_link_products;
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
    borrow mut words callableOwners,
    borrow byteview moduleNames,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    long finalFunctionCount,
    borrow byteview finalFunctionIdentities,
    borrow mut words hashSlots,
    borrow mut words hashFunctions,
    borrow mut words relocationRows,
    borrow mut words relocationOwners,
    borrow mut bytes relocationIdentities,
    borrow mut words resolvedInstructionTargets,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    assert(bufferLength(relocationRows) == 768);
    assert(bufferLength(relocationOwners) == 256);
    assert(bufferLength(relocationIdentities) == 8192);
    assert(bufferLength(resolvedInstructionTargets) == 131072);
    assert(bufferLength(artifact) == 32768);
    assert(bufferLength(identity) == 32);
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
    region qualifiers = new region(/* bytes= */ 1146880, /* allocations= */ 4);
    bytes qualifierNames = allocateBytes(qualifiers, /* length= */ 1048576);
    words qualifierNameStarts = allocate(qualifiers, /* length= */ 4096);
    words qualifierNameLengths = allocate(qualifiers, /* length= */ 4096);
    words qualifierDependencyRanks = allocate(qualifiers, /* length= */ 4096);
    ImportedCallQualifierPlan qualifierPlan = materializeImportedCallQualifierProducts(
      targetPlan.targetCount,
      targetRows,
      callableOwners,
      moduleNames,
      moduleNameStarts,
      moduleNameLengths,
      qualifierNames,
      qualifierNameStarts,
      qualifierNameLengths,
      qualifierDependencyRanks
    );
    assert(qualifierPlan.valid);
    region publication = new region(/* bytes= */ 1097760, /* allocations= */ 6);
    bytes stagedArtifact = allocateBytes(publication, /* length= */ 32768);
    bytes stagedIdentity = allocateBytes(publication, /* length= */ 32);
    words stagedRelocations = allocate(publication, /* length= */ 768);
    words stagedRelocationOwners = allocate(publication, /* length= */ 256);
    bytes stagedRelocationIdentities = allocateBytes(publication, /* length= */ 8192);
    words stagedInstructionTargets = allocate(publication, /* length= */ 131072);
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
      qualifierNames,
      qualifierNameStarts,
      qualifierNameLengths,
      qualifierDependencyRanks,
      callableBodyStarts,
      callableBodyLengths,
      importedValueCount,
      importedValueRows,
      importedValueNames,
      importedValueNameStarts,
      callableFirstParameters,
      callableParameterCounts,
      callableResultTypes,
      callableEffects,
      parameterTypes,
      parameterModes,
      callableNames,
      callableNameStarts,
      callableNameLengths,
      stagedRelocations,
      stagedRelocationOwners,
      stagedRelocationIdentities,
      stagedArtifact,
      stagedIdentity
    );
    region decoded = new region(/* bytes= */ 201728, /* allocations= */ 2);
    words functionRows = allocate(decoded, /* length= */ 640);
    words instructionRows = allocate(decoded, /* length= */ 24576);
    CompiledFunctionPlan compiled = indexCompiledFunctionProducts(
      stagedArtifact,
      result.length,
      functionRows,
      instructionRows
    );
    SourceCallRelocationLinkPlan linked = materializeSourceCallRelocationLinkProducts(
      callableCount,
      compiled.functionCount,
      compiled.instructionCount,
      instructionRows,
      result.relocationCount,
      stagedRelocations,
      stagedRelocationOwners,
      stagedRelocationIdentities,
      finalFunctionCount,
      finalFunctionIdentities,
      hashSlots,
      hashFunctions,
      stagedInstructionTargets
    );
    assert(linked.relocationCount == result.relocationCount);
    long artifactByte = 0;
    while (artifactByte < result.length) limit 32768 {
      setByte(artifact, artifactByte, stagedArtifact[artifactByte]);
      artifactByte += 1;
    }

    long identityByte = 0;
    while (identityByte < 32) limit 32 {
      setByte(identity, identityByte, stagedIdentity[identityByte]);
      identityByte += 1;
    }

    long relocation = 0;
    while (relocation < result.relocationCount) limit 256 {
      set(relocationRows, relocation, stagedRelocations[relocation]);
      set(relocationRows, 256 + relocation, stagedRelocations[256 + relocation]);
      set(relocationRows, 512 + relocation, stagedRelocations[512 + relocation]);
      set(relocationOwners, relocation, stagedRelocationOwners[relocation]);
      identityByte = 0;
      while (identityByte < 32) limit 32 {
        setByte(
          relocationIdentities,
          relocation * 32 + identityByte,
          stagedRelocationIdentities[relocation * 32 + identityByte]
        );
        identityByte += 1;
      }

      relocation += 1;
    }

    long instructionTarget = 0;
    while (instructionTarget < 131072) limit 131072 {
      set(
        resolvedInstructionTargets,
        instructionTarget,
        stagedInstructionTargets[instructionTarget]
      );
      instructionTarget += 1;
    }

    drop(instructionRows);
    drop(functionRows);
    drop(decoded);
    drop(stagedInstructionTargets);
    drop(stagedRelocationIdentities);
    drop(stagedRelocationOwners);
    drop(stagedRelocations);
    drop(stagedIdentity);
    drop(stagedArtifact);
    drop(publication);
    drop(qualifierDependencyRanks);
    drop(qualifierNameLengths);
    drop(qualifierNameStarts);
    drop(qualifierNames);
    drop(qualifiers);
    drop(targetIdentities);
    drop(targetNames);
    drop(targetParameterRows);
    drop(targetRows);
    drop(targets);
    return result;
  }
}
