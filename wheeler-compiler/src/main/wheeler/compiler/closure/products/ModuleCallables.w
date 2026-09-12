//! Publishes counted callable signatures and body ranges from staged closure sources.

module wheeler.compiler.closure.module_callables;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.callable_signature_products;
import wheeler.compiler.closure.manifest_assertions;
import wheeler.compiler.closure.plan;
import wheeler.compiler.closure.source_callable_front_products;
import wheeler.compiler.compiler_token_limits;

classical class CountedModuleCallables {
  private const long MAX_CALLABLES = 4096;
  private const long MAX_CALLABLE_NAME_BYTES = 1048576;
  private const long MAX_CALLABLE_NAME_LENGTH = 256;
  private const long MAX_CALLABLES_PER_MODULE = 64;
  private const long MAX_DIRECT_IMPORTS = 64;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long WORD_BYTES = 8;
  private const long TOKEN_COLUMNS = 3;
  private const long MODULE_PRODUCT_COLUMNS = 3;
  private const long MODULE_WORK_COLUMNS = 1;
  private const long CALLABLE_PRODUCT_COLUMNS = 14;
  private const long PARAMETER_PRODUCT_COLUMNS = 3;
  private const long MODULE_RANGE_WORDS = 2;
  private const long PARAMETER_TOTAL_WORDS = 1;
  private const long CALLABLE_ARENA_WORDS = MAX_LOCAL_MODULES * (
    MODULE_PRODUCT_COLUMNS + MODULE_WORK_COLUMNS
  ) + MAX_IMPORTS + MAX_CALLABLES * CALLABLE_PRODUCT_COLUMNS + MAX_CLOSURE_PARAMETERS
    * PARAMETER_PRODUCT_COLUMNS + MODULE_RANGE_WORDS + PARAMETER_TOTAL_WORDS;
  private const long CALLABLE_ARENA_BYTES = CALLABLE_ARENA_WORDS * WORD_BYTES;
  private const long CALLABLE_ARENA_BUFFERS = MODULE_PRODUCT_COLUMNS + MODULE_WORK_COLUMNS
    + CALLABLE_PRODUCT_COLUMNS + PARAMETER_PRODUCT_COLUMNS + 1 + 1 + 1;
  private const long TOKEN_ARENA_BYTES = MAX_COMPILER_TOKENS * TOKEN_COLUMNS * WORD_BYTES;

  /// Describes one completely published closure-wide callable table.
  public record CountedModuleCallablePlan(
    long moduleCount,
    long callableCount,
    long parameterCount,
    long peakActiveSources,
    long finalGeneration
  ) {}

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
    borrow mut words callableResultSlotWidths,
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

    if (bufferLength(callableResultSlotWidths) == MAX_CALLABLES) {} else {
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
    borrow mut words callableResultSlotWidths,
    borrow mut words parameterTypeStarts,
    borrow mut words parameterTypeLengths,
    borrow mut words parameterModes
  ) {
    requireMetadata(0 < plan.moduleCount);
    requireMetadata(plan.moduleCount < MAX_LOCAL_MODULES + 1);
    requireMetadata(plan.importCount < MAX_IMPORTS + 1);
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
        callableResultSlotWidths,
        parameterTypeStarts,
        parameterTypeLengths,
        parameterModes
      )
    );

    region slotArena = new region(
      /* bytes= */ ACTIVE_SOURCE_SLOT_ARENA_BYTES,
      /* allocations= */ ACTIVE_SOURCE_SLOT_BUFFERS
    );
    bytes storage = allocateBytes(slotArena, ACTIVE_SOURCE_SLOT_BYTES);
    words owners = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words generations = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words activeLengths = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    words live = allocate(slotArena, ACTIVE_SOURCE_SLOT_COUNT);
    assert(initializeActiveSourceSlots(storage, owners, generations, activeLengths, live));
    region callableArena = new region(
      /* bytes= */ CALLABLE_ARENA_BYTES,
      /* allocations= */ CALLABLE_ARENA_BUFFERS
    );
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
    words scratchResultSlotWidths = allocate(callableArena, MAX_CALLABLES);
    words scratchParameterTypeStarts = allocate(callableArena, MAX_CLOSURE_PARAMETERS);
    words scratchParameterTypeLengths = allocate(callableArena, MAX_CLOSURE_PARAMETERS);
    words scratchParameterModes = allocate(callableArena, MAX_CLOSURE_PARAMETERS);
    words parameterTotal = allocate(callableArena, PARAMETER_TOTAL_WORDS);
    words processed = allocate(callableArena, MAX_LOCAL_MODULES);
    words moduleRangeScratch = allocate(callableArena, MODULE_RANGE_WORDS);
    long callableCount = 0;
    long finalGeneration = 0;
    long position = 0;
    while (position < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long module = leafFirstOrder[position];
      requireMetadata(-1 < module);
      requireMetadata(module < plan.moduleCount);
      requireMetadata(processed[module] == 0);
      long firstImport = firstImports[module];
      long importCount = directImportCounts[module];
      requireMetadata(-1 < firstImport);
      requireMetadata(-1 < importCount);
      requireMetadata(importCount < MAX_DIRECT_IMPORTS + 1);
      long importedCount = 0;
      long rank = 0;
      while (rank < importCount) limit MAX_DIRECT_IMPORTS {
        long edge = firstImport + rank;
        requireMetadata(edge < plan.importCount);
        long dependency = edgeTargets[edge];
        long visible = 0;
        if (-1 < dependency) {
          requireMetadata(dependency < plan.moduleCount);
          requireMetadata(processed[dependency] == 1);
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
          requireMetadata(failedOwner < 0);
        }
      }

      requireMetadata(-1 < selected.slot);
      requireMetadata(
        publishActiveSource(
          selected,
          archive,
          sourceStarts[module],
          sourceLengths[module],
          storage,
          owners,
          generations,
          activeLengths,
          live
        )
      );
      region sourceArena = new region(/* bytes= */ MAX_SOURCE_BYTES, /* allocations= */ 1);
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
        )
      );
      utf8 activeSource = freezeUtf8(activeBytes);
      region tokenArena = new region(
        /* bytes= */ TOKEN_ARENA_BYTES,
        /* allocations= */ TOKEN_COLUMNS
      );
      words tokenKinds = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words tokenStarts = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words tokenLengths = allocate(tokenArena, MAX_COMPILER_TOKENS);
      set(scratchFirstCallables, module, callableCount);
      long localCallables = stageSourceCallableProducts(
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
        scratchResultSlotWidths,
        scratchParameterTypeStarts,
        scratchParameterTypeLengths,
        scratchParameterModes,
        parameterTotal
      );
      requireMetadata(-1 < localCallables);
      callableCount += localCallables;
      requireMetadata(callableCount < MAX_CALLABLES + 1);
      set(scratchCallableCounts, module, localCallables);
      set(scratchImportedCounts, module, importedCount);
      set(processed, module, 1);
      finalGeneration = selected.generation;
      requireMetadata(
        releaseActiveSource(selected, storage, owners, generations, activeLengths, live)
      );
      drop(tokenLengths);
      drop(tokenStarts);
      drop(tokenKinds);
      drop(tokenArena);
      drop(activeSource);
      drop(sourceArena);
      position += 1;
    }

    CountedModuleCallablePlan result = new CountedModuleCallablePlan(
      plan.moduleCount,
      callableCount,
      parameterTotal[0],
      /* peakActiveSources= */ 1,
      finalGeneration
    );
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
      set(callableResultSlotWidths, callable, scratchResultSlotWidths[callable]);
      callable += 1;
    }

    long parameter = 0;
    while (parameter < parameterTotal[0]) limit MAX_CLOSURE_PARAMETERS {
      set(parameterTypeStarts, parameter, scratchParameterTypeStarts[parameter]);
      set(parameterTypeLengths, parameter, scratchParameterTypeLengths[parameter]);
      set(parameterModes, parameter, scratchParameterModes[parameter]);
      parameter += 1;
    }

    drop(moduleRangeScratch);
    drop(processed);
    drop(parameterTotal);
    drop(scratchParameterModes);
    drop(scratchParameterTypeLengths);
    drop(scratchParameterTypeStarts);
    drop(scratchResultSlotWidths);
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

  /// Copies validated callable names into a source-independent counted product.
  public long copyCallableNameProducts(
    borrow byteview archive,
    long callableCount,
    borrow mut words sourceNameStarts,
    borrow mut words nameLengths,
    borrow mut words productNameStarts,
    borrow mut bytes productNames
  ) {
    assert(-1 < callableCount);
    assert(callableCount < MAX_CALLABLES + 1);
    assert(bufferLength(sourceNameStarts) == MAX_CALLABLES);
    assert(bufferLength(nameLengths) == MAX_CALLABLES);
    assert(bufferLength(productNameStarts) == MAX_CALLABLES);
    assert(bufferLength(productNames) == MAX_CALLABLE_NAME_BYTES);
    long total = 0;
    long callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      long sourceStart = sourceNameStarts[callable];
      long length = nameLengths[callable];
      assert(-1 < sourceStart);
      assert(0 < length);
      assert(length < MAX_CALLABLE_NAME_LENGTH + 1);
      assert(length < bufferLength(archive) - sourceStart + 1);
      assert(length < MAX_CALLABLE_NAME_BYTES - total + 1);
      total += length;
      callable += 1;
    }

    long written = 0;
    callable = 0;
    while (callable < callableCount) limit MAX_CALLABLES {
      set(productNameStarts, callable, written);
      long copiedSourceStart = sourceNameStarts[callable];
      long copiedLength = nameLengths[callable];
      long offset = 0;
      while (offset < copiedLength) limit MAX_CALLABLE_NAME_LENGTH {
        setByte(productNames, written + offset, archive[copiedSourceStart + offset]);
        offset += 1;
      }

      written += copiedLength;
      callable += 1;
    }

    assert(written == total);
    return total;
  }
}
