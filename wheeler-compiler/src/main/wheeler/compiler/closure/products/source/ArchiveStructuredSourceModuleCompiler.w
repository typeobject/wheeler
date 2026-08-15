//! Prepares archive-owned metadata for direct structured source-module compilation.

module wheeler.compiler.closure.archive_structured_source_module_compiler;

import wheeler.compiler.closure.imported_source_call_targets;
import wheeler.compiler.closure.source_call_target_table;
import wheeler.compiler.closure.source_product_artifact;
import wheeler.compiler.closure.structured_source_module_compiler;
import wheeler.core.encoding.binary;

classical class ArchiveStructuredSourceModuleCompiler {
  private const long MAX_CALLABLES = 64;
  private const long MAX_PARAMETERS = 16384;
  private const long MAX_SIGNATURE_TYPES = 4096;

  private record ClassNameRange(long start, long length, boolean valid) {}

  private record ModuleNameRange(long start, long length, boolean valid) {}

  private record NameUseRange(long start, boolean valid) {}

  private boolean classPrefix(borrow byteview source, long start) {
    boolean valid = true;
    if (source[start] != 99) {
      valid = false;
    }

    if (source[start + 1] != 108) {
      valid = false;
    }

    if (source[start + 2] != 97) {
      valid = false;
    }

    if (source[start + 3] != 115) {
      valid = false;
    }

    if (source[start + 4] != 115) {
      valid = false;
    }

    if (source[start + 5] != 105) {
      valid = false;
    }

    if (source[start + 6] != 99) {
      valid = false;
    }

    if (source[start + 7] != 97) {
      valid = false;
    }

    if (source[start + 8] != 108) {
      valid = false;
    }

    if (source[start + 9] != 32) {
      valid = false;
    }

    if (source[start + 10] != 99) {
      valid = false;
    }

    if (source[start + 11] != 108) {
      valid = false;
    }

    if (source[start + 12] != 97) {
      valid = false;
    }

    if (source[start + 13] != 115) {
      valid = false;
    }

    if (source[start + 14] != 115) {
      valid = false;
    }

    if (source[start + 15] != 32) {
      valid = false;
    }

    return valid;
  }

  private boolean modulePrefix(borrow byteview source, long start) {
    boolean valid = true;
    if (source[start] != 109) {
      valid = false;
    }

    if (source[start + 1] != 111) {
      valid = false;
    }

    if (source[start + 2] != 100) {
      valid = false;
    }

    if (source[start + 3] != 117) {
      valid = false;
    }

    if (source[start + 4] != 108) {
      valid = false;
    }

    if (source[start + 5] != 101) {
      valid = false;
    }

    if (source[start + 6] != 32) {
      valid = false;
    }

    return valid;
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

  private ClassNameRange sourceClassName(
    borrow byteview source,
    long sourceStart,
    long sourceLength
  ) {
    long selectedStart = 0;
    long selectedLength = 0;
    long matches = 0;
    long cursor = sourceStart;
    long sourceEnd = sourceStart + sourceLength;
    while (cursor + 16 < sourceEnd) limit 32768 {
      if (classPrefix(source, cursor)) {
        long nameStart = cursor + 16;
        long nameLength = 0;
        while (nameStart + nameLength < sourceEnd) limit 256 {
          if (identifierByte(source[nameStart + nameLength])) {
            nameLength += 1;
          } else {
            break;
          }
        }

        if (0 < nameLength) {
          selectedStart = nameStart;
          selectedLength = nameLength;
          matches += 1;
        }
      }

      cursor += 1;
    }

    return new ClassNameRange(selectedStart, selectedLength, matches == 1);
  }

  private ModuleNameRange sourceModuleName(
    borrow byteview source,
    long sourceStart,
    long sourceLength
  ) {
    long selectedStart = 0;
    long selectedLength = 0;
    long matches = 0;
    long cursor = sourceStart;
    long sourceEnd = sourceStart + sourceLength;
    while (cursor + 7 < sourceEnd) limit 32768 {
      if (modulePrefix(source, cursor)) {
        long nameStart = cursor + 7;
        long nameLength = 0;
        while (nameStart + nameLength < sourceEnd) limit 256 {
          long value = source[nameStart + nameLength];
          if (identifierByte(value)) {
            nameLength += 1;
          } else {
            if (value == 46) {
              nameLength += 1;
            } else {
              break;
            }
          }
        }

        if (0 < nameLength) {
          selectedStart = nameStart;
          selectedLength = nameLength;
          matches += 1;
        }
      }

      cursor += 1;
    }

    return new ModuleNameRange(selectedStart, selectedLength, matches == 1);
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

  /// Publishes one local-call archive module from closed value and callable products.
  public SourceProductArtifactPlan compileStructuredArchiveModule(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long moduleOwner,
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
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    region emptyTargets = new region(/* bytes= */ 1703936, /* allocations= */ 4);
    words importedTargetRows = allocate(emptyTargets, /* length= */ 32768);
    words importedTargetParameterRows = allocate(emptyTargets, /* length= */ 32768);
    bytes importedTargetNames = allocateBytes(emptyTargets, /* length= */ 1048576);
    bytes importedTargetIdentities = allocateBytes(emptyTargets, /* length= */ 131072);
    SourceProductArtifactPlan result = compileStructuredArchiveModuleWithTargetView(
      archive,
      sourceStart,
      sourceLength,
      moduleOwner,
      firstCallable,
      callableCount,
      /* importedTargetCount= */ 0,
      importedTargetRows,
      importedTargetParameterRows,
      importedTargetNames,
      importedTargetIdentities,
      callableBodyStarts,
      callableBodyLengths,
      importedCount,
      importedRows,
      importedNames,
      importedNameStarts,
      callableFirstParameters,
      callableParameterCounts,
      callableResultTypes,
      parameterTypes,
      parameterModes,
      callableNames,
      callableNameStarts,
      callableNameLengths,
      artifact,
      identity
    );
    drop(importedTargetIdentities);
    drop(importedTargetNames);
    drop(importedTargetParameterRows);
    drop(importedTargetRows);
    drop(emptyTargets);
    return result;
  }

  /// Publishes an archive module against one closed imported target view.
  public SourceProductArtifactPlan compileStructuredArchiveModuleWithTargetView(
    borrow byteview archive,
    long sourceStart,
    long sourceLength,
    long moduleOwner,
    long firstCallable,
    long callableCount,
    long importedTargetCount,
    borrow mut words importedTargetRows,
    borrow mut words importedTargetParameterRows,
    borrow byteview importedTargetNames,
    borrow byteview importedTargetIdentities,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    long importedCount,
    borrow mut words importedRows,
    borrow byteview importedNames,
    borrow mut words importedNameStarts,
    borrow mut words callableFirstParameters,
    borrow mut words callableParameterCounts,
    borrow mut words callableResultTypes,
    borrow mut words parameterTypes,
    borrow mut words parameterModes,
    borrow byteview callableNames,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut bytes artifact,
    borrow mut bytes identity
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceLength < 32769);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < firstCallable);
    assert(0 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(-1 < importedTargetCount);
    assert(importedTargetCount < 4097);
    assert(bufferLength(importedTargetRows) == 32768);
    assert(bufferLength(importedTargetParameterRows) == 32768);
    assert(bufferLength(importedTargetNames) == 1048576);
    assert(bufferLength(importedTargetIdentities) == 131072);
    assert(bufferLength(callableBodyStarts) == 4096);
    assert(bufferLength(callableBodyLengths) == 4096);
    assert(-1 < importedCount);
    assert(importedCount < 16385);
    assert(bufferLength(importedRows) == 114689);
    assert(16384 < bufferLength(importedNameStarts) + 1);
    assert(bufferLength(callableFirstParameters) == 4096);
    assert(bufferLength(callableParameterCounts) == 4096);
    assert(bufferLength(callableResultTypes) == 4096);
    assert(bufferLength(parameterTypes) == MAX_PARAMETERS);
    assert(bufferLength(parameterModes) == MAX_PARAMETERS);
    assert(bufferLength(callableNameStarts) == 4096);
    assert(bufferLength(callableNameLengths) == 4096);
    assert(bufferLength(artifact) == 32768);
    assert(bufferLength(identity) == 32);

    ClassNameRange className = sourceClassName(archive, sourceStart, sourceLength);
    ModuleNameRange moduleName = sourceModuleName(archive, sourceStart, sourceLength);
    assert(className.valid);
    assert(moduleName.valid);
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
    region metadata = new region(/* bytes= */ 988160, /* allocations= */ 14);
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
    set(stringLengths, 1, className.length);
    stringCursor = copyRange(archive, className.start, className.length, strings, stringCursor);

    long signatureTypeCount = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long sourceCallable = firstCallable + callable;
      long localBodyStart = callableBodyStarts[sourceCallable] - sourceStart;
      assert(-1 < localBodyStart);
      set(localBodyStarts, callable, localBodyStart);
      set(localBodyLengths, callable, callableBodyLengths[sourceCallable]);
      long ownedParameters = callableParameterCounts[sourceCallable];
      assert(-1 < ownedParameters);
      assert(ownedParameters < MAX_SIGNATURE_TYPES);
      assert(callableResultTypes[sourceCallable] == 1);
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

      long string = callable + 2;
      long callableNameStart = callableNameStarts[sourceCallable];
      long callableNameLength = callableNameLengths[sourceCallable];
      assert(0 < callableNameLength);
      set(stringStarts, string, stringCursor);
      stringCursor = copyRange(
        archive,
        moduleName.start,
        moduleName.length,
        strings,
        stringCursor
      );
      writeAscii(strings, stringCursor, "::");
      stringCursor += 2;
      stringCursor = copyRange(
        callableNames,
        callableNameStart,
        callableNameLength,
        strings,
        stringCursor
      );
      set(stringLengths, string, moduleName.length + 2 + callableNameLength);
      set(functionNameIds, callable, string);
      callable += 1;
    }

    SourceProductArtifactPlan result = compileStructuredSourceModuleWithTargets(
      source,
      /* archiveSourceStart= */ 0,
      moduleOwner,
      /* firstCallable= */ 0,
      callableCount,
      importedTargetCount,
      importedTargetRows,
      importedTargetParameterRows,
      importedTargetNames,
      importedTargetIdentities,
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
      artifact,
      identity
    );

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
