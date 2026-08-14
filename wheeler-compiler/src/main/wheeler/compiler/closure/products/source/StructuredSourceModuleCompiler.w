//! Compiles the bounded scalar structured-loop profile from semantic source products.

module wheeler.compiler.closure.structured_source_module_compiler;

import wheeler.compiler.closure.callable_source_composition;
import wheeler.compiler.closure.direct_statement_products;
import wheeler.compiler.closure.loop_body_layouts;
import wheeler.compiler.closure.loop_body_values;
import wheeler.compiler.closure.loop_instruction_products;
import wheeler.compiler.closure.loop_local_type_products;
import wheeler.compiler.closure.resolved_loop_body_products;
import wheeler.compiler.closure.resolved_loop_products;
import wheeler.compiler.closure.source_callable_coordinate_products;
import wheeler.compiler.closure.source_loop_products;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.source_statement_products;
import wheeler.compiler.closure.source_value_products;

classical class StructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_LOOPS = 256;
  private const long MAX_STATEMENTS = 4096;

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

  private long instructionStartForLoop(
    borrow utf8 source,
    long owner,
    long loopOrdinal,
    long statementCount,
    borrow mut words statementRows
  ) {
    long rootBlock = loopBodyRootBlockForOwner(owner, statementCount, statementRows);
    long instructionStart = 0;
    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      if (statementRows[statement] == owner) {
        if (statementRows[4096 + statement] == rootBlock) {
          if (statementRows[LOOP_STATEMENT_ORDINAL_ROW + statement] < loopOrdinal) {
            if (statementRows[LOOP_STATEMENT_CHILD_COUNT_ROW + statement] == 0) {
              long directInstructions = 2;
              long start = statementRows[LOOP_STATEMENT_START_ROW + statement];
              if (utf8Scalar(source, start) == 97) {
                directInstructions = 4;
              }

              instructionStart += directInstructions;
            }
          }
        }
      }

      statement += 1;
    }

    return instructionStart;
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

    region products = new region(/* bytes= */ 2180608, /* allocations= */ 25);
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
    words directTypes = allocate(products, /* length= */ 12288);
    bytes directCode = allocateBytes(products, /* length= */ 262144);
    words composedCallables = allocate(products, /* length= */ 320);
    words composedTypes = allocate(products, /* length= */ 12288);
    bytes composedCode = allocateBytes(products, /* length= */ 262144);

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
    long measuredStatement = 0;
    while (measuredStatement < loopPlan.statementCount) limit MAX_STATEMENTS {
      set(
        statementPhysicalWidths,
        measuredStatement,
        statementLocalRows[MAX_STATEMENTS + measuredStatement]
      );
      measuredStatement += 1;
    }

    ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
      source,
      loopPlan.statementCount,
      statements,
      valuePlan.valueCount,
      values,
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
      set(
        loopInstructionStarts,
        loop,
        instructionStartForLoop(source, owner, ordinal, loopPlan.statementCount, statements)
      );
      loop += 1;
    }

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
      bodyPlan.nestedCount,
      nestedRows,
      loopLocalBases,
      statementPhysicalStarts,
      loopInstructionStarts,
      loopWindowRows,
      loopCode
    );
    assert(codePlan.valid);
    LoopLocalTypePlan typePlan = materializeLoopLocalTypeProducts(
      resolvedPlan.loopCount,
      resolvedLoops,
      loopPlan.statementCount,
      statements,
      bodyPlan.bodyCount,
      bodyRows,
      bodyPlan.nestedCount,
      nestedRows,
      loopLocalBases,
      statementPhysicalStarts,
      loopTypes
    );
    assert(typePlan.valid);

    DirectStatementPlan directPlan = materializeDirectStatementProducts(
      source,
      loopPlan.statementCount,
      statements,
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
    CallableSourceCompositionPlan composition = composeCallableSourceProducts(
      callableCount,
      loopPlan.statementCount,
      statements,
      directPlan.productCount,
      directRows,
      directCode,
      resolvedPlan.loopCount,
      resolvedLoops,
      loopWindowRows,
      loopCode,
      signatureTypeCount,
      signatureTypes,
      directPlan.typeCount,
      directTypes,
      typePlan.typeCount,
      loopTypes,
      functionResultTypes,
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

    drop(composedCode);
    drop(composedTypes);
    drop(composedCallables);
    drop(directCode);
    drop(directTypes);
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
