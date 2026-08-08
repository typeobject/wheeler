//! Publishes counted callable signatures and body ranges from staged closure sources.

module wheeler.compiler.closure.module_callables;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.closure.manifest_syntax;
import wheeler.compiler.closure.plan;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;

classical class CountedModuleCallables {
  private const long CALLABLE_ARENA_BYTES = 865000;
  private const long MAX_CALLABLES = 4096;
  private const long MAX_CALLABLES_PER_MODULE = 64;
  private const long MAX_DIRECT_IMPORTS = 64;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_LOCAL_MODULES = 512;
  private const long TOKEN_ARENA_BYTES = 98320;
  private const long TOKEN_RECORD = 3360058449;

  /// Describes one completely published closure-wide callable table.
  public record CountedModuleCallablePlan(
    long moduleCount,
    long callableCount,
    long parameterCount,
    long peakActiveSources,
    long finalGeneration
  ) {}

  private long closingBrace(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long tokenCount
  ) {
    long depth = 1;
    long cursor = open + 1;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_BRACE)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_BRACE)
      ) {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private long closingParen(
    borrow utf8 source,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    long open,
    long limitToken
  ) {
    long depth = 1;
    long cursor = open + 1;
    while (cursor < limitToken) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
      ) {
        depth += 1;
      }

      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_PAREN)
      ) {
        depth -= 1;
        if (depth == 0) {
          return cursor;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private long indexSourceCallables(
    borrow utf8 source,
    long archiveSourceStart,
    long owner,
    long firstCallable,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words moduleRange,
    borrow mut words callableOwners,
    borrow mut words callableVisibilities,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableSignatureStarts,
    borrow mut words callableSignatureLengths,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callableFirstParameters,
    borrow mut words callableResultTypeStarts,
    borrow mut words callableResultTypeLengths,
    borrow mut words callableEffects,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes,
    borrow mut words parameterTotal
  ) {
    long tokenCount = scanSemanticTokens(source, tokenKinds, tokenStarts, tokenLengths);
    if (0 < tokenCount) {} else {
      return -1;
    }

    long body = moduleBodyStart(
      source,
      tokenKinds,
      tokenStarts,
      tokenLengths,
      moduleRange,
      tokenCount
    );
    if (-1 < body) {} else {
      return -1;
    }

    long cursor = body + 4;
    long callableCount = 0;
    boolean classClosed = false;
    while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
      if (
        punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_CLOSE_BRACE)
      ) {
        classClosed = cursor + 1 == tokenCount;
        break;
      }

      long declarationStart = cursor;
      long firstParen = -1;
      long delimiter = -1;
      boolean bodyDelimiter = false;
      while (cursor < tokenCount) limit MAX_COMPILER_TOKENS {
        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_PAREN)
        ) {
          if (firstParen < 0) {
            firstParen = cursor;
          }
        }

        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_SEMICOLON)
        ) {
          delimiter = cursor;
          break;
        }

        if (
          punctuationAt(source, tokenKinds, tokenStarts, cursor, PUNCTUATION_OPEN_BRACE)
        ) {
          delimiter = cursor;
          bodyDelimiter = true;
          break;
        }

        cursor += 1;
      }

      if (-1 < delimiter) {} else {
        return -1;
      }

      if (bodyDelimiter) {
        long closeBody = closingBrace(source, tokenKinds, tokenStarts, delimiter, tokenCount);
        if (-1 < closeBody) {} else {
          return -1;
        }

        long nextDeclaration = closeBody + 1;
        if (nextDeclaration + 1 < tokenCount) {
          if (
            tokenHash(source, tokenStarts, tokenLengths, nextDeclaration) == TOKEN_REVERSE
          ) {
            if (
              punctuationAt(
                source,
                tokenKinds,
                tokenStarts,
                nextDeclaration + 1,
                PUNCTUATION_OPEN_BRACE
              )
            ) {
              long closeReverse = closingBrace(
                source,
                tokenKinds,
                tokenStarts,
                nextDeclaration + 1,
                tokenCount
              );
              if (-1 < closeReverse) {} else {
                return -1;
              }

              closeBody = closeReverse;
              nextDeclaration = closeReverse + 1;
            }
          }
        }

        boolean callable = 0 < firstParen;
        long nameToken = firstParen - 1;
        if (callable) {
          if (0 < nameToken) {} else {
            return -1;
          }

          if (
            tokenHash(source, tokenStarts, tokenLengths, nameToken - 1) == TOKEN_RECORD
          ) {
            callable = false;
          }
        }

        if (callable) {
          long closeParameters = closingParen(
            source,
            tokenKinds,
            tokenStarts,
            firstParen,
            delimiter
          );
          if (-1 < closeParameters) {} else {
            return -1;
          }

          long parameters = parameterCount(
            source,
            tokenKinds,
            tokenStarts,
            firstParen,
            closeParameters
          );
          if (-1 < parameters) {} else {
            return -1;
          }

          CallableHeader header = callableHeader(
            source,
            tokenStarts,
            tokenLengths,
            declarationStart,
            nameToken
          );
          if (header.valid) {} else {
            return -1;
          }

          long nextParameter = writeParameterProducts(
            source,
            archiveSourceStart,
            tokenKinds,
            tokenStarts,
            tokenLengths,
            firstParen,
            closeParameters,
            parameters,
            parameterTotal[0],
            parameterTypeStarts,
            parameterTypeLengths,
            parameterModes
          );
          if (-1 < nextParameter) {} else {
            return -1;
          }

          if (callableCount < MAX_CALLABLES_PER_MODULE) {} else {
            return -1;
          }

          long callableIndex = firstCallable + callableCount;
          if (callableIndex < MAX_CALLABLES) {} else {
            return -1;
          }

          long visibility = 0;
          if (
            tokenHash(source, tokenStarts, tokenLengths, declarationStart) == TOKEN_PUBLIC
          ) {
            visibility = 1;
          }

          long signatureStart = tokenStarts[declarationStart];
          long bodyStart = tokenStarts[delimiter];
          long bodyEnd = tokenStarts[closeBody] + tokenLengths[closeBody];
          set(callableOwners, callableIndex, owner);
          set(callableVisibilities, callableIndex, visibility);
          set(callableNameStarts, callableIndex, archiveSourceStart + tokenStarts[nameToken]);
          set(callableNameLengths, callableIndex, tokenLengths[nameToken]);
          set(callableSignatureStarts, callableIndex, archiveSourceStart + signatureStart);
          set(callableSignatureLengths, callableIndex, bodyStart - signatureStart);
          set(callableBodyStarts, callableIndex, archiveSourceStart + bodyStart);
          set(callableBodyLengths, callableIndex, bodyEnd - bodyStart);
          set(callableParameterCounts, callableIndex, parameters);
          set(callableFirstParameters, callableIndex, parameterTotal[0]);
          long resultTypeStart = tokenStarts[header.resultTypeToken];
          long finalResultType = nameToken - 1;
          long resultTypeEnd = tokenStarts[finalResultType] + tokenLengths[finalResultType];
          set(callableResultTypeStarts, callableIndex, archiveSourceStart + resultTypeStart);
          set(callableResultTypeLengths, callableIndex, resultTypeEnd - resultTypeStart);
          set(callableEffects, callableIndex, header.effects);
          set(parameterTotal, 0, nextParameter);
          callableCount += 1;
        }

        cursor = nextDeclaration;
      } else {
        cursor = delimiter + 1;
      }
    }

    if (classClosed) {
      return callableCount;
    }

    return -1;
  }

  private boolean columnsValid(
    borrow mut words moduleFirstCallables,
    borrow mut words moduleCallableCounts,
    borrow mut words moduleImportedCallableCounts,
    borrow mut words edgeCallableCounts,
    borrow mut words callableOwners,
    borrow mut words callableVisibilities,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableSignatureStarts,
    borrow mut words callableSignatureLengths,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callableFirstParameters,
    borrow mut words callableResultTypeStarts,
    borrow mut words callableResultTypeLengths,
    borrow mut words callableEffects,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes
  ) {
    if (bufferLength(moduleFirstCallables) == MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (bufferLength(moduleCallableCounts) == MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (bufferLength(moduleImportedCallableCounts) == MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (bufferLength(edgeCallableCounts) == MAX_IMPORTS) {} else {
      return false;
    }

    if (bufferLength(callableOwners) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableVisibilities) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableNameStarts) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableNameLengths) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableSignatureStarts) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableSignatureLengths) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableBodyStarts) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableBodyLengths) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableParameterCounts) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableFirstParameters) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableResultTypeStarts) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableResultTypeLengths) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(callableEffects) == MAX_CALLABLES) {} else {
      return false;
    }

    if (bufferLength(parameterTypeStarts) == MAX_CLOSURE_PARAMETERS) {} else {
      return false;
    }

    if (bufferLength(parameterTypeLengths) == MAX_CLOSURE_PARAMETERS) {} else {
      return false;
    }

    return bufferLength(parameterModes) == MAX_CLOSURE_PARAMETERS;
  }

  /// Stages each source once and publishes callable products after the complete pass.
  public CountedModuleCallablePlan indexCountedModuleCallables(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    borrow mut words edgeTargets,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words leafFirstOrder,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words moduleFirstCallables,
    borrow mut words moduleCallableCounts,
    borrow mut words moduleImportedCallableCounts,
    borrow mut words edgeCallableCounts,
    borrow mut words callableOwners,
    borrow mut words callableVisibilities,
    borrow mut words callableNameStarts,
    borrow mut words callableNameLengths,
    borrow mut words callableSignatureStarts,
    borrow mut words callableSignatureLengths,
    borrow mut words callableBodyStarts,
    borrow mut words callableBodyLengths,
    borrow mut words callableParameterCounts,
    borrow mut words callableFirstParameters,
    borrow mut words callableResultTypeStarts,
    borrow mut words callableResultTypeLengths,
    borrow mut words callableEffects,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes
  ) {
    requireMetadata(0 < plan.moduleCount, manifest);
    requireMetadata(plan.moduleCount < MAX_LOCAL_MODULES + 1, manifest);
    requireMetadata(plan.importCount < MAX_IMPORTS + 1, manifest);
    requireMetadata(
      columnsValid(
        moduleFirstCallables,
        moduleCallableCounts,
        moduleImportedCallableCounts,
        edgeCallableCounts,
        callableOwners,
        callableVisibilities,
        callableNameStarts,
        callableNameLengths,
        callableSignatureStarts,
        callableSignatureLengths,
        callableBodyStarts,
        callableBodyLengths,
        callableParameterCounts,
        callableFirstParameters,
        callableResultTypeStarts,
        callableResultTypeLengths,
        callableEffects,
        parameterTypeStarts,
        parameterTypeLengths,
        parameterModes
      ),
      manifest
    );

    region slotArena = new region(
      /* bytes= */ ACTIVE_SOURCE_SLOT_ARENA_BYTES,
      /* allocations= */ 6
    );
    bytes storage = allocateBytes(slotArena, ACTIVE_SOURCE_SLOT_BYTES);
    words owners = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words generations = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words activeLengths = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words live = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    assert(initializeActiveSourceSlots(storage, owners, generations, activeLengths, live));
    region callableArena = new region(/* bytes= */ CALLABLE_ARENA_BYTES, /* allocations= */ 23);
    words scratchFirstCallables = allocate(callableArena, MAX_LOCAL_MODULES);
    words scratchCallableCounts = allocate(callableArena, MAX_LOCAL_MODULES);
    words scratchImportedCounts = allocate(callableArena, MAX_LOCAL_MODULES);
    words scratchEdgeCounts = allocate(callableArena, MAX_IMPORTS);
    words scratchOwners = allocate(callableArena, MAX_CALLABLES);
    words scratchVisibilities = allocate(callableArena, MAX_CALLABLES);
    words scratchNameStarts = allocate(callableArena, MAX_CALLABLES);
    words scratchNameLengths = allocate(callableArena, MAX_CALLABLES);
    words scratchSignatureStarts = allocate(callableArena, MAX_CALLABLES);
    words scratchSignatureLengths = allocate(callableArena, MAX_CALLABLES);
    words scratchBodyStarts = allocate(callableArena, MAX_CALLABLES);
    words scratchBodyLengths = allocate(callableArena, MAX_CALLABLES);
    words scratchParameterCounts = allocate(callableArena, MAX_CALLABLES);
    words scratchFirstParameters = allocate(callableArena, MAX_CALLABLES);
    words scratchResultTypeStarts = allocate(callableArena, MAX_CALLABLES);
    words scratchResultTypeLengths = allocate(callableArena, MAX_CALLABLES);
    words scratchEffects = allocate(callableArena, MAX_CALLABLES);
    words scratchParameterTypeStarts = allocate(callableArena, MAX_CLOSURE_PARAMETERS);
    words scratchParameterTypeLengths = allocate(callableArena, MAX_CLOSURE_PARAMETERS);
    words scratchParameterModes = allocate(callableArena, MAX_CLOSURE_PARAMETERS);
    words parameterTotal = allocate(callableArena, 1);
    words processed = allocate(callableArena, MAX_LOCAL_MODULES);
    words moduleRangeScratch = allocate(callableArena, 2);
    long callableCount = 0;
    long finalGeneration = 0;
    long position = 0;
    while (position < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long module = leafFirstOrder[position];
      requireMetadata(-1 < module, manifest);
      requireMetadata(module < plan.moduleCount, manifest);
      requireMetadata(processed[module] == 0, manifest);
      long firstImport = firstImports[module];
      long importCount = directImportCounts[module];
      requireMetadata(-1 < firstImport, manifest);
      requireMetadata(-1 < importCount, manifest);
      requireMetadata(importCount < MAX_DIRECT_IMPORTS + 1, manifest);
      long importedCount = 0;
      long rank = 0;
      while (rank < importCount) limit MAX_DIRECT_IMPORTS {
        long edge = firstImport + rank;
        requireMetadata(edge < plan.importCount, manifest);
        long dependency = edgeTargets[edge];
        long visible = 0;
        if (-1 < dependency) {
          requireMetadata(dependency < plan.moduleCount, manifest);
          requireMetadata(processed[dependency] == 1, manifest);
          long dependencyFirst = scratchFirstCallables[dependency];
          long dependencyCount = scratchCallableCounts[dependency];
          long dependencyOffset = 0;
          while (dependencyOffset < dependencyCount) limit MAX_CALLABLES_PER_MODULE {
            if (scratchVisibilities[dependencyFirst + dependencyOffset] == 1) {
              visible += 1;
            }

            dependencyOffset += 1;
          }
        }

        set(scratchEdgeCounts, edge, visible);
        importedCount += visible;
        rank += 1;
      }

      region sourceArena = new region(/* bytes= */ 65536, /* allocations= */ 2);
      bytes archiveSource = allocateBytes(sourceArena, sourceLengths[module]);
      long copied = 0;
      while (copied < sourceLengths[module]) limit 32768 {
        setByte(archiveSource, copied, archive[sourceStarts[module] + copied]);
        copied += 1;
      }

      utf8 source = freezeUtf8(archiveSource);
      ActiveSourceHandle selected = new ActiveSourceHandle(-1, 0, module);
      ActiveSourceAcquireResult acquired = acquireActiveSourceSlot(
        module,
        storage,
        owners,
        generations,
        activeLengths,
        live
      );
      match (acquired) {
        case ActiveSourceAcquireResult.Value(ActiveSourceHandle handle) {
          selected = handle;
        }
        case ActiveSourceAcquireResult.Full(long failedOwner) {
          requireMetadata(failedOwner < 0, manifest);
        }
      }

      requireMetadata(-1 < selected.slot, manifest);
      requireMetadata(
        publishActiveSource(
          selected,
          source,
          storage,
          owners,
          generations,
          activeLengths,
          live
        ),
        manifest
      );
      bytes activeBytes = allocateBytes(sourceArena, sourceLengths[module]);
      requireMetadata(
        copyActiveSource(
          selected,
          storage,
          owners,
          generations,
          activeLengths,
          live,
          activeBytes
        ),
        manifest
      );
      utf8 activeSource = freezeUtf8(activeBytes);
      region tokenArena = new region(/* bytes= */ TOKEN_ARENA_BYTES, /* allocations= */ 3);
      words tokenKinds = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words tokenStarts = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words tokenLengths = allocate(tokenArena, MAX_COMPILER_TOKENS);
      set(scratchFirstCallables, module, callableCount);
      long localCallables = indexSourceCallables(
        activeSource,
        sourceStarts[module],
        module,
        callableCount,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        moduleRangeScratch,
        scratchOwners,
        scratchVisibilities,
        scratchNameStarts,
        scratchNameLengths,
        scratchSignatureStarts,
        scratchSignatureLengths,
        scratchBodyStarts,
        scratchBodyLengths,
        scratchParameterCounts,
        scratchFirstParameters,
        scratchResultTypeStarts,
        scratchResultTypeLengths,
        scratchEffects,
        scratchParameterTypeStarts,
        scratchParameterTypeLengths,
        scratchParameterModes,
        parameterTotal
      );
      requireMetadata(-1 < localCallables, manifest);
      callableCount += localCallables;
      requireMetadata(callableCount < MAX_CALLABLES + 1, manifest);
      set(scratchCallableCounts, module, localCallables);
      set(scratchImportedCounts, module, importedCount);
      set(processed, module, 1);
      finalGeneration = selected.generation;
      requireMetadata(
        releaseActiveSource(selected, storage, owners, generations, activeLengths, live),
        manifest
      );
      drop(tokenLengths);
      drop(tokenStarts);
      drop(tokenKinds);
      drop(tokenArena);
      drop(activeSource);
      drop(source);
      drop(sourceArena);
      position += 1;
    }

    long publishedModule = 0;
    while (publishedModule < plan.moduleCount) limit MAX_LOCAL_MODULES {
      set(moduleFirstCallables, publishedModule, scratchFirstCallables[publishedModule]);
      set(moduleCallableCounts, publishedModule, scratchCallableCounts[publishedModule]);
      set(moduleImportedCallableCounts, publishedModule, scratchImportedCounts[publishedModule]);
      publishedModule += 1;
    }

    long publishedEdge = 0;
    while (publishedEdge < plan.importCount) limit MAX_IMPORTS {
      set(edgeCallableCounts, publishedEdge, scratchEdgeCounts[publishedEdge]);
      publishedEdge += 1;
    }

    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      set(callableOwners, callable, scratchOwners[callable]);
      set(callableVisibilities, callable, scratchVisibilities[callable]);
      set(callableNameStarts, callable, scratchNameStarts[callable]);
      set(callableNameLengths, callable, scratchNameLengths[callable]);
      set(callableSignatureStarts, callable, scratchSignatureStarts[callable]);
      set(callableSignatureLengths, callable, scratchSignatureLengths[callable]);
      set(callableBodyStarts, callable, scratchBodyStarts[callable]);
      set(callableBodyLengths, callable, scratchBodyLengths[callable]);
      set(callableParameterCounts, callable, scratchParameterCounts[callable]);
      set(callableFirstParameters, callable, scratchFirstParameters[callable]);
      set(callableResultTypeStarts, callable, scratchResultTypeStarts[callable]);
      set(callableResultTypeLengths, callable, scratchResultTypeLengths[callable]);
      set(callableEffects, callable, scratchEffects[callable]);
      callable += 1;
    }

    long parameter = 0;
    while (parameter < parameterTotal[0]) limit MAX_CLOSURE_PARAMETERS {
      set(parameterTypeStarts, parameter, scratchParameterTypeStarts[parameter]);
      set(parameterTypeLengths, parameter, scratchParameterTypeLengths[parameter]);
      set(parameterModes, parameter, scratchParameterModes[parameter]);
      parameter += 1;
    }

    CountedModuleCallablePlan result = new CountedModuleCallablePlan(
      plan.moduleCount,
      callableCount,
      parameterTotal[0],
      /* peakActiveSources= */ 1,
      finalGeneration
    );
    drop(moduleRangeScratch);
    drop(processed);
    drop(parameterTotal);
    drop(scratchParameterModes);
    drop(scratchParameterTypeLengths);
    drop(scratchParameterTypeStarts);
    drop(scratchEffects);
    drop(scratchResultTypeLengths);
    drop(scratchResultTypeStarts);
    drop(scratchFirstParameters);
    drop(scratchParameterCounts);
    drop(scratchBodyLengths);
    drop(scratchBodyStarts);
    drop(scratchSignatureLengths);
    drop(scratchSignatureStarts);
    drop(scratchNameLengths);
    drop(scratchNameStarts);
    drop(scratchVisibilities);
    drop(scratchOwners);
    drop(scratchEdgeCounts);
    drop(scratchImportedCounts);
    drop(scratchCallableCounts);
    drop(scratchFirstCallables);
    drop(callableArena);
    drop(live);
    drop(activeLengths);
    drop(generations);
    drop(owners);
    drop(storage);
    drop(slotArena);
    return result;
  }
}
