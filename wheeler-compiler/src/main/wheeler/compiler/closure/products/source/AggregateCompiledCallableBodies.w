//! Compiles aggregate-aware source products into immutable primitive and supplemental code.

module wheeler.compiler.closure.aggregate_compiled_callable_bodies;

import wheeler.compiler.closure.aggregate_constructor_targets;
import wheeler.compiler.closure.aggregate_expression_projection;
import wheeler.compiler.closure.aggregate_expression_temporaries;
import wheeler.compiler.closure.aggregate_frontend_bindings;
import wheeler.compiler.closure.aggregate_indexed_owners;
import wheeler.compiler.closure.aggregate_instruction_composition;
import wheeler.compiler.closure.aggregate_instruction_products;
import wheeler.compiler.closure.aggregate_placeholder_placements;
import wheeler.compiler.closure.aggregate_projection_targets;
import wheeler.compiler.closure.aggregate_resolved_operands;
import wheeler.compiler.closure.aggregate_source_owners;
import wheeler.compiler.closure.aggregate_source_projection;
import wheeler.compiler.closure.compiled_callable_bodies;
import wheeler.compiler.closure.compiled_function_products;
import wheeler.compiler.closure.imported_callable_stubs;
import wheeler.compiler.closure.imported_nominal_carrier_projections;
import wheeler.compiler.closure.imported_nominal_references;
import wheeler.compiler.closure.local_nominal_carrier_projections;
import wheeler.compiler.closure.local_nominal_carriers;
import wheeler.compiler.closure.primitive_placeholder_projection;
import wheeler.compiler.closure.resolved_aggregate_operations;
import wheeler.compiler.closure.source_statement_products;

