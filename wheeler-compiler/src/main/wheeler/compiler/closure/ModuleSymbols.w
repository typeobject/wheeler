//! Materializes counted scalar-symbol products from staged closure sources.

module wheeler.compiler.closure.module_symbols;

import wheeler.compiler.closure.active_source_slots;
import wheeler.compiler.closure.manifest_syntax;
import wheeler.compiler.closure.plan;
import wheeler.compiler.compiler_token_limits;
import wheeler.compiler.constant_declarations;
import wheeler.compiler.keyword_tokens;
import wheeler.compiler.module_headers;
import wheeler.compiler.module_linker;
import wheeler.compiler.source_scalars;
import wheeler.compiler.tokens;
import wheeler.crypto.sha256;

classical class CountedModuleSymbols {
  private const long MAX_CLOSURE_SYMBOLS = 16384;
  private const long MAX_IMPORTS = 3072;
  private const long MAX_LOCAL_MODULES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long SYMBOL_ARENA_BYTES = 840000;
  private const long SYMBOL_IDENTITY_BYTES = 32;
  private const long SYMBOL_IDENTITY_INPUT_BYTES = 350;
  private const long SYMBOL_IDENTITY_STORAGE_BYTES = 524288;
  private const long TOKEN_ARENA_BYTES = 98320;

  /// Names one scalar constant symbol.
  public const long MODULE_SYMBOL_CONSTANT = 1;
  /// Names one signed scalar symbol type.
  public const long MODULE_SYMBOL_SIGNED = 1;
  /// Names one Boolean scalar symbol type.
  public const long MODULE_SYMBOL_BOOLEAN = 2;

  /// Summarizes one complete source-to-symbol pass.
  public record CountedModuleSymbolPlan(
    long moduleCount,
    long symbolCount,
    long peakActiveSources,
    long finalGeneration
  ) {}

  private boolean columnsValid(
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words moduleImportedSymbolCounts,
    borrow mut words edgeSymbolCounts,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolKinds,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes
  ) {
    if (bufferLength(moduleFirstSymbols) == MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (bufferLength(moduleSymbolCounts) == MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (bufferLength(moduleImportedSymbolCounts) == MAX_LOCAL_MODULES) {} else {
      return false;
    }

    if (bufferLength(edgeSymbolCounts) == MAX_IMPORTS) {} else {
      return false;
    }

    if (bufferLength(symbolOwners) == MAX_CLOSURE_SYMBOLS) {} else {
      return false;
    }

    if (bufferLength(symbolStarts) == MAX_CLOSURE_SYMBOLS) {} else {
      return false;
    }

    if (bufferLength(symbolLengths) == MAX_CLOSURE_SYMBOLS) {} else {
      return false;
    }

    if (bufferLength(symbolKinds) == MAX_CLOSURE_SYMBOLS) {} else {
      return false;
    }

    if (bufferLength(symbolVisibilities) == MAX_CLOSURE_SYMBOLS) {} else {
      return false;
    }

    return bufferLength(symbolTypes) == MAX_CLOSURE_SYMBOLS;
  }

  private long stateEnd(
    borrow utf8 source,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    long cursor,
    long count
  ) {
    if (cursor < count) {} else {
      return -1;
    }

    if (tokenHash(source, tokenStarts, tokenLengths, cursor) == TOKEN_STATE) {} else {
      return cursor;
    }

    while (cursor < count) limit MAX_COMPILER_TOKENS {
      if (tokenLengths[cursor] == 1) {
        if (utf8Scalar(source, tokenStarts[cursor]) == PUNCTUATION_SEMICOLON) {
          return cursor + 1;
        }
      }

      cursor += 1;
    }

    return -1;
  }

  private boolean sameName(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength == rightLength) {} else {
      return false;
    }

    long cursor = 0;
    while (cursor < leftLength) limit 256 {
      if (
        utf8Scalar(source, leftStart + cursor) == utf8Scalar(source, rightStart + cursor)
      ) {} else {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  private long publicSymbolCount(
    long module,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words symbolVisibilities
  ) {
    long first = moduleFirstSymbols[module];
    long count = moduleSymbolCounts[module];
    long publicCount = 0;
    long offset = 0;
    while (offset < count) limit MAX_CLASS_CONSTANTS {
      if (symbolVisibilities[first + offset] == 1) {
        publicCount += 1;
      }

      offset += 1;
    }

    return publicCount;
  }

  private long indexModuleConstants(
    borrow utf8 source,
    long archiveStart,
    long module,
    long firstSymbol,
    borrow mut words tokenKinds,
    borrow mut words tokenStarts,
    borrow mut words tokenLengths,
    borrow mut words moduleRange,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolKinds,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes
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

    if (
      classPrefixValid(source, tokenKinds, tokenStarts, tokenLengths, body, tokenCount)
    ) {} else {
      return -1;
    }

    long declaration = stateEnd(source, tokenStarts, tokenLengths, body + 4, tokenCount);
    if (-1 < declaration) {} else {
      return -1;
    }

    long symbolCount = 0;
    boolean indexing = true;
    while (indexing) limit MAX_CLASS_CONSTANTS + 1 {
      if (declaration < tokenCount) {} else {
        break;
      }

      long constant = constantToken(source, tokenStarts, tokenLengths, declaration);
      if (-1 < constant) {
        if (symbolCount < MAX_CLASS_CONSTANTS) {} else {
          return -1;
        }

        long declarationEnd = constantDeclarationEnd(
          source,
          tokenStarts,
          tokenLengths,
          declaration,
          tokenCount
        );
        if (declaration < declarationEnd) {} else {
          return -1;
        }

        long visibilityHash = tokenHash(source, tokenStarts, tokenLengths, declaration);
        long visibility = -1;
        if (visibilityHash == TOKEN_PUBLIC) {
          visibility = 1;
        } else {
          if (visibilityHash == TOKEN_PRIVATE) {
            visibility = 0;
          }
        }

        if (-1 < visibility) {} else {
          return -1;
        }

        long name = constantNameToken(source, tokenStarts, tokenLengths, declaration);
        if (tokenKinds[name] == 1) {} else {
          return -1;
        }

        long prior = 0;
        while (prior < symbolCount) limit MAX_CLASS_CONSTANTS {
          long priorSymbol = firstSymbol + prior;
          if (
            sameName(
              source,
              symbolStarts[priorSymbol] - archiveStart,
              symbolLengths[priorSymbol],
              tokenStarts[name],
              tokenLengths[name]
            )
          ) {
            return -1;
          }

          prior += 1;
        }

        long symbol = firstSymbol + symbolCount;
        if (symbol < MAX_CLOSURE_SYMBOLS) {} else {
          return -1;
        }

        set(symbolOwners, symbol, module);
        set(symbolStarts, symbol, archiveStart + tokenStarts[name]);
        set(symbolLengths, symbol, tokenLengths[name]);
        set(symbolKinds, symbol, MODULE_SYMBOL_CONSTANT);
        set(symbolVisibilities, symbol, visibility);
        long symbolType = MODULE_SYMBOL_BOOLEAN;
        if (constantTypeSigned(source, tokenStarts, tokenLengths, declaration)) {
          symbolType = MODULE_SYMBOL_SIGNED;
        }

        set(symbolTypes, symbol, symbolType);
        symbolCount += 1;
        declaration = declarationEnd;
      } else {
        indexing = false;
      }
    }

    return symbolCount;
  }

  private long hexNibble(long scalar) {
    if (47 < scalar) {
      if (scalar < 58) {
        return scalar - 48;
      }
    }

    if (96 < scalar) {
      if (scalar < 103) {
        return scalar - 87;
      }
    }

    return -1;
  }

  private void writeIdentityInput(
    borrow byteview archive,
    borrow byteview manifest,
    borrow mut bytes packageIdentity,
    long moduleIdentityStart,
    long symbol,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolKinds,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes,
    borrow mut bytes input
  ) {
    writeAscii(input, 0, "wheeler-module-symbol-1");
    long cursor = 0;
    while (cursor < SYMBOL_IDENTITY_BYTES) limit SYMBOL_IDENTITY_BYTES {
      setByte(input, 23 + cursor, packageIdentity[cursor]);
      long high = hexNibble(manifest[moduleIdentityStart + cursor * 2]);
      long low = hexNibble(manifest[moduleIdentityStart + cursor * 2 + 1]);
      assert(-1 < high);
      assert(-1 < low);
      setByte(input, 55 + cursor, high * 16 + low);
      cursor += 1;
    }

    setByte(input, 87, symbolKinds[symbol]);
    setByte(input, 88, symbolVisibilities[symbol]);
    setByte(input, 89, symbolTypes[symbol]);
    long nameLength = symbolLengths[symbol];
    assert(0 < nameLength);
    assert(nameLength < 257);
    setByte(input, 90, nameLength % 256);
    setByte(input, 91, nameLength / 256 % 256);
    setByte(input, 92, 0);
    setByte(input, 93, 0);
    cursor = 0;
    while (cursor < nameLength) limit 256 {
      setByte(input, 94 + cursor, archive[symbolStarts[symbol] + cursor]);
      cursor += 1;
    }
  }

  /// Publishes package-bound symbol identities after every product range validates.
  public void publishCountedSymbolIdentities(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    long symbolCount,
    borrow mut words moduleIdentityStarts,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolKinds,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes,
    borrow mut bytes packageIdentity,
    borrow mut bytes symbolIdentities
  ) {
    requireMetadata(0 < symbolCount, manifest);
    requireMetadata(symbolCount < MAX_CLOSURE_SYMBOLS + 1, manifest);
    requireMetadata(bufferLength(packageIdentity) == SYMBOL_IDENTITY_BYTES, manifest);
    requireMetadata(bufferLength(symbolIdentities) == SYMBOL_IDENTITY_STORAGE_BYTES, manifest);
    region identityArena = new region(/* bytes= */ 540000, /* allocations= */ 4);
    bytes scratchPackageIdentity = allocateBytes(identityArena, SYMBOL_IDENTITY_BYTES);
    bytes scratchIdentities = allocateBytes(identityArena, SYMBOL_IDENTITY_STORAGE_BYTES);
    bytes identityInput = allocateBytes(identityArena, SYMBOL_IDENTITY_INPUT_BYTES);
    bytes digest = allocateBytes(identityArena, SYMBOL_IDENTITY_BYTES);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256(archive, scratchPackageIdentity, hashArena);
    long symbol = 0;
    while (symbol < symbolCount) limit MAX_CLOSURE_SYMBOLS {
      long owner = symbolOwners[symbol];
      requireMetadata(-1 < owner, manifest);
      requireMetadata(owner < plan.moduleCount, manifest);
      long nameStart = symbolStarts[symbol];
      long nameLength = symbolLengths[symbol];
      requireMetadata(-1 < nameStart, manifest);
      requireMetadata(0 < nameLength, manifest);
      requireMetadata(nameLength < 257, manifest);
      requireMetadata(nameStart < bufferLength(archive), manifest);
      requireMetadata(nameLength < bufferLength(archive) - nameStart + 1, manifest);
      requireMetadata(symbolKinds[symbol] == MODULE_SYMBOL_CONSTANT, manifest);
      requireMetadata(-1 < symbolVisibilities[symbol], manifest);
      requireMetadata(symbolVisibilities[symbol] < 2, manifest);
      requireMetadata(0 < symbolTypes[symbol], manifest);
      requireMetadata(symbolTypes[symbol] < 3, manifest);
      writeIdentityInput(
        archive,
        manifest,
        scratchPackageIdentity,
        moduleIdentityStarts[owner],
        symbol,
        symbolStarts,
        symbolLengths,
        symbolKinds,
        symbolVisibilities,
        symbolTypes,
        identityInput
      );
      hashSha256Range(identityInput, 0, 94 + nameLength, digest, hashArena);
      long digestByte = 0;
      while (digestByte < SYMBOL_IDENTITY_BYTES) limit SYMBOL_IDENTITY_BYTES {
        setByte(
          scratchIdentities,
          symbol * SYMBOL_IDENTITY_BYTES + digestByte,
          digest[digestByte]
        );
        digestByte += 1;
      }

      symbol += 1;
    }

    long packageByte = 0;
    while (packageByte < SYMBOL_IDENTITY_BYTES) limit SYMBOL_IDENTITY_BYTES {
      setByte(packageIdentity, packageByte, scratchPackageIdentity[packageByte]);
      packageByte += 1;
    }

    long publishedByte = 0;
    while (publishedByte < symbolCount
      * SYMBOL_IDENTITY_BYTES) limit SYMBOL_IDENTITY_STORAGE_BYTES {
      setByte(symbolIdentities, publishedByte, scratchIdentities[publishedByte]);
      publishedByte += 1;
    }

    drop(hashArena);
    drop(digest);
    drop(identityInput);
    drop(scratchIdentities);
    drop(scratchPackageIdentity);
    drop(identityArena);
  }

  /// Stages every source once and publishes compact scalar products after the complete pass.
  ///
  /// One edge receives its dependency's public-symbol count only after that dependency has
  /// completed. Symbol names remain immutable ranges in the validated archive.
  public CountedModuleSymbolPlan indexCountedModuleSymbols(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    borrow mut words edgeTargets,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words importRanks,
    borrow mut words leafFirstOrder,
    borrow mut words sourceStarts,
    borrow mut words sourceLengths,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut words moduleImportedSymbolCounts,
    borrow mut words edgeSymbolCounts,
    borrow mut words symbolOwners,
    borrow mut words symbolStarts,
    borrow mut words symbolLengths,
    borrow mut words symbolKinds,
    borrow mut words symbolVisibilities,
    borrow mut words symbolTypes
  ) {
    requireMetadata(0 < plan.moduleCount, manifest);
    requireMetadata(plan.moduleCount < MAX_LOCAL_MODULES + 1, manifest);
    requireMetadata(plan.importCount < MAX_IMPORTS + 1, manifest);
    requireMetadata(
      columnsValid(
        moduleFirstSymbols,
        moduleSymbolCounts,
        moduleImportedSymbolCounts,
        edgeSymbolCounts,
        symbolOwners,
        symbolStarts,
        symbolLengths,
        symbolKinds,
        symbolVisibilities,
        symbolTypes
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
    region symbolArena = new region(/* bytes= */ SYMBOL_ARENA_BYTES, /* allocations= */ 11);
    words scratchFirstSymbols = allocate(symbolArena, MAX_LOCAL_MODULES);
    words scratchSymbolCounts = allocate(symbolArena, MAX_LOCAL_MODULES);
    words scratchImportedCounts = allocate(symbolArena, MAX_LOCAL_MODULES);
    words scratchEdgeCounts = allocate(symbolArena, MAX_IMPORTS);
    words scratchOwners = allocate(symbolArena, MAX_CLOSURE_SYMBOLS);
    words scratchStarts = allocate(symbolArena, MAX_CLOSURE_SYMBOLS);
    words scratchLengths = allocate(symbolArena, MAX_CLOSURE_SYMBOLS);
    words scratchKinds = allocate(symbolArena, MAX_CLOSURE_SYMBOLS);
    words scratchVisibilities = allocate(symbolArena, MAX_CLOSURE_SYMBOLS);
    words scratchTypes = allocate(symbolArena, MAX_CLOSURE_SYMBOLS);
    words processed = allocate(symbolArena, MAX_LOCAL_MODULES);

    long symbolCount = 0;
    long finalGeneration = 0;
    long position = 0;
    while (position < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long module = leafFirstOrder[position];
      requireMetadata(-1 < module, manifest);
      requireMetadata(module < plan.moduleCount, manifest);
      requireMetadata(processed[module] == 0, manifest);
      long importedCount = 0;
      long rank = 0;
      while (rank < directImportCounts[module]) limit 64 {
        long edge = firstImports[module] + rank;
        requireMetadata(edge < plan.importCount, manifest);
        requireMetadata(importRanks[edge] == rank, manifest);
        long dependency = edgeTargets[edge];
        long edgeCount = 0;
        if (-1 < dependency) {
          requireMetadata(dependency < plan.moduleCount, manifest);
          requireMetadata(processed[dependency] == 1, manifest);
          edgeCount = publicSymbolCount(
            dependency,
            scratchFirstSymbols,
            scratchSymbolCounts,
            scratchVisibilities
          );
        }

        set(scratchEdgeCounts, edge, edgeCount);
        importedCount += edgeCount;
        rank += 1;
      }

      long sourceStart = sourceStarts[module];
      long sourceLength = sourceLengths[module];
      requireMetadata(0 < sourceLength, manifest);
      requireMetadata(sourceLength < MAX_SOURCE_BYTES + 1, manifest);
      requireMetadata(-1 < sourceStart, manifest);
      requireMetadata(sourceLength < bufferLength(archive) - sourceStart + 1, manifest);
      region sourceArena = new region(/* bytes= */ 65536, /* allocations= */ 2);
      bytes archiveBytes = allocateBytes(sourceArena, sourceLength);
      long cursor = 0;
      while (cursor < sourceLength) limit MAX_SOURCE_BYTES {
        setByte(archiveBytes, cursor, archive[sourceStart + cursor]);
        cursor += 1;
      }

      utf8 archiveSource = freezeUtf8(archiveBytes);
      ActiveSourceHandle selected = new ActiveSourceHandle(0, 0, 0);
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
        case ActiveSourceAcquireResult.Full(long owner) {
          requireMetadata(owner < 0, manifest);
        }
      }

      requireMetadata(
        publishActiveSource(
          selected,
          archiveSource,
          storage,
          owners,
          generations,
          activeLengths,
          live
        ),
        manifest
      );
      bytes activeBytes = allocateBytes(sourceArena, sourceLength);
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
      region tokenArena = new region(/* bytes= */ TOKEN_ARENA_BYTES, /* allocations= */ 4);
      words tokenKinds = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words tokenStarts = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words tokenLengths = allocate(tokenArena, MAX_COMPILER_TOKENS);
      words moduleRange = allocate(tokenArena, 2);
      set(scratchFirstSymbols, module, symbolCount);
      long localSymbols = indexModuleConstants(
        activeSource,
        sourceStart,
        module,
        symbolCount,
        tokenKinds,
        tokenStarts,
        tokenLengths,
        moduleRange,
        scratchOwners,
        scratchStarts,
        scratchLengths,
        scratchKinds,
        scratchVisibilities,
        scratchTypes
      );
      requireMetadata(-1 < localSymbols, manifest);
      symbolCount += localSymbols;
      requireMetadata(symbolCount < MAX_CLOSURE_SYMBOLS + 1, manifest);
      set(scratchSymbolCounts, module, localSymbols);
      set(scratchImportedCounts, module, importedCount);
      set(processed, module, 1);
      finalGeneration = selected.generation;
      requireMetadata(
        releaseActiveSource(selected, storage, owners, generations, activeLengths, live),
        manifest
      );
      drop(moduleRange);
      drop(tokenLengths);
      drop(tokenStarts);
      drop(tokenKinds);
      drop(tokenArena);
      drop(activeSource);
      drop(archiveSource);
      drop(sourceArena);
      position += 1;
    }

    long publishedModule = 0;
    while (publishedModule < plan.moduleCount) limit MAX_LOCAL_MODULES {
      set(moduleFirstSymbols, publishedModule, scratchFirstSymbols[publishedModule]);
      set(moduleSymbolCounts, publishedModule, scratchSymbolCounts[publishedModule]);
      set(moduleImportedSymbolCounts, publishedModule, scratchImportedCounts[publishedModule]);
      publishedModule += 1;
    }

    long publishedEdge = 0;
    while (publishedEdge < plan.importCount) limit MAX_IMPORTS {
      set(edgeSymbolCounts, publishedEdge, scratchEdgeCounts[publishedEdge]);
      publishedEdge += 1;
    }

    long symbol = 0;
    while (symbol < symbolCount) limit MAX_CLOSURE_SYMBOLS {
      set(symbolOwners, symbol, scratchOwners[symbol]);
      set(symbolStarts, symbol, scratchStarts[symbol]);
      set(symbolLengths, symbol, scratchLengths[symbol]);
      set(symbolKinds, symbol, scratchKinds[symbol]);
      set(symbolVisibilities, symbol, scratchVisibilities[symbol]);
      set(symbolTypes, symbol, scratchTypes[symbol]);
      symbol += 1;
    }

    CountedModuleSymbolPlan result = new CountedModuleSymbolPlan(
      plan.moduleCount,
      symbolCount,
      /* peakActiveSources= */ 1,
      finalGeneration
    );
    drop(processed);
    drop(scratchTypes);
    drop(scratchVisibilities);
    drop(scratchKinds);
    drop(scratchLengths);
    drop(scratchStarts);
    drop(scratchOwners);
    drop(scratchEdgeCounts);
    drop(scratchImportedCounts);
    drop(scratchSymbolCounts);
    drop(scratchFirstSymbols);
    drop(symbolArena);
    drop(live);
    drop(activeLengths);
    drop(generations);
    drop(owners);
    drop(storage);
    drop(slotArena);
    return result;
  }
}
