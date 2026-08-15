//! Compiles the bounded scalar structured-loop profile from semantic source products.

module wheeler.compiler.closure.structured_source_module_compiler;

import wheeler.compiler.closure.callable_instruction_prefixes;
import wheeler.compiler.closure.callable_return_products;
import wheeler.compiler.closure.callable_source_composition;
import wheeler.compiler.closure.direct_statement_products;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.loop_call_products;
import wheeler.compiler.closure.loop_instruction_products;
import wheeler.compiler.closure.loop_local_type_products;
import wheeler.compiler.closure.qualified_source_call_products;
import wheeler.compiler.closure.referenced_source_call_targets;
import wheeler.compiler.closure.resolved_loop_body_products;
import wheeler.compiler.closure.resolved_loop_products;
import wheeler.compiler.closure.source_call_argument_products;
import wheeler.compiler.closure.source_call_instruction_products;
import wheeler.compiler.closure.source_call_layout_products;
import wheeler.compiler.closure.source_call_target_table;
import wheeler.compiler.closure.source_callable_coordinate_products;
import wheeler.compiler.closure.source_callable_result_products;
import wheeler.compiler.closure.source_loop_products;
import wheeler.compiler.closure.source_module_call_products;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.source_statement_products;
import wheeler.compiler.closure.source_value_products;
import wheeler.compiler.closure.structured_artifact_directions;
import wheeler.compiler.closure.structured_source_coordinates;
import wheeler.compiler.closure.structured_source_targets;