classical class AggregateCompiledCallableBodies {
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CALLABLE_ARTIFACT_BYTES = 32768;
  private const long MAX_CALLABLE_SOURCE_BYTES = 32768;

  /// Reports one primitive product and its source-local aggregate code product.
  public record AggregateCompiledCallableBody(
    long length,
    long functionCount,
    long maxLocalCount,
    long supplementalInstructionCount,
    long supplementalLength,
    long composedInstructionCount
  ) {}

  /// Compiles one aggregate-aware local class against counted import products.
  public AggregateCompiledCallableBody compileAggregateSourceModuleProductWithImports(
    borrow byteview sourceArchive,
    long sourceStart,
    long sourceLength,
    long aggregateCount,
    borrow mut words aggregateRows,
    long localCaseCount,
    borrow mut words localCaseRows,
    long localMemberCount,
    borrow mut words localMemberRows,
    long operationCount,
    borrow mut words operationRows,
    long argumentCount,
    borrow mut words argumentRows,
    long localNominalReferenceCount,
    borrow mut words localNominalReferenceRows,
    borrow mut words localNominalProjectionRows,
    borrow mut words localCarrierRows,
    long firstLocalCallable,
    long localCallableCount,
    borrow mut words localCallableBodyStarts,
    borrow mut words localCallableBodyLengths,
    borrow mut words localStatementRows,
    borrow mut words localValueRows,
    borrow mut words localFunctionLocalCounts,
    borrow mut words localDestinationRows,
    borrow mut words localOwnerRows,
    borrow mut words localArgumentRows,
    borrow mut words localPlacementRows,
    borrow mut words localConstructorTargetRows,
    borrow mut words localProjectionTargetRows,
    borrow mut words localResolvedOperationRows,
    borrow mut bytes supplementalCode,
    borrow mut words localComposedFunctionRows,
    borrow mut words localComposedInstructionRows,
    borrow mut words localArtifactSelectors,
    long moduleOwner,
    long firstRecordTypeId,
    long firstVariantTypeId,
    long nominalReferenceCount,
    borrow mut words nominalReferenceRows,
    borrow mut words carrierFunctionRows,
    borrow mut words carrierLocalRows,
    borrow mut words importedAggregateRows,
    borrow mut words nominalProjectionRows,
    borrow mut words carrierProjectionRows,
    long callCount,
    borrow mut words callRows,
    borrow mut words callableEffects,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    assert(bufferLength(artifact) == MAX_CALLABLE_ARTIFACT_BYTES);
    assert(bufferLength(supplementalCode) == 12288);
    assert(bufferLength(identity) == IDENTITY_BYTES);
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceLength < MAX_CALLABLE_SOURCE_BYTES + 1);
    region sourceArena = new region(/* bytes= */ 2209952, /* allocations= */ 38);
    bytes originalSource = allocateBytes(sourceArena, sourceLength);
    words stagedStatements = allocate(sourceArena, /* length= */ 24576);
    words stagedValues = allocate(sourceArena, /* length= */ 7168);
    words stagedValueStructures = allocate(sourceArena, /* length= */ 1024);
    words stagedLocalCounts = allocate(sourceArena, /* length= */ 64);
    words stagedLocalProjections = allocate(sourceArena, /* length= */ 4096);
    words stagedDestinations = allocate(sourceArena, /* length= */ 256);
    words stagedOwners = allocate(sourceArena, /* length= */ 256);
    words stagedArguments = allocate(sourceArena, /* length= */ 1024);
    words stagedPlacements = allocate(sourceArena, /* length= */ 768);
    words stagedOperationFunctions = allocate(sourceArena, /* length= */ 256);
    words stagedOperationDirections = allocate(sourceArena, /* length= */ 256);
    words stagedConstructorTargets = allocate(sourceArena, /* length= */ 768);
    words stagedOwnerAggregates = allocate(sourceArena, /* length= */ 256);
    words stagedOwnerCases = allocate(sourceArena, /* length= */ 256);
    words stagedProjectionTargets = allocate(sourceArena, /* length= */ 1024);
    words stagedSliceDescriptors = allocate(sourceArena, /* length= */ 256);
    words stagedResolvedOperations = allocate(sourceArena, /* length= */ 1536);
    bytes stagedSupplementalCode = allocateBytes(sourceArena, /* length= */ 12288);
    bytes stagedArtifact = allocateBytes(sourceArena, MAX_CALLABLE_ARTIFACT_BYTES);
    bytes stagedIdentity = allocateBytes(sourceArena, IDENTITY_BYTES);
    words primitiveFunctionRows = allocate(sourceArena, /* length= */ 640);
    words primitiveInstructionRows = allocate(sourceArena, /* length= */ 24576);
    words projectedFunctionRows = allocate(sourceArena, /* length= */ 640);
    words projectedInstructionRows = allocate(sourceArena, /* length= */ 24576);
    words projectedPlacementRows = allocate(sourceArena, /* length= */ 768);
    words stagedComposedFunctions = allocate(sourceArena, /* length= */ 640);
    words stagedComposedInstructions = allocate(sourceArena, /* length= */ 24576);
    words stagedArtifactSelectors = allocate(sourceArena, /* length= */ 4096);
    bytes projectedSource = allocateBytes(sourceArena, MAX_CALLABLE_SOURCE_BYTES);
    bytes expressionSource = allocateBytes(sourceArena, MAX_CALLABLE_SOURCE_BYTES);
    bytes localCarrierSource = allocateBytes(sourceArena, MAX_CALLABLE_SOURCE_BYTES);
    bytes stubSource = allocateBytes(sourceArena, MAX_CALLABLE_SOURCE_BYTES);
    bytes nominalSource = allocateBytes(sourceArena, MAX_CALLABLE_SOURCE_BYTES);
    bytes carrierSource = allocateBytes(sourceArena, MAX_CALLABLE_SOURCE_BYTES);
    words stagedProjections = allocate(sourceArena, /* length= */ 49152);
    words stagedCarrierProjections = allocate(sourceArena, /* length= */ 65536);
    assert(bufferLength(localNominalProjectionRows) == 4096);
    assert(bufferLength(nominalProjectionRows) == 49152);
    assert(bufferLength(carrierProjectionRows) == 65536);
    assert(bufferLength(localStatementRows) == 24576);
    assert(bufferLength(localValueRows) == 7168);
    assert(bufferLength(localFunctionLocalCounts) == 64);
    assert(bufferLength(localDestinationRows) == 256);
    assert(bufferLength(localOwnerRows) == 256);
    assert(bufferLength(localArgumentRows) == 1024);
    assert(bufferLength(localPlacementRows) == 768);
    assert(bufferLength(localConstructorTargetRows) == 768);
    assert(bufferLength(localProjectionTargetRows) == 1024);
    assert(bufferLength(localResolvedOperationRows) == 1536);
    assert(bufferLength(localComposedFunctionRows) == 640);
    assert(bufferLength(localComposedInstructionRows) == 24576);
    assert(bufferLength(localArtifactSelectors) == 4096);
    long sliceDescriptor = 0;
    while (sliceDescriptor < 256) limit 256 {
      set(stagedSliceDescriptors, sliceDescriptor, -1);
      sliceDescriptor += 1;
    }

    long originalByte = 0;
    while (originalByte < sourceLength) limit MAX_CALLABLE_SOURCE_BYTES {
      setByte(originalSource, originalByte, sourceArchive[sourceStart + originalByte]);
      originalByte += 1;
    }

    utf8 originalUtf8 = freezeUtf8(originalSource);
    SourceStatementProductPlan sourceStatements = materializeSourceStatementProducts(
      originalUtf8,
      sourceStart,
      firstLocalCallable,
      localCallableCount,
      localCallableBodyStarts,
      localCallableBodyLengths,
      stagedStatements
    );
    assert(sourceStatements.valid);
    SourceValueProductPlan sourceValues = materializeSourceValueProducts(
      originalUtf8,
      sourceStart,
      firstLocalCallable,
      localCallableCount,
      localCallableBodyStarts,
      sourceStatements.statementCount,
      stagedStatements,
      stagedValues,
      stagedLocalCounts
    );
    assert(sourceValues.valid);
    AggregateExpressionTemporaryPlan expressionValues = appendAggregateExpressionTemporaries(
      operationCount,
      operationRows,
      sourceStatements.statementCount,
      stagedStatements,
      sourceValues.valueCount,
      stagedValues,
      stagedLocalCounts
    );
    assert(expressionValues.valid);
    AggregateFrontendBindingPlan frontendBindings = projectAggregateFrontendBindings(
      originalUtf8,
      operationCount,
      operationRows,
      argumentCount,
      argumentRows,
      expressionValues.valueCount,
      stagedValues,
      sourceStatements.statementCount,
      stagedStatements,
      stagedDestinations,
      stagedOwners,
      stagedArguments,
      stagedPlacements
    );
    assert(frontendBindings.valid);
    boolean constructorTargetsValid = resolveLocalAggregateConstructorTargets(
      originalUtf8,
      operationCount,
      operationRows,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      stagedConstructorTargets
    );
    assert(constructorTargetsValid);
    LocalNominalCarrierProjectionPlan localProjectionPlan = publishLocalNominalCarrierProjections(
      originalUtf8,
      localNominalReferenceCount,
      localNominalReferenceRows,
      expressionValues.valueCount,
      stagedValues,
      operationCount,
      operationRows,
      stagedLocalProjections
    );
    assert(localProjectionPlan.valid);
    AggregateSourceOwnerPlan sourceOwners = deriveAggregateSourceOwners(
      operationCount,
      operationRows,
      stagedDestinations,
      stagedOwners,
      stagedPlacements,
      localProjectionPlan.projectionCount,
      stagedLocalProjections,
      stagedConstructorTargets,
      stagedOwnerAggregates,
      stagedOwnerCases
    );
    assert(sourceOwners.valid);
    AggregateIndexedOwnerPlan indexedOwners = deriveAggregateIndexedOwners(
      originalUtf8,
      operationCount,
      operationRows,
      stagedDestinations,
      stagedOwners,
      stagedPlacements,
      expressionValues.valueCount,
      stagedValues,
      stagedValueStructures,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      localMemberCount,
      localMemberRows,
      stagedOwnerAggregates,
      stagedOwnerCases
    );
    assert(indexedOwners.valid);
    boolean projectionTargetsValid = resolveLocalAggregateProjectionTargets(
      originalUtf8,
      operationCount,
      operationRows,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      localMemberCount,
      localMemberRows,
      stagedOwnerAggregates,
      stagedOwnerCases,
      stagedProjectionTargets
    );
    assert(projectionTargetsValid);
    boolean resolvedOperandsValid = assembleAggregateResolvedOperands(
      operationCount,
      operationRows,
      argumentCount,
      argumentRows,
      stagedArguments,
      stagedConstructorTargets,
      stagedProjectionTargets,
      stagedDestinations,
      stagedOwners,
      stagedSliceDescriptors,
      stagedResolvedOperations
    );
    assert(resolvedOperandsValid);
    AggregateInstructionProductPlan supplementalProduct = writeResolvedSourceAggregateInstructions(
      operationCount,
      operationRows,
      stagedResolvedOperations,
      stagedSupplementalCode
    );
    drop(originalUtf8);
    ImportedNominalCarrierProjectionPlan carrierProjectionPlan
      = publishImportedNominalCarrierProjections(
      moduleOwner,
      nominalReferenceCount,
      nominalReferenceRows,
      carrierFunctionRows,
      carrierLocalRows,
      importedAggregateRows,
      stagedCarrierProjections
    );
    assert(carrierProjectionPlan.projectionCount == nominalReferenceCount);
    long projectedLength = writeSourceWithoutAggregateDeclarations(
      sourceArchive,
      sourceStart,
      sourceLength,
      aggregateCount,
      aggregateRows,
      projectedSource
    );
    long expressionLength = writeSourceWithoutAggregateExpressions(
      projectedSource,
      /* sourceStart= */ 0,
      projectedLength,
      operationCount,
      operationRows,
      expressionSource
    );
    LocalNominalCarrierPlan localCarriers = writeLocalNominalCarriers(
      expressionSource,
      expressionLength,
      localNominalReferenceCount,
      localNominalReferenceRows,
      stagedLocalProjections,
      localCarrierRows,
      localCarrierSource
    );
    assert(localCarriers.valid);
    ImportedCallableStubPlan callables = writeImportedCallableStubs(
      localCarrierSource,
      /* sourceStart= */ 0,
      localCarriers.length,
      callCount,
      callRows,
      callableEffects,
      callableFirstParameters,
      callableParameterCounts,
      callableResultTypes,
      parameterTypes,
      parameterModes,
      stubSource
    );
    ImportedNominalReferencePlan nominals = writeImportedNominalReferences(
      sourceArchive,
      sourceStart,
      sourceLength,
      stubSource,
      /* callableSourceStart= */ 0,
      callables.length,
      moduleOwner,
      firstRecordTypeId,
      firstVariantTypeId,
      nominalReferenceCount,
      nominalReferenceRows,
      callCount,
      callRows,
      importedAggregateRows,
      stagedProjections,
      nominalSource
    );
    ImportedNominalCarrierPlan carriers = writeImportedNominalCarriers(
      sourceArchive,
      sourceStart,
      sourceLength,
      stubSource,
      /* callableSourceStart= */ 0,
      callables.length,
      nominalReferenceCount,
      nominalReferenceRows,
      callCount,
      callRows,
      importedAggregateRows,
      carrierSource
    );
    assert(carriers.referenceCount == nominalReferenceCount);
    assert(nominals.projectionCount < nominalReferenceCount + 1);
    bytes exactSource = allocateBytes(sourceArena, carriers.length);
    long sourceByte = 0;
    while (sourceByte < carriers.length) limit MAX_CALLABLE_SOURCE_BYTES {
      setByte(exactSource, sourceByte, carrierSource[sourceByte]);
      sourceByte += 1;
    }

    drop(carrierSource);
    drop(nominalSource);
    drop(stubSource);
    drop(localCarrierSource);
    drop(expressionSource);
    drop(projectedSource);
    CompiledCallableBody result = compileExactProductSource(
      exactSource,
      stagedArtifact,
      stagedIdentity
    );
    CompiledFunctionPlan primitiveFunctions = indexCompiledFunctionProducts(
      stagedArtifact,
      result.length,
      primitiveFunctionRows,
      primitiveInstructionRows
    );
    long placementOperation = 0;
    while (placementOperation < operationCount) limit 256 {
      set(stagedOperationFunctions, placementOperation, stagedPlacements[placementOperation]);
      set(
        stagedOperationDirections,
        placementOperation,
        stagedPlacements[256 + placementOperation]
      );
      placementOperation += 1;
    }

    AggregatePlaceholderPlacementPlan exactPlacements = deriveAggregatePlaceholderPlacements(
      stagedArtifact,
      result.length,
      primitiveFunctions.functionCount,
      primitiveFunctions.instructionCount,
      primitiveInstructionRows,
      operationCount,
      operationRows,
      stagedDestinations,
      stagedOperationFunctions,
      stagedOperationDirections,
      stagedPlacements
    );
    assert(exactPlacements.valid);
    PrimitivePlaceholderProjectionPlan placeholderProjection
      = projectPrimitiveAggregatePlaceholders(
      stagedArtifact,
      result.length,
      primitiveFunctions.functionCount,
      primitiveFunctionRows,
      primitiveFunctions.instructionCount,
      primitiveInstructionRows,
      operationCount,
      operationRows,
      stagedDestinations,
      stagedPlacements,
      projectedFunctionRows,
      projectedInstructionRows,
      projectedPlacementRows
    );
    assert(placeholderProjection.valid);
    AggregateCompositionPlan composition = composeAggregateInstructionProducts(
      primitiveFunctions.functionCount,
      projectedFunctionRows,
      placeholderProjection.instructionCount,
      projectedInstructionRows,
      operationCount,
      stagedSupplementalCode,
      supplementalProduct.length,
      projectedPlacementRows,
      stagedComposedFunctions,
      stagedComposedInstructions,
      stagedArtifactSelectors
    );
    assert(composition.valid);
    long artifactByte = 0;
    while (artifactByte < result.length) limit MAX_CALLABLE_ARTIFACT_BYTES {
      setByte(artifact, artifactByte, stagedArtifact[artifactByte]);
      artifactByte += 1;
    }

    long identityByte = 0;
    while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(identity, identityByte, stagedIdentity[identityByte]);
      identityByte += 1;
    }

    long projectionRow = 0;
    while (projectionRow < 49152) limit 49152 {
      set(nominalProjectionRows, projectionRow, stagedProjections[projectionRow]);
      projectionRow += 1;
    }

    long constructorTargetRow = 0;
    while (constructorTargetRow < 768) limit 768 {
      set(
        localConstructorTargetRows,
        constructorTargetRow,
        stagedConstructorTargets[constructorTargetRow]
      );
      constructorTargetRow += 1;
    }

    long composedFunctionRow = 0;
    while (composedFunctionRow < 640) limit 640 {
      set(
        localComposedFunctionRows,
        composedFunctionRow,
        stagedComposedFunctions[composedFunctionRow]
      );
      composedFunctionRow += 1;
    }

    long composedInstructionRow = 0;
    while (composedInstructionRow < 24576) limit 24576 {
      set(
        localComposedInstructionRows,
        composedInstructionRow,
        stagedComposedInstructions[composedInstructionRow]
      );
      composedInstructionRow += 1;
    }

    long artifactSelector = 0;
    while (artifactSelector < 4096) limit 4096 {
      set(localArtifactSelectors, artifactSelector, stagedArtifactSelectors[artifactSelector]);
      artifactSelector += 1;
    }

    long supplementalByte = 0;
    while (supplementalByte < supplementalProduct.length) limit 12288 {
      setByte(supplementalCode, supplementalByte, stagedSupplementalCode[supplementalByte]);
      supplementalByte += 1;
    }

    long resolvedOperationRow = 0;
    while (resolvedOperationRow < 1536) limit 1536 {
      set(
        localResolvedOperationRows,
        resolvedOperationRow,
        stagedResolvedOperations[resolvedOperationRow]
      );
      resolvedOperationRow += 1;
    }

    long projectionTargetRow = 0;
    while (projectionTargetRow < 1024) limit 1024 {
      set(
        localProjectionTargetRows,
        projectionTargetRow,
        stagedProjectionTargets[projectionTargetRow]
      );
      projectionTargetRow += 1;
    }

    long bindingRow = 0;
    while (bindingRow < 256) limit 256 {
      set(localDestinationRows, bindingRow, stagedDestinations[bindingRow]);
      set(localOwnerRows, bindingRow, stagedOwners[bindingRow]);
      bindingRow += 1;
    }

    bindingRow = 0;
    while (bindingRow < 1024) limit 1024 {
      set(localArgumentRows, bindingRow, stagedArguments[bindingRow]);
      bindingRow += 1;
    }

    bindingRow = 0;
    while (bindingRow < 768) limit 768 {
      set(localPlacementRows, bindingRow, stagedPlacements[bindingRow]);
      bindingRow += 1;
    }

    long localProjectionRow = 0;
    while (localProjectionRow < 4096) limit 4096 {
      set(
        localNominalProjectionRows,
        localProjectionRow,
        stagedLocalProjections[localProjectionRow]
      );
      localProjectionRow += 1;
    }

    long valueRow = 0;
    while (valueRow < 7168) limit 7168 {
      set(localValueRows, valueRow, stagedValues[valueRow]);
      valueRow += 1;
    }

    long localCountRow = 0;
    while (localCountRow < 64) limit 64 {
      set(localFunctionLocalCounts, localCountRow, stagedLocalCounts[localCountRow]);
      localCountRow += 1;
    }

    long statementRow = 0;
    while (statementRow < 24576) limit 24576 {
      set(localStatementRows, statementRow, stagedStatements[statementRow]);
      statementRow += 1;
    }

    long carrierProjectionRow = 0;
    while (carrierProjectionRow < 65536) limit 65536 {
      set(
        carrierProjectionRows,
        carrierProjectionRow,
        stagedCarrierProjections[carrierProjectionRow]
      );
      carrierProjectionRow += 1;
    }

    drop(stagedCarrierProjections);
    drop(stagedProjections);
    drop(stagedArtifactSelectors);
    drop(stagedComposedInstructions);
    drop(stagedComposedFunctions);
    drop(projectedPlacementRows);
    drop(projectedInstructionRows);
    drop(projectedFunctionRows);
    drop(primitiveInstructionRows);
    drop(primitiveFunctionRows);
    drop(stagedIdentity);
    drop(stagedArtifact);
    drop(stagedSupplementalCode);
    drop(stagedResolvedOperations);
    drop(stagedSliceDescriptors);
    drop(stagedProjectionTargets);
    drop(stagedOwnerCases);
    drop(stagedOwnerAggregates);
    drop(stagedConstructorTargets);
    drop(stagedOperationDirections);
    drop(stagedOperationFunctions);
    drop(stagedPlacements);
    drop(stagedArguments);
    drop(stagedOwners);
    drop(stagedDestinations);
    drop(stagedLocalProjections);
    drop(stagedLocalCounts);
    drop(stagedValueStructures);
    drop(stagedValues);
    drop(stagedStatements);
    drop(sourceArena);
    return new AggregateCompiledCallableBody(
      result.length,
      result.functionCount,
      result.maxLocalCount,
      supplementalProduct.instructionCount,
      supplementalProduct.length,
      composition.instructionCount
    );
  }

}
