//! Prepares archive-owned metadata for direct structured source-module compilation.

//! Scalar names and qualifiers share one detached view, before body-column reduction.

module wheeler.compiler.closure.archive_structured_source_module_compiler;

import wheeler.compiler.closure.imported_source_call_targets;
import wheeler.compiler.closure.scoped_constant_products;
import wheeler.compiler.closure.source_call_target_table;
import wheeler.compiler.closure.source_classical_proofs;
import wheeler.compiler.closure.source_module_name_products;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_module_strings;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.structured_source_module_compiler;
import wheeler.compiler.constant_product_schema;
import wheeler.core.encoding.binary;

classical class ArchiveStructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_PARAMETERS = 16384;
  private const long MAX_SIGNATURE_TYPES = 4096;
  private const long MAX_CLOSURE_CALLABLES = 4096;
  private const long ARTIFACT_BYTES = 32768;
  private const long WORD_BYTES = 8;
  private const long SYMBOL_COLUMNS = 6;
  private const long SIGNATURE_COLUMNS = 3;
  private const long LOCAL_COLUMNS = 3;
  private const long BODY_COLUMNS = 3;
  private const long STRING_COLUMNS = 2;
  private const long SIGNATURE_ROWS = MAX_SIGNATURE_TYPES * SIGNATURE_COLUMNS;
  private const long METADATA_WORDS = MAX_CONSTANT_PRODUCTS * SYMBOL_COLUMNS + SIGNATURE_ROWS
    + MAX_CALLABLES * LOCAL_COLUMNS + MAX_CLOSURE_CALLABLES * BODY_COLUMNS
    + MAX_SOURCE_MODULE_STRINGS * STRING_COLUMNS + SOURCE_MODULE_NAME_ROWS;
  private const long METADATA_BYTES = METADATA_WORDS * WORD_BYTES + ARTIFACT_BYTES;
  private const long METADATA_BUFFERS = SYMBOL_COLUMNS + 1 + LOCAL_COLUMNS + BODY_COLUMNS
    + STRING_COLUMNS + 2;
  private const long CALLABLE_COLUMNS = 5;
  private const long CALLABLE_ROWS = MAX_CALLABLES * CALLABLE_COLUMNS;
  private const long EMPTY_CODE_BYTES = 1;
  private const long EMPTY_WORDS = CALLABLE_ROWS + MAX_CALLABLES * LOCAL_COLUMNS + SIGNATURE_ROWS
    + MAX_SOURCE_MODULE_STRINGS * STRING_COLUMNS + MAX_CLOSURE_CALLABLES * BODY_COLUMNS
    + SOURCE_MODULE_NAME_ROWS;
  private const long EMPTY_BYTES = EMPTY_WORDS * WORD_BYTES + ARTIFACT_BYTES * 2 + EMPTY_CODE_BYTES;
  private const long EMPTY_BUFFERS = 1 + LOCAL_COLUMNS + 1 + STRING_COLUMNS + BODY_COLUMNS + 4;

  private void requireArchiveSourceNames(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    borrow byteview moduleNames,
    long moduleNameStart,
    long moduleNameLength,
    long classNameStart,
    long classNameLength
  ) {
    assert(-1 < sourceStart);
    assert(sourceStart < bufferLength(archive) + 1);
    assert(0 < sourceLength);
    assert(sourceLength < 32769);
    assert(sourceLength < bufferLength(archive) - sourceStart + 1);
    assert(-1 < moduleNameStart);
    assert(moduleNameStart < bufferLength(moduleNames) + 1);
    assert(0 < moduleNameLength);
    assert(moduleNameLength < 257);
    assert(moduleNameLength < bufferLength(moduleNames) - moduleNameStart + 1);
    assert(classNameStart < sourceStart + sourceLength);
    assert(sourceStart < classNameStart + 1);
    assert(0 < classNameLength);
    assert(classNameLength < 257);
    assert(classNameLength < sourceStart + sourceLength - classNameStart + 1);
  }

  private void requireArchiveConstantPacket(
    long count,
    borrow mut words rows,
    borrow byteview names,
    borrow mut words nameStarts
  ) {
    assert(-1 < count);
    assert(count < MAX_CONSTANT_PRODUCTS + 1);
    assert(bufferLength(rows) == CONSTANT_PRODUCT_ROWS);
    assert(rows[0] == count);
    assert(
      measureScopedConstantProducts(names, names, count, rows, CONSTANT_PRODUCT_NAME_BYTES)
        < CONSTANT_PRODUCT_NAME_BYTES + 1
    );
    assert(MAX_CONSTANT_PRODUCTS < bufferLength(nameStarts) + 1);
    long row = 0;
    while (row < count) limit MAX_CONSTANT_PRODUCTS {
      long first = CONSTANT_PRODUCT_HEADER_ROWS + row * CONSTANT_PRODUCT_COLUMNS;
      assert(nameStarts[row] == rows[first + CONSTANT_NAME_START]);
      row += 1;
    }
  }

  private long localParameterType(long type, long mode) {
    if (mode == 0) {
      return type;
    }

    if (type == 3) {
      return 12;
    }

    if (type == 4) {
      return 10;
    }

    if (type == 5) {
      return 11;
    }

    if (type == 6) {
      return 9;
    }

    if (type == 7) {
      return 8;
    }

    if (type == 13) {
      return 13;
    }

    assert(false);
    return 0;
  }

  private long copyRange(
    borrow byteview source,
    long start,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < start);
    assert(-1 < length);
    assert(-1 < outputStart);
    assert(length < bufferLength(output) - outputStart + 1);
    long offset = 0;
    while (offset < length) limit 32768 {
      setByte(output, outputStart + offset, source[start + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  /// Publishes one local-call archive module from closed name, value, and callable products.
  public SourceProductArtifactPlan compileStructuredArchiveModule(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long moduleOwner,
    borrow byteview moduleNames,
    long moduleNameStart,
    long moduleNameLength,
    long classNameStart,
    long classNameLength,
    long firstCallable,
    long callableCount,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    long importedCount,
    borrow mut words importedRows,
    borrow byteview importedNames,
    borrow mut words importedNameStarts,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words callableEffects,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    requireArchiveSourceNames(
      archive,
      sourceStart,
      sourceLength,
      moduleNames,
      moduleNameStart,
      moduleNameLength,
      classNameStart,
      classNameLength
    );
    if (callableCount == 0) {
      return compileCallableFreeArchiveModule(
        archive,
        sourceStart,
        sourceLength,
        classNameStart,
        classNameLength,
        importedCount,
        importedRows,
        importedNames,
        importedNameStarts,
        artifact,
        identity
      );
    }

    region emptyTargets = new region(/* bytes= */ 64, /* allocations= */ 7);
    words importedTargetRows = allocate(emptyTargets, /* length= */ 1);
    words importedTargetParameterRows = allocate(emptyTargets, /* length= */ 1);
    bytes importedTargetNames = allocateBytes(emptyTargets, /* length= */ 1);
    bytes importedTargetIdentities = allocateBytes(emptyTargets, /* length= */ 1);
    region emptyRelocations = new region(/* bytes= */ 16384, /* allocations= */ 3);
    words relocationRows = allocate(emptyRelocations, /* length= */ 768);
    words relocationOwners = allocate(emptyRelocations, /* length= */ 256);
    bytes relocationIdentities = allocateBytes(emptyRelocations, /* length= */ 8192);
    words qualifierNameStarts = allocate(emptyTargets, /* length= */ 1);
    words qualifierNameLengths = allocate(emptyTargets, /* length= */ 1);
    words qualifierRanks = allocate(emptyTargets, /* length= */ 1);
    SourceProductArtifactPlan result = compileStructuredArchiveModuleWithTargetView(
      archive,
      sourceStart,
      sourceLength,
      moduleOwner,
      moduleNames,
      moduleNameStart,
      moduleNameLength,
      classNameStart,
      classNameLength,
      firstCallable,
      callableCount,
      /* importedTargetCount= */ 0,
      importedTargetRows,
      importedTargetParameterRows,
      importedTargetNames,
      importedTargetIdentities,
      importedTargetNames,
      qualifierNameStarts,
      qualifierNameLengths,
      qualifierRanks,
      callableBodyStarts,
      callableBodyLengths,
      importedCount,
      importedRows,
      importedNames,
      importedNameStarts,
      callableFirstParameters,
      callableParameterCounts,
      callableResultTypes,
      callableEffects,
      parameterTypes,
      parameterModes,
      callableNames,
      callableNameStarts,
      callableNameLengths,
      relocationRows,
      relocationOwners,
      relocationIdentities,
      artifact,
      identity
    );
    drop(relocationIdentities);
    drop(relocationOwners);
    drop(relocationRows);
    drop(emptyRelocations);
    drop(qualifierRanks);
    drop(qualifierNameLengths);
    drop(qualifierNameStarts);
    drop(importedTargetIdentities);
    drop(importedTargetNames);
    drop(importedTargetParameterRows);
    drop(importedTargetRows);
    drop(emptyTargets);
    return result;
  }

  private SourceProductArtifactPlan compileCallableFreeArchiveModule(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long classNameStart,
    long classNameLength,
    long constantCount,
    borrow mut words constants,
    borrow byteview constantNames,
    borrow mut words constantNameStarts,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    requireArchiveConstantPacket(constantCount, constants, constantNames, constantNameStarts);
    region empty = new region(/* bytes= */ EMPTY_BYTES, /* allocations= */ EMPTY_BUFFERS);
    words callables = allocate(empty, CALLABLE_ROWS);
    words parameterCounts = allocate(empty, MAX_CALLABLES);
    words resultTypes = allocate(empty, MAX_CALLABLES);
    words functionNameIds = allocate(empty, MAX_CALLABLES);
    words localTypes = allocate(empty, SIGNATURE_ROWS);
    bytes code = allocateBytes(empty, EMPTY_CODE_BYTES);
    bytes strings = allocateBytes(empty, ARTIFACT_BYTES);
    words stringStarts = allocate(empty, MAX_SOURCE_MODULE_STRINGS);
    words stringLengths = allocate(empty, MAX_SOURCE_MODULE_STRINGS);
    words kinds = allocate(empty, MAX_CLOSURE_CALLABLES);
    words starts = allocate(empty, MAX_CLOSURE_CALLABLES);
    words lengths = allocate(empty, MAX_CLOSURE_CALLABLES);
    bytes sourceBytes = allocateBytes(empty, sourceLength);
    assert(copyRange(archive, sourceStart, sourceLength, sourceBytes, 0) == sourceLength);
    utf8 source = freezeUtf8(sourceBytes);
    words nameProducts = allocate(empty, SOURCE_MODULE_NAME_ROWS);
    SourceModuleNamePlan names = materializeSourceModuleNames(
      source,
      archive,
      classNameStart,
      classNameLength,
      archive,
      /* moduleNameStart= */ 0,
      /* moduleNameLength= */ 0,
      /* firstCallable= */ 0,
      /* callableCount= */ 0,
      archive,
      callables,
      resultTypes,
      constantNames,
      constants,
      kinds,
      starts,
      lengths,
      strings,
      stringStarts,
      stringLengths,
      functionNameIds,
      nameProducts
    );
    assert(sourceClassicalClaimsAbsent(source, kinds, starts, lengths, functionNameIds));
    SourceProductArtifactPlan result = publishClassicalSourceModuleArtifact(
      names.classNameId,
      names.globalCount,
      SOURCE_MODULE_GLOBAL_START,
      nameProducts,
      /* callableCount= */ 0,
      callables,
      parameterCounts,
      resultTypes,
      functionNameIds,
      /* localTypeCount= */ 0,
      localTypes,
      code,
      /* codeLength= */ 0,
      strings,
      names.stringBytes,
      names.stringCount,
      stringStarts,
      stringLengths,
      artifact,
      identity
    );
    drop(nameProducts);
    drop(source);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(stringLengths);
    drop(stringStarts);
    drop(strings);
    drop(code);
    drop(localTypes);
    drop(functionNameIds);
    drop(resultTypes);
    drop(parameterCounts);
    drop(callables);
    drop(empty);
    return result;
  }

  /// Publishes an archive module from bound declaration names and a closed imported target view.
  public SourceProductArtifactPlan compileStructuredArchiveModuleWithTargetView(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long moduleOwner,
    borrow byteview moduleNames,
    long moduleNameStart,
    long moduleNameLength,
    long classNameStart,
    long classNameLength,
    long firstCallable,
    long callableCount,
    long importedTargetCount,
    borrow mut words importedTargetRows,
    borrow mut words importedTargetParameterRows,
    borrow byteview importedTargetNames,
    borrow byteview importedTargetIdentities,
    borrow byteview importedTargetQualifierNames,
    borrow mut words importedTargetQualifierNameStarts,
    borrow mut words importedTargetQualifierNameLengths,
    borrow mut words importedTargetQualifierDependencyRanks,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    long importedCount,
    borrow mut words importedRows,
    borrow byteview importedNames,
    borrow mut words importedNameStarts,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words callableEffects,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words relocationRows,
    borrow mut words relocationOwners,
    borrow mut bytes relocationIdentities,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    requireArchiveSourceNames(
      archive,
      sourceStart,
      sourceLength,
      moduleNames,
      moduleNameStart,
      moduleNameLength,
      classNameStart,
      classNameLength
    );
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < firstCallable);
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-1 < importedTargetCount);
    assert(importedTargetCount < 4097);
    assert(bufferLength(callableBodyStarts) == 4096);
    assert(bufferLength(callableBodyLengths) == 4096);
    requireArchiveConstantPacket(importedCount, importedRows, importedNames, importedNameStarts);
    assert(bufferLength(callableFirstParameters) == 4096);
    assert(bufferLength(callableParameterCounts) == 4096);
    assert(bufferLength(callableResultTypes) == 4096);
    assert(bufferLength(callableEffects) == 4096);
    assert(bufferLength(parameterTypes) == MAX_PARAMETERS);
    assert(bufferLength(parameterModes) == MAX_PARAMETERS);
    assert(bufferLength(callableNameStarts) == 4096);
    assert(bufferLength(callableNameLengths) == 4096);
    assert(bufferLength(artifact) == 32768);
    assert(bufferLength(identity) == 32);
    if (callableCount == 0) {
      return compileCallableFreeArchiveModule(
        archive,
        sourceStart,
        sourceLength,
        classNameStart,
        classNameLength,
        importedCount,
        importedRows,
        importedNames,
        importedNameStarts,
        artifact,
        identity
      );
    }

    region sourceArena = new region(/* bytes= */ ARTIFACT_BYTES, /* allocations= */ 1);
    bytes sourceBytes = allocateBytes(sourceArena, sourceLength);
    long copiedSourceLength = copyRange(
      archive,
      sourceStart,
      sourceLength,
      sourceBytes,
      /* outputStart= */ 0
    );
    assert(copiedSourceLength == sourceLength);
    utf8 source = freezeUtf8(sourceBytes);
    region metadata = new region(/* bytes= */ METADATA_BYTES, /* allocations= */ METADATA_BUFFERS);
    words symbolOwners = allocate(metadata, MAX_CONSTANT_PRODUCTS);
    words symbolStarts = allocate(metadata, MAX_CONSTANT_PRODUCTS);
    words symbolLengths = allocate(metadata, MAX_CONSTANT_PRODUCTS);
    words symbolTypes = allocate(metadata, MAX_CONSTANT_PRODUCTS);
    words symbolValues = allocate(metadata, MAX_CONSTANT_PRODUCTS);
    words symbolResolved = allocate(metadata, MAX_CONSTANT_PRODUCTS);
    words signatureTypes = allocate(metadata, SIGNATURE_ROWS);
    words localParameterCounts = allocate(metadata, MAX_CALLABLES);
    words localResultTypes = allocate(metadata, MAX_CALLABLES);
    bytes strings = allocateBytes(metadata, ARTIFACT_BYTES);
    words stringStarts = allocate(metadata, MAX_SOURCE_MODULE_STRINGS);
    words stringLengths = allocate(metadata, MAX_SOURCE_MODULE_STRINGS);
    words functionNameIds = allocate(metadata, MAX_CALLABLES);
    words localBodyStarts = allocate(metadata, MAX_CLOSURE_CALLABLES);
    words localBodyLengths = allocate(metadata, MAX_CLOSURE_CALLABLES);
    words localCallableEffects = allocate(metadata, MAX_CLOSURE_CALLABLES);
    words nameProducts = allocate(metadata, SOURCE_MODULE_NAME_ROWS);
    SourceModuleNamePlan names = materializeSourceModuleNames(
      source,
      archive,
      classNameStart,
      classNameLength,
      moduleNames,
      moduleNameStart,
      moduleNameLength,
      firstCallable,
      callableCount,
      callableNames,
      callableNameStarts,
      callableNameLengths,
      importedNames,
      importedRows,
      localBodyStarts,
      localBodyLengths,
      localCallableEffects,
      strings,
      stringStarts,
      stringLengths,
      functionNameIds,
      nameProducts
    );

    long imported = 0;
    while (imported < importedCount) limit MAX_CONSTANT_PRODUCTS {
      long importedBase = CONSTANT_PRODUCT_HEADER_ROWS + imported * CONSTANT_PRODUCT_COLUMNS;
      set(symbolOwners, imported, moduleOwner);
      set(symbolStarts, imported, importedRows[importedBase + CONSTANT_NAME_START]);
      set(symbolLengths, imported, importedRows[importedBase + CONSTANT_NAME_LENGTH]);
      set(symbolTypes, imported, importedRows[importedBase + CONSTANT_TYPE]);
      set(symbolValues, imported, importedRows[importedBase + CONSTANT_VALUE]);
      set(symbolResolved, imported, importedRows[importedBase + CONSTANT_RESOLVED]);
      imported += 1;
    }

    long signatureTypeCount = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long sourceCallable = firstCallable + callable;
      long localBodyStart = callableBodyStarts[sourceCallable] - sourceStart;
      assert(-1 < localBodyStart);
      set(localBodyStarts, callable, localBodyStart);
      set(localBodyLengths, callable, callableBodyLengths[sourceCallable]);
      set(localCallableEffects, callable, callableEffects[sourceCallable]);
      long ownedParameters = callableParameterCounts[sourceCallable];
      assert(-1 < ownedParameters);
      assert(ownedParameters < MAX_SIGNATURE_TYPES);
      long localResultType = callableResultTypes[sourceCallable];
      assert(-1 < localResultType);
      assert(localResultType < 3);
      set(localResultTypes, callable, localResultType);
      set(localParameterCounts, callable, ownedParameters);
      long firstParameter = callableFirstParameters[sourceCallable];
      long parameter = 0;
      while (parameter < ownedParameters) limit MAX_SIGNATURE_TYPES {
        assert(signatureTypeCount < MAX_SIGNATURE_TYPES);
        set(signatureTypes, signatureTypeCount, callable);
        set(signatureTypes, 4096 + signatureTypeCount, parameter);
        set(
          signatureTypes,
          8192 + signatureTypeCount,
          localParameterType(
            parameterTypes[firstParameter + parameter],
            parameterModes[firstParameter + parameter]
          )
        );
        signatureTypeCount += 1;
        parameter += 1;
      }

      callable += 1;
    }

    SourceProductArtifactPlan result = compileStructuredSourceModuleWithTargets(
      names.classNameId,
      names.globalCount,
      SOURCE_MODULE_GLOBAL_START,
      nameProducts,
      source,
      importedNames,
      /* constantNames= */ importedNames,
      /* constants= */ importedRows,
      /* archiveSourceStart= */ 0,
      moduleOwner,
      /* firstCallable= */ 0,
      callableCount,
      localCallableEffects,
      importedTargetCount,
      importedTargetRows,
      importedTargetParameterRows,
      importedTargetNames,
      importedTargetIdentities,
      importedTargetQualifierNames,
      importedTargetQualifierNameStarts,
      importedTargetQualifierNameLengths,
      importedTargetQualifierDependencyRanks,
      localBodyStarts,
      localBodyLengths,
      importedCount,
      symbolOwners,
      symbolStarts,
      symbolLengths,
      symbolTypes,
      symbolValues,
      symbolResolved,
      signatureTypeCount,
      signatureTypes,
      localParameterCounts,
      localResultTypes,
      strings,
      names.stringBytes,
      names.stringCount,
      stringStarts,
      stringLengths,
      functionNameIds,
      relocationRows,
      relocationOwners,
      relocationIdentities,
      artifact,
      identity
    );

    drop(nameProducts);
    drop(localCallableEffects);
    drop(localBodyLengths);
    drop(localBodyStarts);
    drop(functionNameIds);
    drop(stringLengths);
    drop(stringStarts);
    drop(strings);
    drop(localResultTypes);
    drop(localParameterCounts);
    drop(signatureTypes);
    drop(symbolResolved);
    drop(symbolValues);
    drop(symbolTypes);
    drop(symbolLengths);
    drop(symbolStarts);
    drop(symbolOwners);
    drop(metadata);
    drop(source);
    drop(sourceArena);
    return result;
  }
}
