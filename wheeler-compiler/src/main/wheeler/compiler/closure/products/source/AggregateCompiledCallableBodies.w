//! Compiles aggregate-aware source products into immutable primitive and supplemental code.

module wheeler.compiler.closure.aggregate_compiled_callable_bodies;

import wheeler.compiler.closure.aggregate_expression_projection;
import wheeler.compiler.closure.aggregate_instruction_composition;
import wheeler.compiler.closure.aggregate_instruction_products;
import wheeler.compiler.closure.aggregate_placeholder_placements;
import wheeler.compiler.closure.aggregate_primitive_compiler;
import wheeler.compiler.closure.aggregate_source_bindings;
import wheeler.compiler.closure.aggregate_source_projection;
import wheeler.compiler.closure.compiled_function_products;
import wheeler.compiler.closure.imported_callable_stubs;
import wheeler.compiler.closure.imported_nominal_carrier_projections;
import wheeler.compiler.closure.imported_nominal_references;
import wheeler.compiler.closure.local_nominal_carriers;
import wheeler.compiler.closure.primitive_placeholder_projection;
import wheeler.compiler.closure.source_product_artifact;

classical class AggregateCompiledCallableBodies {
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CALLABLE_ARTIFACT_BYTES = 32768;
  private const long MAX_CALLABLE_SOURCE_BYTES = 32768;
  private const long WORD_BYTES = 8;
  private const long MAX_SOURCE_ROWS = 4096;
  private const long FUNCTION_COLUMNS = 10;
  private const long MAX_LOCAL_REFERENCES = 512;
  private const long CARRIER_COLUMNS = 4;
  private const long CARRIER_ROWS = MAX_LOCAL_REFERENCES * CARRIER_COLUMNS;
  private const long SOURCE_PRODUCT_ROWS = 4096 * 6 + 1024 * 7 + 1024 + 64 + 4096 * 2;
  private const long LOCAL_PROJECTION_ROWS = MAX_LOCAL_REFERENCES * 8;
  // Destinations, owners, arguments, placements, and their function/direction joins.
  private const long BINDING_ROWS = 256 * 2 + 1024 + 256 * 3 + 256 * 2;
  // Constructors, aggregate/case owners, projections, slice descriptors, and resolved operands.
  private const long OPERATION_ROWS = 256 * 3 + 256 * 2 + 256 * 4 + 256 + 256 * 6;
  // Primitive, placeholder-projected, and composed functions/instructions, then selectors.
  private const long COMPOSITION_ROWS = 3 * (64 * 10 + 4096 * 6) + 256 * 3 + 4096;
  private const long IMPORT_PROJECTION_ROWS = 16384 * 3 + 16384 * 4;
  private const long STAGING_WORDS = SOURCE_PRODUCT_ROWS + LOCAL_PROJECTION_ROWS + CARRIER_ROWS
    + BINDING_ROWS + OPERATION_ROWS + COMPOSITION_ROWS + IMPORT_PROJECTION_ROWS;
  private const long SUPPLEMENTAL_BYTES = 12288;
  // The original and six projected sources coexist during the admitted binding phases.
  private const long PEAK_SOURCE_BUFFERS = 7;
  private const long STAGING_BYTES = STAGING_WORDS * WORD_BYTES + PEAK_SOURCE_BUFFERS
    * MAX_CALLABLE_SOURCE_BYTES + MAX_CALLABLE_ARTIFACT_BYTES + SUPPLEMENTAL_BYTES + IDENTITY_BYTES;
  // Source products, local projections/carriers, bindings, operations, composition, imports.
  private const long WORD_BUFFERS = 5 + 2 + 6 + 6 + 8 + 2;
  private const long CODE_BUFFERS = 3;
  private const long SOURCE_BUFFER_IDENTITIES = PEAK_SOURCE_BUFFERS;
  private const long STAGING_BUFFER_IDENTITIES = WORD_BUFFERS + CODE_BUFFERS
    + SOURCE_BUFFER_IDENTITIES;

  // Call only after validating every backing and producer extent and constructing the report.
  // These copies allocate no storage and introduce no late semantic validation.
  private void copyPublishedWords(
    long rowCount,
    long columnCount,
    borrow mut words source,
    borrow mut words output
  ) {
    long stride = bufferLength(source) / columnCount;
    long column = 0;
    while (column < columnCount) limit FUNCTION_COLUMNS {
      long row = 0;
      while (row < rowCount) limit MAX_SOURCE_ROWS {
        long cell = column * stride + row;
        set(output, cell, source[cell]);
        row += 1;
      }

      column += 1;
    }
  }

  private void copyPublishedBytes(long length, borrow byteview source, borrow mut bytes output) {
    long byte = 0;
    while (byte < length) limit MAX_CALLABLE_ARTIFACT_BYTES {
      setByte(output, byte, source[byte]);
      byte += 1;
    }
  }

  private void requirePublicationBackings(
    borrow mut words localNominalProjectionRows,
    borrow mut words localCarrierRows,
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
    borrow mut words localComposedFunctionRows,
    borrow mut words localComposedInstructionRows,
    borrow mut words localArtifactSelectors,
    borrow mut words nominalProjectionRows,
    borrow mut words carrierProjectionRows,
    borrow mut bytes supplementalCode,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    assert(bufferLength(localNominalProjectionRows) == LOCAL_PROJECTION_ROWS);
    assert(bufferLength(localCarrierRows) == CARRIER_ROWS);
    assert(bufferLength(localStatementRows) == MAX_SOURCE_ROWS * 6);
    assert(bufferLength(localValueRows) == 1024 * 7);
    assert(bufferLength(localFunctionLocalCounts) == 64);
    assert(bufferLength(localDestinationRows) == 256);
    assert(bufferLength(localOwnerRows) == 256);
    assert(bufferLength(localArgumentRows) == 1024);
    assert(bufferLength(localPlacementRows) == 256 * 3);
    assert(bufferLength(localConstructorTargetRows) == 256 * 3);
    assert(bufferLength(localProjectionTargetRows) == 256 * 4);
    assert(bufferLength(localResolvedOperationRows) == 256 * 6);
    assert(bufferLength(localComposedFunctionRows) == 64 * FUNCTION_COLUMNS);
    assert(bufferLength(localComposedInstructionRows) == MAX_SOURCE_ROWS * 6);
    assert(bufferLength(localArtifactSelectors) == MAX_SOURCE_ROWS);
    assert(bufferLength(nominalProjectionRows) == 16384 * 3);
    assert(bufferLength(carrierProjectionRows) == 16384 * 4);
    assert(bufferLength(supplementalCode) == SUPPLEMENTAL_BYTES);
    assert(bufferLength(artifact) == MAX_CALLABLE_ARTIFACT_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);
  }

  /// Reports one primitive product and its source-local aggregate code product.
  public record AggregateCompiledCallableBody(
    long length,
    long functionCount,
    long maxLocalCount,
    long supplementalInstructionCount,
    long supplementalLength,
    long composedInstructionCount
  ) {}

  /// Names the original archive window and its closed compilation intent.
  /// Class coordinates stay archive-relative, not relative to a rewritten body.
  public record AggregateSourceRequest(
    long targetKind,
    long sourceStart,
    long sourceLength,
    long classNameStart,
    long classNameLength,
    long constantCount,
    long moduleOwner
  ) {}

  /// Compiles one aggregate-aware local class against counted import products.
  public AggregateCompiledCallableBody compileAggregateSourceModuleProductWithImports(
    borrow byteview sourceArchive,
    AggregateSourceRequest request,
    borrow mut words constants,
    borrow byteview constantNames,
    borrow mut words constantNameStarts,
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
    long sourceStart = request.sourceStart;
    long sourceLength = request.sourceLength;
    long classNameStart = request.classNameStart;
    long classNameLength = request.classNameLength;
    long moduleOwner = request.moduleOwner;
    requirePublicationBackings(
      localNominalProjectionRows,
      localCarrierRows,
      localStatementRows,
      localValueRows,
      localFunctionLocalCounts,
      localDestinationRows,
      localOwnerRows,
      localArgumentRows,
      localPlacementRows,
      localConstructorTargetRows,
      localProjectionTargetRows,
      localResolvedOperationRows,
      localComposedFunctionRows,
      localComposedInstructionRows,
      localArtifactSelectors,
      nominalProjectionRows,
      carrierProjectionRows,
      supplementalCode,
      artifact,
      identity
    );
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceLength < MAX_CALLABLE_SOURCE_BYTES + 1);
    assert(sourceStart < bufferLength(sourceArchive) + 1);
    assert(sourceLength < bufferLength(sourceArchive) - sourceStart + 1);
    assert(classNameStart < sourceStart + sourceLength);
    assert(sourceStart < classNameStart + 1);
    assert(0 < classNameLength);
    assert(classNameLength < sourceStart + sourceLength - classNameStart + 1);
    region sourceArena = new region(STAGING_BYTES, STAGING_BUFFER_IDENTITIES);
    bytes originalSource = allocateBytes(sourceArena, sourceLength);
    words stagedStatements = allocate(sourceArena, /* length= */ 24576);
    words stagedValues = allocate(sourceArena, /* length= */ 7168);
    words stagedValueStructures = allocate(sourceArena, /* length= */ 1024);
    words stagedLocalCounts = allocate(sourceArena, /* length= */ 64);
    words stagedStatementLocals = allocate(sourceArena, /* length= */ 8192);
    words stagedLocalProjections = allocate(sourceArena, LOCAL_PROJECTION_ROWS);
    words stagedLocalCarriers = allocate(sourceArena, CARRIER_ROWS);
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
    long sliceDescriptor = 0;
    while (sliceDescriptor < operationCount) limit 256 {
      set(stagedSliceDescriptors, sliceDescriptor, -1);
      sliceDescriptor += 1;
    }

    long originalByte = 0;
    while (originalByte < sourceLength) limit MAX_CALLABLE_SOURCE_BYTES {
      setByte(originalSource, originalByte, sourceArchive[sourceStart + originalByte]);
      originalByte += 1;
    }

    utf8 originalUtf8 = freezeUtf8(originalSource);
    AggregateSourceValuePlan sourceValues = bindAggregateSourceValues(
      originalUtf8,
      sourceArchive,
      sourceStart,
      firstLocalCallable,
      localCallableCount,
      localCallableBodyStarts,
      localCallableBodyLengths,
      operationCount,
      operationRows,
      argumentCount,
      argumentRows,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      localNominalReferenceCount,
      localNominalReferenceRows,
      stagedStatements,
      stagedValues,
      stagedLocalCounts,
      stagedStatementLocals,
      stagedLocalProjections,
      stagedDestinations,
      stagedOwners,
      stagedArguments,
      stagedPlacements,
      stagedConstructorTargets
    );
    AggregateInstructionProductPlan supplementalProduct = resolveAggregateSourceOperations(
      originalUtf8,
      operationCount,
      operationRows,
      argumentCount,
      argumentRows,
      aggregateCount,
      aggregateRows,
      localCaseCount,
      localCaseRows,
      localMemberCount,
      localMemberRows,
      sourceValues.valueCount,
      sourceValues.projectionCount,
      stagedValues,
      stagedValueStructures,
      stagedLocalProjections,
      stagedDestinations,
      stagedOwners,
      stagedArguments,
      stagedPlacements,
      stagedConstructorTargets,
      stagedOwnerAggregates,
      stagedOwnerCases,
      stagedProjectionTargets,
      stagedSliceDescriptors,
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
      stagedLocalCarriers,
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
    drop(nominalSource);
    drop(stubSource);
    drop(localCarrierSource);
    drop(expressionSource);
    drop(projectedSource);
    SourceProductArtifactPlan result = compileAggregatePrimitiveSource(
      request.targetKind,
      carrierSource,
      /* sourceStart= */ 0,
      carriers.length,
      classNameStart - sourceStart,
      classNameLength,
      request.constantCount,
      constants,
      constantNames,
      constantNameStarts,
      stagedArtifact,
      stagedIdentity
    );
    drop(carrierSource);
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
    AggregateCompiledCallableBody published = new AggregateCompiledCallableBody(
      result.length,
      result.functionCount,
      result.maxLocalCount,
      supplementalProduct.instructionCount,
      supplementalProduct.length,
      composition.instructionCount
    );
    copyPublishedWords(
      localNominalReferenceCount,
      CARRIER_COLUMNS,
      stagedLocalCarriers,
      localCarrierRows
    );
    copyPublishedBytes(result.length, stagedArtifact, artifact);
    copyPublishedBytes(IDENTITY_BYTES, stagedIdentity, identity);
    copyPublishedWords(nominals.projectionCount, 3, stagedProjections, nominalProjectionRows);
    copyPublishedWords(operationCount, 3, stagedConstructorTargets, localConstructorTargetRows);
    copyPublishedWords(
      primitiveFunctions.functionCount,
      FUNCTION_COLUMNS,
      stagedComposedFunctions,
      localComposedFunctionRows
    );
    copyPublishedWords(
      composition.instructionCount,
      6,
      stagedComposedInstructions,
      localComposedInstructionRows
    );
    copyPublishedWords(
      composition.instructionCount,
      1,
      stagedArtifactSelectors,
      localArtifactSelectors
    );
    copyPublishedBytes(supplementalProduct.length, stagedSupplementalCode, supplementalCode);
    copyPublishedWords(operationCount, 6, stagedResolvedOperations, localResolvedOperationRows);
    copyPublishedWords(operationCount, 4, stagedProjectionTargets, localProjectionTargetRows);
    copyPublishedWords(operationCount, 1, stagedDestinations, localDestinationRows);
    copyPublishedWords(operationCount, 1, stagedOwners, localOwnerRows);
    copyPublishedWords(argumentCount, 1, stagedArguments, localArgumentRows);
    copyPublishedWords(operationCount, 3, stagedPlacements, localPlacementRows);
    copyPublishedWords(
      sourceValues.projectionCount,
      8,
      stagedLocalProjections,
      localNominalProjectionRows
    );
    copyPublishedWords(sourceValues.valueCount, 7, stagedValues, localValueRows);
    copyPublishedWords(localCallableCount, 1, stagedLocalCounts, localFunctionLocalCounts);
    copyPublishedWords(sourceValues.statementCount, 6, stagedStatements, localStatementRows);
    copyPublishedWords(
      carrierProjectionPlan.projectionCount,
      4,
      stagedCarrierProjections,
      carrierProjectionRows
    );

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
    drop(stagedLocalCarriers);
    drop(stagedLocalProjections);
    drop(stagedStatementLocals);
    drop(stagedLocalCounts);
    drop(stagedValueStructures);
    drop(stagedValues);
    drop(stagedStatements);
    drop(sourceArena);
    return published;
  }

}