classical class StructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_LOOPS = 256;
  private const long MAX_STATEMENTS = 4096;

  /// Publishes one verified artifact against closed imported target products.
  public SourceProductArtifactPlan compileStructuredSourceModuleWithTargets(
    borrow utf8 source,
    long archiveSourceStart,
    long moduleOwner,
    long firstCallable,
    long callableCount,
    borrow mut words callableEffects,
    long importedTargetCount,
    borrow mut words importedTargetRows,
    borrow mut words importedTargetParameterRows,
    borrow byteview importedTargetNames,
    borrow byteview importedTargetIdentities,
    borrow byteview importedTargetQualifierNames,
    borrow mut words importedTargetQualifierNameStarts,
    borrow mut words importedTargetQualifierNameLengths,
    borrow mut words importedTargetQualifierDependencyRanks,
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
    borrow mut words publishedRelocations,
    borrow mut words publishedRelocationOwners,
    borrow mut bytes publishedRelocationIdentities,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    assert(-1 < archiveSourceStart);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(callableEffects) == 4096);
    long reversibleCallableCount = 0;
    long validatedCallable = 0;
    while (validatedCallable < callableCount) limit MAX_CALLABLES {
      long effect = callableEffects[firstCallable + validatedCallable];
      boolean supportedEffect = effect == 0;
      if (effect == 2) {
        supportedEffect = true;
        reversibleCallableCount += 1;
      }

      assert(supportedEffect);
      validatedCallable += 1;
    }

    if (0 < reversibleCallableCount) {
      assert(reversibleCallableCount == callableCount);
    }

    assert(-1 < importedTargetCount);
    assert(importedTargetCount < 4097);
    assert(importedTargetCount < 4096 - callableCount + 1);
    assert(bufferLength(importedTargetRows) == 32768);
    assert(bufferLength(importedTargetParameterRows) == 32768);
    assert(bufferLength(importedTargetNames) == 1048576);
    assert(bufferLength(importedTargetIdentities) == 131072);
    if (0 < importedTargetCount) {
      assert(bufferLength(importedTargetQualifierNames) == 1048576);
      assert(4095 < bufferLength(importedTargetQualifierNameStarts));
      assert(4095 < bufferLength(importedTargetQualifierNameLengths));
      assert(4095 < bufferLength(importedTargetQualifierDependencyRanks));
    }

    assert(bufferLength(bodyStarts) == 4096);
    assert(bufferLength(bodyLengths) == 4096);
    assert(-1 < symbolCount);
    assert(symbolCount < 16385);
    assert(bufferLength(symbolOwners) == 16384);
    assert(bufferLength(symbolStarts) == 16384);
    assert(bufferLength(symbolLengths) == 16384);
    assert(bufferLength(symbolTypes) == 16384);
    assert(bufferLength(symbolValues) == 16384);
    assert(bufferLength(symbolResolved) == 16384);
    assert(-1 < signatureTypeCount);
    assert(signatureTypeCount < 4097);
    assert(bufferLength(signatureTypes) == 12288);
    assert(bufferLength(parameterCounts) == 64);
    assert(bufferLength(stringStarts) == 256);
    assert(bufferLength(stringLengths) == 256);
    assert(bufferLength(functionNameIds) == 64);
    assert(bufferLength(publishedRelocations) == 768);
    assert(bufferLength(publishedRelocationOwners) == 256);
    assert(bufferLength(publishedRelocationIdentities) == 8192);
    assert(bufferLength(output) == 32768);
    assert(bufferLength(identity) == 32);

    region products = new region(/* bytes= */ 5022720, /* allocations= */ 64);
    words blocks = allocate(products, /* length= */ 6144);
    words statements = allocate(products, /* length= */ 28672);
    words sourceConditions = allocate(products, /* length= */ 1536);
    words sourceLoops = allocate(products, /* length= */ 2304);
    words values = allocate(products, /* length= */ 7168);
    words functionLocalCounts = allocate(products, /* length= */ 64);
    words statementLocalRows = allocate(products, /* length= */ 8192);
    words bodyRows = allocate(products, /* length= */ 20480);
    words nestedRows = allocate(products, /* length= */ 20480);
    words statementPhysicalWidths = allocate(products, /* length= */ 4096);
    words statementPhysicalStarts = allocate(products, /* length= */ 4096);
    words resolvedConditions = allocate(products, /* length= */ 1536);
    words resolvedLoops = allocate(products, /* length= */ 2304);
    words loopLocalBases = allocate(products, /* length= */ 256);
    words loopInstructionStarts = allocate(products, /* length= */ 256);
    words loopWindowRows = allocate(products, /* length= */ 768);
    bytes loopCode = allocateBytes(products, /* length= */ 262144);
    words loopTypes = allocate(products, /* length= */ 12288);
    words directRows = allocate(products, /* length= */ 28672);
    words functionResultTypes = allocate(products, /* length= */ 64);
    words localTargetResultTypes = allocate(products, /* length= */ 4096);
    words returnRows = allocate(products, /* length= */ 192);
    words directTypes = allocate(products, /* length= */ 12288);
    bytes directCode = allocateBytes(products, /* length= */ 262144);
    words composedCallables = allocate(products, /* length= */ 320);
    words composedTypes = allocate(products, /* length= */ 12288);
    bytes composedCode = allocateBytes(products, /* length= */ 262144);
    words callableNameStarts = allocate(products, /* length= */ 4096);
    words callableNameLengths = allocate(products, /* length= */ 4096);
    words callableParameterCounts = allocate(products, /* length= */ 4096);
    words discoveredCalls = allocate(products, /* length= */ 1024);
    words calls = allocate(products, /* length= */ 1024);
    words targetDependencyRows = allocate(products, /* length= */ 8192);
    words callStatements = allocate(products, /* length= */ 256);
    words callArgumentStarts = allocate(products, /* length= */ 256);
    words callArgumentCounts = allocate(products, /* length= */ 256);
    words callArguments = allocate(products, /* length= */ 3584);
    words callArgumentValues = allocate(products, /* length= */ 3584);
    words resolvedCalls = allocate(products, /* length= */ 1024);
    words callLocalWidths = allocate(products, /* length= */ 256);
    words callInstructionStarts = allocate(products, /* length= */ 256);
    words callWindowRows = allocate(products, /* length= */ 768);
    words valuePhysicalStarts = allocate(products, /* length= */ 1024);
    bytes localTargetIdentities = allocateBytes(products, /* length= */ 131072);
    words localTargetParameterStarts = allocate(products, /* length= */ 4096);
    words localTargetParameterCounts = allocate(products, /* length= */ 4096);
    words localTargetParameterTypes = allocate(products, /* length= */ 16384);
    bytes targetNames = allocateBytes(products, /* length= */ 1048576);
    words targetNameStarts = allocate(products, /* length= */ 4096);
    words targetNameLengths = allocate(products, /* length= */ 4096);
    words targetParameterStarts = allocate(products, /* length= */ 4096);
    words targetParameterCounts = allocate(products, /* length= */ 4096);
    words targetParameterTypes = allocate(products, /* length= */ 16384);
    words targetResultTypes = allocate(products, /* length= */ 4096);
    bytes targetIdentities = allocateBytes(products, /* length= */ 131072);
    words retainedTargetParameterStarts = allocate(products, /* length= */ 4096);
    words retainedTargetParameterCounts = allocate(products, /* length= */ 4096);
    words retainedTargetParameterTypes = allocate(products, /* length= */ 16384);
    words retainedTargetResultTypes = allocate(products, /* length= */ 4096);
    bytes retainedTargetIdentities = allocateBytes(products, /* length= */ 131072);
    words callRelocations = allocate(products, /* length= */ 768);
    bytes callRelocationIdentities = allocateBytes(products, /* length= */ 8192);
    words callTypes = allocate(products, /* length= */ 12288);
    bytes callCode = allocateBytes(products, /* length= */ 262144);

    long targetParameterCursor = 0;
    long namedCallable = 0;
    while (namedCallable < callableCount) limit MAX_CALLABLES {
      long name = functionNameIds[namedCallable];
      assert(-1 < name);
      assert(name < stringCount);
      long nameStart = stringStarts[name];
      long nameLength = stringLengths[name];
      long simpleStart = nameStart;
      long nameByte = 0;
      while (nameByte + 1 < nameLength) limit 256 {
        if (strings[nameStart + nameByte] == 58) {
          if (strings[nameStart + nameByte + 1] == 58) {
            simpleStart = nameStart + nameByte + 2;
          }
        }

        nameByte += 1;
      }

      assert(simpleStart < nameStart + nameLength);
      set(callableNameStarts, namedCallable, simpleStart);
      set(callableNameLengths, namedCallable, nameStart + nameLength - simpleStart);
      set(callableParameterCounts, namedCallable, parameterCounts[namedCallable]);
      writeTargetIdentity(strings, nameStart, nameLength, namedCallable, localTargetIdentities);
      set(localTargetParameterStarts, namedCallable, targetParameterCursor);
      set(localTargetParameterCounts, namedCallable, parameterCounts[namedCallable]);
      long targetParameter = 0;
      while (targetParameter < parameterCounts[namedCallable]) limit 256 {
        long targetType = signatureTypeAt(
          namedCallable,
          targetParameter,
          signatureTypeCount,
          signatureTypes
        );
        assert(-1 < targetType);
        set(localTargetParameterTypes, targetParameterCursor, targetType);
        targetParameterCursor += 1;
        targetParameter += 1;
      }

      namedCallable += 1;
    }

    SourceCallableResultPlan resultPlan = materializeSourceCallableResultProducts(
      source,
      archiveSourceStart,
      firstCallable,
      callableCount,
      bodyStarts,
      functionResultTypes
    );
    assert(resultPlan.valid);
    long resultTarget = 0;
    while (resultTarget < callableCount) limit MAX_CALLABLES {
      set(localTargetResultTypes, resultTarget, functionResultTypes[resultTarget]);
      resultTarget += 1;
    }

    SourceCallTargetTablePlan targetTablePlan = materializeSourceCallTargetTable(
      callableCount,
      strings,
      callableNameStarts,
      callableNameLengths,
      localTargetParameterStarts,
      localTargetParameterCounts,
      localTargetParameterTypes,
      localTargetResultTypes,
      localTargetIdentities,
      importedTargetCount,
      importedTargetRows,
      importedTargetParameterRows,
      importedTargetNames,
      importedTargetIdentities,
      targetNames,
      targetNameStarts,
      targetNameLengths,
      targetParameterStarts,
      targetParameterCounts,
      targetParameterTypes,
      targetResultTypes,
      targetIdentities,
      targetDependencyRows
    );
    assert(targetTablePlan.valid);
    SourceBlockProductPlan blockPlan = materializeSourceBlockProducts(
      source,
      archiveSourceStart,
      firstCallable,
      callableCount,
      bodyStarts,
      bodyLengths,
      blocks
    );
    assert(blockPlan.valid);
    SourceLoopProductPlan loopPlan = materializeSourceLoopProducts(
      source,
      blockPlan.blockCount,
      blocks,
      statements,
      sourceConditions,
      sourceLoops
    );
    assert(loopPlan.valid);
    assert(0 < loopPlan.loopCount);
    SourceModuleCallPlan callPlan = materializeSourceModuleCallProducts(
      source,
      archiveSourceStart,
      firstCallable,
      callableCount,
      bodyStarts,
      bodyLengths,
      targetNames,
      targetNameStarts,
      targetNameLengths,
      targetParameterCounts,
      importedTargetCount,
      targetDependencyRows,
      loopPlan.statementCount,
      statements,
      discoveredCalls,
      callStatements
    );
    assert(callPlan.valid);
    long resolvedCallCount = callPlan.callCount;
    if (0 < importedTargetCount) {
      SourceModuleCallPlan qualifiedCallPlan = appendQualifiedSourceModuleCallProducts(
        source,
        archiveSourceStart,
        firstCallable,
        callableCount,
        bodyStarts,
        bodyLengths,
        targetNames,
        targetNameStarts,
        targetNameLengths,
        targetParameterCounts,
        callableCount,
        importedTargetCount,
        importedTargetQualifierNames,
        importedTargetQualifierNameStarts,
        importedTargetQualifierNameLengths,
        importedTargetQualifierDependencyRanks,
        targetDependencyRows,
        loopPlan.statementCount,
        statements,
        callPlan.callCount,
        discoveredCalls,
        callStatements
      );
      assert(qualifiedCallPlan.valid);
      resolvedCallCount = qualifiedCallPlan.callCount;
    }

    ReferencedSourceCallTargetPlan referencedTargetPlan = materializeReferencedSourceCallTargets(
      callableCount,
      importedTargetCount,
      resolvedCallCount,
      discoveredCalls,
      targetParameterStarts,
      targetParameterCounts,
      targetParameterTypes,
      targetResultTypes,
      targetIdentities,
      calls,
      retainedTargetParameterStarts,
      retainedTargetParameterCounts,
      retainedTargetParameterTypes,
      retainedTargetResultTypes,
      retainedTargetIdentities
    );
    assert(referencedTargetPlan.valid);
    SourceValueProductPlan valuePlan = materializeSourceValueProducts(
      source,
      archiveSourceStart,
      firstCallable,
      callableCount,
      bodyStarts,
      loopPlan.statementCount,
      statements,
      LOOP_STATEMENT_START_ROW,
      LOOP_STATEMENT_LENGTH_ROW,
      values,
      functionLocalCounts,
      statementLocalRows
    );
    assert(valuePlan.valid);
    SourceCallArgumentPlan callArgumentPlan = materializeSourceCallArgumentProducts(
      source,
      /* callSourceBase= */ 0,
      resolvedCallCount,
      calls,
      callStatements,
      loopPlan.statementCount,
      statements,
      valuePlan.valueCount,
      values,
      callArgumentStarts,
      callArgumentCounts,
      callArguments,
      callArgumentValues
    );
    assert(callArgumentPlan.valid);
    long measuredStatement = 0;
    while (measuredStatement < loopPlan.statementCount) limit MAX_STATEMENTS {
      set(
        statementPhysicalWidths,
        measuredStatement,
        statementLocalRows[MAX_STATEMENTS + measuredStatement]
      );
      measuredStatement += 1;
    }

    boolean qualifiedWidthsValid = materializeQualifiedCallStatementWidths(
      source,
      resolvedCallCount,
      calls,
      callStatements,
      retainedTargetResultTypes,
      statementPhysicalWidths
    );
    assert(qualifiedWidthsValid);
    SourceCallLayoutPlan callLayoutPlan = materializeSourceCallLayoutProducts(
      resolvedCallCount,
      calls,
      callStatements,
      callArgumentStarts,
      callArgumentCounts,
      callArguments,
      referencedTargetPlan.targetCount,
      retainedTargetParameterStarts,
      retainedTargetParameterCounts,
      retainedTargetParameterTypes,
      retainedTargetResultTypes,
      statements,
      statementPhysicalWidths,
      resolvedCalls,
      callLocalWidths
    );
    assert(callLayoutPlan.valid);
    ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
      source,
      loopPlan.statementCount,
      statements,
      valuePlan.valueCount,
      values,
      resolvedCallCount,
      callStatements,
      bodyRows,
      nestedRows,
      statementPhysicalWidths
    );
    assert(bodyPlan.valid);
    boolean frameWidthsValid = materializeLoopFrameWidths(
      loopPlan.loopCount,
      sourceLoops,
      loopPlan.statementCount,
      statements,
      statementPhysicalWidths
    );
    assert(frameWidthsValid);
    SourceCallableCoordinatePlan coordinatePlan = materializeSourceCallableCoordinateProducts(
      callableCount,
      parameterCounts,
      loopPlan.statementCount,
      statements,
      statementLocalRows,
      statementPhysicalWidths,
      statementPhysicalStarts
    );
    assert(coordinatePlan.valid);
    long plannedValue = 0;
    while (plannedValue < valuePlan.valueCount) limit 1024 {
      long valueOwner = values[plannedValue];
      long valueLocal = values[3072 + plannedValue];
      long valueStart = physicalValueLocal(
        valueOwner,
        valueLocal,
        loopPlan.statementCount,
        statements,
        statementLocalRows,
        valuePlan.valueCount,
        values,
        statementPhysicalStarts
      );
      assert(-1 < valueStart);
      long valueOrdinal = values[4096 + plannedValue];
      if (0 < valueOrdinal) {
        long valueStatement = statementAtOrdinal(
          valueOwner,
          valueOrdinal,
          loopPlan.statementCount,
          statements
        );
        assert(-1 < valueStatement);
        long valueCall = callAtStatement(valueStatement, resolvedCallCount, callStatements);
        if (-1 < valueCall) {
          assert(resolvedCalls[256 + valueCall] != 0);
          valueStart = statementPhysicalStarts[valueStatement] + callLocalWidths[valueCall] - 1;
        }
      }

      set(valuePhysicalStarts, plannedValue, valueStart);
      plannedValue += 1;
    }

    ResolvedLoopProductPlan resolvedPlan = materializeResolvedLoopProducts(
      source,
      archiveSourceStart,
      moduleOwner,
      loopPlan.loopCount,
      sourceConditions,
      sourceLoops,
      valuePlan.valueCount,
      values,
      symbolCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved,
      resolvedConditions,
      resolvedLoops
    );
    assert(resolvedPlan.valid);
    long conditionLoop = 0;
    while (conditionLoop < resolvedPlan.loopCount) limit MAX_LOOPS {
      long conditionOwner = resolvedLoops[conditionLoop];
      long condition = resolvedLoops[768 + conditionLoop];
      if (resolvedConditions[256 + condition] == 1) {
        long leftLocal = physicalValueLocal(
          conditionOwner,
          resolvedConditions[512 + condition],
          loopPlan.statementCount,
          statements,
          statementLocalRows,
          valuePlan.valueCount,
          values,
          statementPhysicalStarts
        );
        assert(-1 < leftLocal);
        set(resolvedConditions, 512 + condition, leftLocal);
      }

      if (resolvedConditions[768 + condition] == 1) {
        long rightLocal = physicalValueLocal(
          conditionOwner,
          resolvedConditions[1024 + condition],
          loopPlan.statementCount,
          statements,
          statementLocalRows,
          valuePlan.valueCount,
          values,
          statementPhysicalStarts
        );
        assert(-1 < rightLocal);
        set(resolvedConditions, 1024 + condition, rightLocal);
      }

      conditionLoop += 1;
    }

    long loop = 0;
    while (loop < resolvedPlan.loopCount) limit MAX_LOOPS {
      long owner = resolvedLoops[loop];
      long ordinal = resolvedLoops[512 + loop];
      long loopDepth = resolvedLoops[2048 + loop];
      assert(0 < loopDepth);
      assert(loopDepth < 5);
      long loopStatement = statementAtLoop(owner, ordinal, loopPlan.statementCount, statements);
      assert(-1 < loopStatement);
      set(loopLocalBases, loop, statementPhysicalStarts[loopStatement]);
      loop += 1;
    }

    DirectStatementPlan directPlan = materializeDirectStatementProducts(
      source,
      loopPlan.statementCount,
      statements,
      resolvedCallCount,
      callStatements,
      valuePlan.valueCount,
      values,
      statementLocalRows,
      statementPhysicalStarts,
      statementPhysicalWidths,
      directRows,
      functionResultTypes,
      directTypes,
      directCode
    );
    assert(directPlan.valid);
    CallableInstructionPrefixPlan instructionPrefixPlan = materializeCallableInstructionPrefixes(
      resolvedPlan.loopCount,
      resolvedLoops,
      loopPlan.statementCount,
      statements,
      directPlan.productCount,
      directRows,
      resolvedCallCount,
      resolvedCalls,
      callStatements,
      callArgumentCounts,
      loopInstructionStarts
    );
    assert(instructionPrefixPlan.valid);
    SourceCallInstructionPlan preliminaryCallInstructionPlan
      = materializeSourceCallInstructionProducts(
      resolvedCallCount,
      resolvedCalls,
      callStatements,
      callArgumentCounts,
      loopPlan.statementCount,
      statements,
      directPlan.productCount,
      directRows,
      resolvedPlan.loopCount,
      resolvedLoops,
      loopWindowRows,
      callInstructionStarts,
      callWindowRows
    );
    assert(preliminaryCallInstructionPlan.valid);
    LoopCallPlan preliminaryEmittedCallPlan = writeLoopCallProducts(
      resolvedCallCount,
      resolvedCalls,
      callArgumentStarts,
      callArgumentCounts,
      callStatements,
      callInstructionStarts,
      callArguments,
      callArgumentValues,
      valuePhysicalStarts,
      referencedTargetPlan.targetCount,
      retainedTargetIdentities,
      retainedTargetParameterStarts,
      retainedTargetParameterCounts,
      retainedTargetParameterTypes,
      callRelocations,
      callRelocationIdentities,
      callTypes,
      callLocalWidths,
      statementPhysicalStarts,
      statementPhysicalWidths,
      callCode
    );
    assert(preliminaryEmittedCallPlan.valid);
    LoopInstructionProductPlan codePlan = writeLoopInstructionProducts(
      true,
      resolvedPlan.loopCount,
      resolvedConditions,
      resolvedLoops,
      loopPlan.statementCount,
      statements,
      blockPlan.blockCount,
      blocks,
      bodyPlan.bodyCount,
      bodyRows,
      resolvedCallCount,
      callStatements,
      callWindowRows,
      callInstructionStarts,
      callCode,
      bodyPlan.nestedCount,
      nestedRows,
      loopLocalBases,
      statementPhysicalStarts,
      loopInstructionStarts,
      loopWindowRows,
      loopCode
    );
    assert(codePlan.valid);
    SourceCallInstructionPlan callInstructionPlan = materializeSourceCallInstructionProducts(
      resolvedCallCount,
      resolvedCalls,
      callStatements,
      callArgumentCounts,
      loopPlan.statementCount,
      statements,
      directPlan.productCount,
      directRows,
      resolvedPlan.loopCount,
      resolvedLoops,
      loopWindowRows,
      callInstructionStarts,
      callWindowRows
    );
    assert(callInstructionPlan.valid);
    LoopCallPlan emittedCallPlan = writeLoopCallProducts(
      resolvedCallCount,
      resolvedCalls,
      callArgumentStarts,
      callArgumentCounts,
      callStatements,
      callInstructionStarts,
      callArguments,
      callArgumentValues,
      valuePhysicalStarts,
      referencedTargetPlan.targetCount,
      retainedTargetIdentities,
      retainedTargetParameterStarts,
      retainedTargetParameterCounts,
      retainedTargetParameterTypes,
      callRelocations,
      callRelocationIdentities,
      callTypes,
      callLocalWidths,
      statementPhysicalStarts,
      statementPhysicalWidths,
      callCode
    );
    assert(emittedCallPlan.valid);
    LoopLocalTypePlan typePlan = materializeLoopLocalTypeProducts(
      resolvedPlan.loopCount,
      resolvedLoops,
      loopPlan.statementCount,
      statements,
      bodyPlan.bodyCount,
      bodyRows,
      resolvedCallCount,
      callStatements,
      bodyPlan.nestedCount,
      nestedRows,
      loopLocalBases,
      statementPhysicalStarts,
      loopTypes
    );
    assert(typePlan.valid);
    CallableReturnPlan returnPlan = materializeCallableReturnProducts(
      callableCount,
      functionResultTypes,
      loopPlan.statementCount,
      statements,
      directPlan.productCount,
      directRows,
      resolvedCallCount,
      resolvedCalls,
      callStatements,
      callArgumentCounts,
      resolvedPlan.loopCount,
      resolvedLoops,
      loopWindowRows,
      returnRows
    );
    assert(returnPlan.valid);
    CallableSourceCompositionPlan composition = composeCallableSourceProducts(
      callableCount,
      loopPlan.statementCount,
      statements,
      directPlan.productCount,
      directRows,
      directCode,
      resolvedCallCount,
      callStatements,
      callWindowRows,
      callCode,
      resolvedPlan.loopCount,
      resolvedLoops,
      loopWindowRows,
      loopCode,
      signatureTypeCount,
      signatureTypes,
      directPlan.typeCount,
      directTypes,
      emittedCallPlan.localTypeCount,
      callTypes,
      typePlan.typeCount,
      loopTypes,
      functionResultTypes,
      returnRows,
      composedCallables,
      composedTypes,
      composedCode
    );
    assert(composition.valid);
    SourceProductArtifactPlan result = publishStructuredArtifactDirections(
      callableCount,
      reversibleCallableCount,
      referencedTargetPlan.importedCount,
      retainedTargetParameterStarts,
      retainedTargetParameterCounts,
      retainedTargetParameterTypes,
      retainedTargetResultTypes,
      composedCallables,
      parameterCounts,
      functionResultTypes,
      functionNameIds,
      composition.typeCount,
      composedTypes,
      composedCode,
      composition.length,
      strings,
      stringBytes,
      stringCount,
      stringStarts,
      stringLengths,
      output,
      identity
    );

    long publishedRelocation = 0;
    while (publishedRelocation < resolvedCallCount) limit 256 {
      set(publishedRelocations, publishedRelocation, callRelocations[publishedRelocation]);
      set(
        publishedRelocationOwners,
        publishedRelocation,
        statements[callStatements[publishedRelocation]]
      );
      set(
        publishedRelocations,
        256 + publishedRelocation,
        callRelocations[256 + publishedRelocation]
      );
      set(
        publishedRelocations,
        512 + publishedRelocation,
        callRelocations[512 + publishedRelocation]
      );
      long publishedIdentityByte = 0;
      while (publishedIdentityByte < 32) limit 32 {
        setByte(
          publishedRelocationIdentities,
          publishedRelocation * 32 + publishedIdentityByte,
          callRelocationIdentities[publishedRelocation * 32 + publishedIdentityByte]
        );
        publishedIdentityByte += 1;
      }

      publishedRelocation += 1;
    }

    SourceProductArtifactPlan publishedResult = new SourceProductArtifactPlan(
      result.length,
      result.codeStart,
      result.functionCount,
      result.maxLocalCount,
      resolvedCallCount
    );

    drop(callCode);
    drop(callTypes);
    drop(callRelocationIdentities);
    drop(callRelocations);
    drop(retainedTargetIdentities);
    drop(retainedTargetResultTypes);
    drop(retainedTargetParameterTypes);
    drop(retainedTargetParameterCounts);
    drop(retainedTargetParameterStarts);
    drop(targetIdentities);
    drop(targetResultTypes);
    drop(targetParameterTypes);
    drop(targetParameterCounts);
    drop(targetParameterStarts);
    drop(targetNameLengths);
    drop(targetNameStarts);
    drop(targetNames);
    drop(localTargetParameterTypes);
    drop(localTargetParameterCounts);
    drop(localTargetParameterStarts);
    drop(localTargetIdentities);
    drop(valuePhysicalStarts);
    drop(callWindowRows);
    drop(callInstructionStarts);
    drop(callLocalWidths);
    drop(resolvedCalls);
    drop(callArgumentValues);
    drop(callArguments);
    drop(callArgumentCounts);
    drop(callArgumentStarts);
    drop(callStatements);
    drop(targetDependencyRows);
    drop(calls);
    drop(discoveredCalls);
    drop(callableParameterCounts);
    drop(callableNameLengths);
    drop(callableNameStarts);
    drop(composedCode);
    drop(composedTypes);
    drop(composedCallables);
    drop(directCode);
    drop(directTypes);
    drop(returnRows);
    drop(localTargetResultTypes);
    drop(functionResultTypes);
    drop(directRows);
    drop(loopTypes);
    drop(loopCode);
    drop(loopWindowRows);
    drop(loopInstructionStarts);
    drop(loopLocalBases);
    drop(resolvedLoops);
    drop(resolvedConditions);
    drop(statementPhysicalStarts);
    drop(statementPhysicalWidths);
    drop(nestedRows);
    drop(bodyRows);
    drop(statementLocalRows);
    drop(functionLocalCounts);
    drop(values);
    drop(sourceLoops);
    drop(sourceConditions);
    drop(statements);
    drop(blocks);
    drop(products);
    return publishedResult;
  }
}
