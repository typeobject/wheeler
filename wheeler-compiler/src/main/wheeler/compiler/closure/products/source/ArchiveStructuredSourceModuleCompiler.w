//! Prepares archive-owned metadata for direct structured source-module compilation.

module wheeler.compiler.closure.archive_structured_source_module_compiler;

import wheeler.compiler.closure.imported_source_call_targets;
import wheeler.compiler.closure.source_call_target_table;
import wheeler.compiler.closure.source_module_product_artifact;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.structured_source_module_compiler;
import wheeler.core.encoding.binary;

classical class ArchiveStructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_PARAMETERS = 16384;
  private const long MAX_SIGNATURE_TYPES = 4096;

  private record NameUseRange(long start, boolean valid) {}

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

  private boolean identifierByte(long value) {
    if (value == 95) {
      return true;
    }

    if (47 < value) {
      if (value < 58) {
        return true;
      }
    }

    if (64 < value) {
      if (value < 91) {
        return true;
      }
    }

    if (96 < value) {
      return value < 123;
    }

    return false;
  }

  private boolean nameBefore(
    borrow byteview names,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    long shared = leftLength;
    if (rightLength < shared) {
      shared = rightLength;
    }

    long index = 0;
    while (index < shared) limit 256 {
      if (names[leftStart + index] < names[rightStart + index]) {
        return true;
      }

      if (names[rightStart + index] < names[leftStart + index]) {
        return false;
      }

      index += 1;
    }

    return leftLength < rightLength;
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

  private NameUseRange sourceNameUse(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    borrow byteview names,
    long nameStart,
    long nameLength
  ) {
    long selected = 0;
    long matches = 0;
    long candidate = sourceStart;
    long sourceEnd = sourceStart + sourceLength;
    while (candidate + nameLength < sourceEnd + 1) limit 32768 {
      boolean same = true;
      long offset = 0;
      while (offset < nameLength) limit 256 {
        if (source[candidate + offset] != names[nameStart + offset]) {
          same = false;
        }

        offset += 1;
      }

      if (same) {
        if (sourceStart < candidate) {
          if (identifierByte(source[candidate - 1])) {
            same = false;
          }
        }

        if (candidate + nameLength < sourceEnd) {
          if (identifierByte(source[candidate + nameLength])) {
            same = false;
          }
        }
      }

      if (same) {
        selected = candidate - sourceStart;
        matches += 1;
      }

      candidate += 1;
    }

    return new NameUseRange(selected, matches == 1);
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
      archive, sourceStart, sourceLength, moduleNames,
      moduleNameStart, moduleNameLength, classNameStart, classNameLength
    );
    if (callableCount == 0) {
      return compileCallableFreeArchiveModule(
        archive, classNameStart, classNameLength, artifact, identity
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
    long classNameStart,
    long classNameLength,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    region empty = new region(/* bytes= */ 140000, /* allocations= */ 9);
    words callables = allocate(empty, /* length= */ 320);
    words parameterCounts = allocate(empty, /* length= */ 64);
    words resultTypes = allocate(empty, /* length= */ 64);
    words functionNameIds = allocate(empty, /* length= */ 64);
    words localTypes = allocate(empty, /* length= */ 12288);
    bytes code = allocateBytes(empty, /* length= */ 1);
    bytes strings = allocateBytes(empty, /* length= */ 32768);
    words stringStarts = allocate(empty, /* length= */ 256);
    words stringLengths = allocate(empty, /* length= */ 256);
    writeAscii(strings, /* outputStart= */ 0, "$library");
    set(stringStarts, 0, 0);
    set(stringLengths, 0, 8);
    set(stringStarts, 1, 8);
    set(stringLengths, 1, classNameLength);
    long stringBytes = copyRange(archive, classNameStart, classNameLength, strings, 8);
    SourceProductArtifactPlan result = publishClassicalSourceModuleArtifact(
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
      stringBytes,
      /* stringCount= */ 2,
      stringStarts,
      stringLengths,
      artifact,
      identity
    );
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
      archive, sourceStart, sourceLength, moduleNames,
      moduleNameStart, moduleNameLength, classNameStart, classNameLength
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
    assert(-1 < importedCount);
    assert(importedCount < 16385);
    assert(bufferLength(importedRows) == 114689);
    assert(16384 < bufferLength(importedNameStarts) + 1);
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
        archive, classNameStart, classNameLength, artifact, identity
      );
    }
    region sourceArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
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
    region metadata = new region(/* bytes= */ 1021440, /* allocations= */ 16);
    words symbolOwners = allocate(metadata, /* length= */ 16384);
    words symbolStarts = allocate(metadata, /* length= */ 16384);
    words symbolLengths = allocate(metadata, /* length= */ 16384);
    words symbolTypes = allocate(metadata, /* length= */ 16384);
    words symbolValues = allocate(metadata, /* length= */ 16384);
    words symbolResolved = allocate(metadata, /* length= */ 16384);
    words signatureTypes = allocate(metadata, /* length= */ 12288);
    words localParameterCounts = allocate(metadata, /* length= */ 64);
    bytes strings = allocateBytes(metadata, /* length= */ 32768);
    words stringStarts = allocate(metadata, /* length= */ 256);
    words stringLengths = allocate(metadata, /* length= */ 256);
    words functionNameIds = allocate(metadata, /* length= */ 64);
    words localBodyStarts = allocate(metadata, /* length= */ 4096);
    words localBodyLengths = allocate(metadata, /* length= */ 4096);
    words localCallableEffects = allocate(metadata, /* length= */ 4096);
    words selectedCallableNames = allocate(metadata, /* length= */ 64);

    long imported = 0;
    while (imported < importedCount) limit 16384 {
      long importedBase = 1 + imported * 7;
      set(symbolOwners, imported, moduleOwner);
      NameUseRange nameUse = sourceNameUse(
        archive,
        sourceStart,
        sourceLength,
        importedNames,
        importedNameStarts[imported],
        importedRows[importedBase + 1]
      );
      set(symbolStarts, imported, nameUse.start);
      set(symbolLengths, imported, importedRows[importedBase + 1]);
      set(symbolTypes, imported, importedRows[importedBase + 2]);
      set(symbolValues, imported, importedRows[importedBase + 3]);
      set(symbolResolved, imported, importedRows[importedBase + 4]);
      imported += 1;
    }

    long stringCursor = 0;
    writeAscii(strings, stringCursor, "$library");
    set(stringStarts, 0, stringCursor);
    set(stringLengths, 0, 8);
    stringCursor += 8;
    set(stringStarts, 1, stringCursor);
    set(stringLengths, 1, classNameLength);
    stringCursor = copyRange(archive, classNameStart, classNameLength, strings, stringCursor);

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

    long nameRank = 0;
    while (nameRank < callableCount) limit MAX_CALLABLES {
      long selected = -1;
      long candidate = 0;
      while (candidate < callableCount) limit MAX_CALLABLES {
        if (selectedCallableNames[candidate] == 0) {
          if (selected < 0) {
            selected = candidate;
          } else {
            long candidateCallable = firstCallable + candidate;
            long selectedCallable = firstCallable + selected;
            if (
              nameBefore(
                callableNames,
                callableNameStarts[candidateCallable],
                callableNameLengths[candidateCallable],
                callableNameStarts[selectedCallable],
                callableNameLengths[selectedCallable]
              )
            ) {
              selected = candidate;
            }
          }
        }

        candidate += 1;
      }

      assert(-1 < selected);
      set(selectedCallableNames, selected, 1);
      long selectedSourceCallable = firstCallable + selected;
      long selectedNameLength = callableNameLengths[selectedSourceCallable];
      assert(0 < selectedNameLength);
      long string = nameRank + 2;
      set(stringStarts, string, stringCursor);
      stringCursor = copyRange(
        moduleNames,
        moduleNameStart,
        moduleNameLength,
        strings,
        stringCursor
      );
      writeAscii(strings, stringCursor, "::");
      stringCursor += 2;
      stringCursor = copyRange(
        callableNames,
        callableNameStarts[selectedSourceCallable],
        selectedNameLength,
        strings,
        stringCursor
      );
      set(stringLengths, string, moduleNameLength + 2 + selectedNameLength);
      set(functionNameIds, selected, string);
      nameRank += 1;
    }

    SourceProductArtifactPlan result = compileStructuredSourceModuleWithTargets(
      source,
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
      strings,
      stringCursor,
      callableCount + 2,
      stringStarts,
      stringLengths,
      functionNameIds,
      relocationRows,
      relocationOwners,
      relocationIdentities,
      artifact,
      identity
    );

    drop(selectedCallableNames);
    drop(localCallableEffects);
    drop(localBodyLengths);
    drop(localBodyStarts);
    drop(functionNameIds);
    drop(stringLengths);
    drop(stringStarts);
    drop(strings);
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
