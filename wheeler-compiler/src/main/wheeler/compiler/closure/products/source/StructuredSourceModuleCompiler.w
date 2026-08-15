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
import wheeler.compiler.closure.resolved_loop_body_products;
import wheeler.compiler.closure.resolved_loop_products;
import wheeler.compiler.closure.source_call_argument_products;
import wheeler.compiler.closure.source_call_instruction_products;
import wheeler.compiler.closure.source_call_layout_products;
import wheeler.compiler.closure.source_callable_coordinate_products;
import wheeler.compiler.closure.source_callable_result_products;
import wheeler.compiler.closure.source_loop_products;
import wheeler.compiler.closure.source_module_call_products;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.source_statement_products;
import wheeler.compiler.closure.source_value_products;
import wheeler.crypto.sha256;

classical class StructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_LOOPS = 256;
  private const long MAX_STATEMENTS = 4096;

  private long signatureTypeAt(
    long owner,
    long local,
    long signatureTypeCount,
    borrow mut words signatureTypes
  ) {
    long selected = -1;
    long matches = 0;
    long type = 0;
    while (type < signatureTypeCount) limit 4096 {
      if (signatureTypes[type] == owner) {
        if (signatureTypes[4096 + type] == local) {
          selected = signatureTypes[8192 + type];
          matches += 1;
        }
      }

      type += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private void writeTargetIdentity(
    borrow byteview names,
    long start,
    long length,
    long target,
    borrow mut bytes identities
  ) {
    region hashArena = new region(/* bytes= */ 1232, /* allocations= */ 4);
    bytes digest = allocateBytes(hashArena, /* length= */ 32);
    hashSha256Range(names, start, length, digest, hashArena);
    long identityByte = 0;
    while (identityByte < 32) limit 32 {
      setByte(identities, target * 32 + identityByte, digest[identityByte]);
      identityByte += 1;
    }

    drop(digest);
    drop(hashArena);
  }

  private long callAtStatement(long statement, long callCount, borrow mut words callStatements) {
    long selected = -1;
    long matches = 0;
    long call = 0;
    while (call < callCount) limit 256 {
      if (callStatements[call] == statement) {
        selected = call;
        matches += 1;
      }

      call += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long statementAtLoop(
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] == ordinal) {
          if (0 < statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement]) {
            selected = statement;
            matches += 1;
          }
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long statementAtOrdinal(
    long owner,
    long ordinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long selected = -1;
    long matches = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] == ordinal) {
          selected = statement;
          matches += 1;
        }
      }

      statement += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  private long physicalValueLocal(
    long owner,
    long local,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words statementLocalRows,
    long valueCount,
    borrow mut words valueRows,
    borrow mut words statementPhysicalStarts
  ) {
    long selected = -1;
    long matches = 0;
    long value = 0;
    while (value < valueCount) limit 1024 {
      if (valueRows[value] == owner) {
        if (valueRows[3072 + value] == local) {
          selected = value;
          matches += 1;
        }
      }

      value += 1;
    }

    if (matches != 1) {
      return -1;
    }

    long ordinal = valueRows[4096 + selected];
    if (ordinal == 0) {
      return local;
    }

    long statement = statementAtOrdinal(owner, ordinal, statementCount, statementRows);
    if (statement < 0) {
      return -1;
    }

    long logicalBase = statementLocalRows[statement];
    if (local < logicalBase) {
      return -1;
    }

    return statementPhysicalStarts[statement] + local - logicalBase;
  }

  /// Publishes one verified source-local artifact without scalar-helper reparsing.
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
    assert(-1 < archiveSourceStart);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
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
    assert(bufferLength(output) == 32768);
    assert(bufferLength(identity) == 32);

    region products = new region(/* bytes= */ 3146752, /* allocations= */ 49);
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
    words returnRows = allocate(products, /* length= */ 192);
    words directTypes = allocate(products, /* length= */ 12288);
    bytes directCode = allocateBytes(products, /* length= */ 262144);
    words composedCallables = allocate(products, /* length= */ 320);
    words composedTypes = allocate(products, /* length= */ 12288);
    bytes composedCode = allocateBytes(products, /* length= */ 262144);
    words callableNameStarts = allocate(products, /* length= */ 4096);
    words callableNameLengths = allocate(products, /* length= */ 4096);
    words callableParameterCounts = allocate(products, /* length= */ 4096);
    words calls = allocate(products, /* length= */ 1024);
    words emptyDependencyRows = allocate(products, /* length= */ 8192);
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
    bytes targetIdentities = allocateBytes(products, /* length= */ 131072);
    words targetParameterStarts = allocate(products, /* length= */ 4096);
    words targetParameterCounts = allocate(products, /* length= */ 4096);
    words targetParameterTypes = allocate(products, /* length= */ 16384);
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
      writeTargetIdentity(strings, nameStart, nameLength, namedCallable, targetIdentities);
      set(targetParameterStarts, namedCallable, targetParameterCursor);
      set(targetParameterCounts, namedCallable, parameterCounts[namedCallable]);
      long targetParameter = 0;
      while (targetParameter < parameterCounts[namedCallable]) limit 256 {
        long targetType = signatureTypeAt(
          namedCallable,
          targetParameter,
          signatureTypeCount,
          signatureTypes
        );
        assert(-1 < targetType);
        set(targetParameterTypes, targetParameterCursor, targetType);
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
      strings,
      callableNameStarts,
      callableNameLengths,
      callableParameterCounts,
      /* dependencyCount= */ 0,
      emptyDependencyRows,
      loopPlan.statementCount,
      statements,
      calls,
      callStatements
    );
    assert(callPlan.valid);
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
      callPlan.callCount,
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

    SourceCallLayoutPlan callLayoutPlan = materializeSourceCallLayoutProducts(
      callPlan.callCount,
      calls,
      callStatements,
      callArgumentStarts,
      callArgumentCounts,
      callArguments,
      callableCount,
      parameterCounts,
      signatureTypeCount,
      signatureTypes,
      functionResultTypes,
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
      callPlan.callCount,
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
        long valueCall = callAtStatement(valueStatement, callPlan.callCount, callStatements);
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
      callPlan.callCount,
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
      callPlan.callCount,
      resolvedCalls,
      callStatements,
      callArgumentCounts,
      loopInstructionStarts
    );
    assert(instructionPrefixPlan.valid);
    SourceCallInstructionPlan preliminaryCallInstructionPlan
      = materializeSourceCallInstructionProducts(
      callPlan.callCount,
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
      callPlan.callCount,
      resolvedCalls,
      callArgumentStarts,
      callArgumentCounts,
      callStatements,
      callInstructionStarts,
      callArguments,
      callArgumentValues,
      valuePhysicalStarts,
      callableCount,
      targetIdentities,
      targetParameterStarts,
      targetParameterCounts,
      targetParameterTypes,
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
      callPlan.callCount,
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
      callPlan.callCount,
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
      callPlan.callCount,
      resolvedCalls,
      callArgumentStarts,
      callArgumentCounts,
      callStatements,
      callInstructionStarts,
      callArguments,
      callArgumentValues,
      valuePhysicalStarts,
      callableCount,
      targetIdentities,
      targetParameterStarts,
      targetParameterCounts,
      targetParameterTypes,
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
      callPlan.callCount,
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
      callPlan.callCount,
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
      callPlan.callCount,
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
    SourceProductArtifactPlan result = publishClassicalSourceModuleArtifact(
      callableCount,
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

    drop(callCode);
    drop(callTypes);
    drop(callRelocationIdentities);
    drop(callRelocations);
    drop(targetParameterTypes);
    drop(targetParameterCounts);
    drop(targetParameterStarts);
    drop(targetIdentities);
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
    drop(emptyDependencyRows);
    drop(calls);
    drop(callableParameterCounts);
    drop(callableNameLengths);
    drop(callableNameStarts);
    drop(composedCode);
    drop(composedTypes);
    drop(composedCallables);
    drop(directCode);
    drop(directTypes);
    drop(returnRows);
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
    return result;
  }
}
