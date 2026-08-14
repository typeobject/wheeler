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
import wheeler.compiler.closure.source_loop_products;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.source_statement_products;
import wheeler.compiler.closure.source_value_products;

classical class StructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_LOOPS = 256;
  private const long MAX_STATEMENTS = 4096;

  private long instructionStartForLoop(
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
              instructionStart += 2;
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

    region products = new region(/* bytes= */ 2049536, /* allocations= */ 22);
    words blocks = allocate(products, /* length= */ 6144);
    words statements = allocate(products, /* length= */ 28672);
    words sourceConditions = allocate(products, /* length= */ 1536);
    words sourceLoops = allocate(products, /* length= */ 2304);
    words values = allocate(products, /* length= */ 7168);
    words functionLocalCounts = allocate(products, /* length= */ 64);
    words bodyRows = allocate(products, /* length= */ 20480);
    words nestedRows = allocate(products, /* length= */ 20480);
    words resolvedConditions = allocate(products, /* length= */ 1536);
    words resolvedLoops = allocate(products, /* length= */ 2304);
    words loopLocalBases = allocate(products, /* length= */ 256);
    words loopInstructionStarts = allocate(products, /* length= */ 256);
    words loopWindowRows = allocate(products, /* length= */ 768);
    bytes loopCode = allocateBytes(products, /* length= */ 262144);
    words loopTypes = allocate(products, /* length= */ 12288);
    words callableReturnLocals = allocate(products, /* length= */ 64);
    words directRows = allocate(products, /* length= */ 28672);
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
      functionLocalCounts
    );
    assert(valuePlan.valid);
    ResolvedLoopBodyPlan bodyPlan = materializeResolvedLoopBodyProducts(
      source,
      loopPlan.statementCount,
      statements,
      valuePlan.valueCount,
      values,
      bodyRows,
      nestedRows
    );
    assert(bodyPlan.valid);
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

    long loop = 0;
    while (loop < resolvedPlan.loopCount) limit MAX_LOOPS {
      long owner = resolvedLoops[loop];
      long ordinal = resolvedLoops[512 + loop];
      set(
        loopLocalBases,
        loop,
        localBaseAtOrdinal(owner, ordinal, valuePlan.valueCount, values)
      );
      set(
        loopInstructionStarts,
        loop,
        instructionStartForLoop(owner, ordinal, loopPlan.statementCount, statements)
      );
      loop += 1;
    }

    LoopInstructionProductPlan codePlan = writeLoopInstructionProducts(
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
      loopTypes
    );
    assert(typePlan.valid);

    long type = 0;
    while (type < typePlan.typeCount) limit 4096 {
      long typeOwner = loopTypes[type];
      long nextLocal = loopTypes[4096 + type] + 1;
      if (callableReturnLocals[typeOwner] < nextLocal) {
        set(callableReturnLocals, typeOwner, nextLocal);
      }

      type += 1;
    }

    DirectStatementPlan directPlan = materializeDirectStatementProducts(
      source,
      loopPlan.statementCount,
      statements,
      valuePlan.valueCount,
      values,
      callableReturnLocals,
      directRows,
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
      composedCallables,
      composedTypes,
      composedCode
    );
    assert(composition.valid);
    SourceProductArtifactPlan result = publishClassicalSourceModuleArtifact(
      callableCount,
      composedCallables,
      parameterCounts,
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
    drop(directRows);
    drop(callableReturnLocals);
    drop(loopTypes);
    drop(loopCode);
    drop(loopWindowRows);
    drop(loopInstructionStarts);
    drop(loopLocalBases);
    drop(resolvedLoops);
    drop(resolvedConditions);
    drop(nestedRows);
    drop(bodyRows);
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
