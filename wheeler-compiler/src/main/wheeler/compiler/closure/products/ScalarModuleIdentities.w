//! Binds resolved counted scalar products into stable module identities.

module wheeler.compiler.closure.scalar_module_identities;

import wheeler.compiler.closure.plan;
import wheeler.crypto.sha256;

classical class ScalarModuleIdentities {
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CLASS_CONSTANTS = 256;
  private const long MAX_DIRECT_IMPORTS = 64;
  private const long MAX_IDENTITY_INPUT_BYTES = 14000;
  private const long MAX_LOCAL_MODULES = 512;
  private const long MODULE_IDENTITY_STORAGE_BYTES = 16384;

  /// Reports whether every dependency had a local completed scalar product.
  public record ScalarModuleIdentityPlan(boolean valid, long moduleCount) {}

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

  private long writeCount(long value, borrow mut bytes input, long cursor) {
    assert(-1 < value);
    assert(value < 65536);
    setByte(input, cursor, value % 256);
    setByte(input, cursor + 1, value / 256);
    return cursor + 2;
  }

  private long writeSigned(long value, borrow mut bytes input, long cursor) {
    long remaining = value;
    long index = 0;
    while (index < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(input, cursor + index, octet);
      remaining = (remaining - octet) / 256;
      index += 1;
    }

    return cursor + 8;
  }

  private long writeSourceIdentity(
    borrow byteview manifest,
    long start,
    borrow mut bytes input,
    long cursor
  ) {
    long index = 0;
    while (index < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long high = hexNibble(manifest[start + index * 2]);
      long low = hexNibble(manifest[start + index * 2 + 1]);
      if (-1 < high) {} else {
        return -1;
      }

      if (-1 < low) {} else {
        return -1;
      }

      setByte(input, cursor + index, high * 16 + low);
      index += 1;
    }

    return cursor + IDENTITY_BYTES;
  }

  private long writeModuleInput(
    borrow byteview archive,
    borrow byteview manifest,
    long module,
    borrow mut words moduleIdentityStarts,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words edgeTargets,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut bytes packageIdentity,
    borrow mut bytes symbolIdentities,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut words processed,
    borrow mut bytes scratchModuleIdentities,
    borrow mut bytes input
  ) {
    writeAscii(input, 0, "wheeler-scalar-module-product-1");
    long cursor = 31;
    long copied = 0;
    while (copied < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(input, cursor + copied, packageIdentity[copied]);
      copied += 1;
    }

    cursor += IDENTITY_BYTES;
    cursor = writeSourceIdentity(manifest, moduleIdentityStarts[module], input, cursor);
    if (-1 < cursor) {} else {
      return -1;
    }

    long nameLength = moduleNameLengths[module];
    if (0 < nameLength) {} else {
      return -1;
    }

    if (nameLength < 257) {} else {
      return -1;
    }

    cursor = writeCount(nameLength, input, cursor);
    copied = 0;
    while (copied < nameLength) limit 256 {
      setByte(input, cursor + copied, archive[moduleNameStarts[module] + copied]);
      copied += 1;
    }

    cursor += nameLength;
    long importCount = directImportCounts[module];
    if (importCount < MAX_DIRECT_IMPORTS + 1) {} else {
      return -1;
    }

    cursor = writeCount(importCount, input, cursor);
    long rank = 0;
    while (rank < importCount) limit MAX_DIRECT_IMPORTS {
      long dependency = edgeTargets[firstImports[module] + rank];
      if (-1 < dependency) {} else {
        return -1;
      }

      if (dependency < MAX_LOCAL_MODULES) {} else {
        return -1;
      }

      if (processed[dependency] == 1) {} else {
        return -1;
      }

      copied = 0;
      while (copied < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(
          input,
          cursor + copied,
          scratchModuleIdentities[dependency * IDENTITY_BYTES + copied]
        );
        copied += 1;
      }

      cursor += IDENTITY_BYTES;
      rank += 1;
    }

    long symbolCount = moduleSymbolCounts[module];
    if (symbolCount < MAX_CLASS_CONSTANTS + 1) {} else {
      return -1;
    }

    cursor = writeCount(symbolCount, input, cursor);
    long firstSymbol = moduleFirstSymbols[module];
    long offset = 0;
    while (offset < symbolCount) limit MAX_CLASS_CONSTANTS {
      long symbol = firstSymbol + offset;
      if (symbolResolved[symbol] == 1) {} else {
        return -1;
      }

      copied = 0;
      while (copied < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(input, cursor + copied, symbolIdentities[symbol * IDENTITY_BYTES + copied]);
        copied += 1;
      }

      cursor += IDENTITY_BYTES;
      setByte(input, cursor, 1);
      cursor += 1;
      cursor = writeSigned(symbolValues[symbol], input, cursor);
      offset += 1;
    }

    if (cursor < MAX_IDENTITY_INPUT_BYTES + 1) {} else {
      return -1;
    }

    return cursor;
  }

  /// Publishes one identity per resolved local module after the complete leaf-first pass.
  public ScalarModuleIdentityPlan publishScalarModuleIdentities(
    borrow byteview archive,
    borrow byteview manifest,
    CountedClosurePlan plan,
    borrow mut words leafFirstOrder,
    borrow mut words moduleIdentityStarts,
    borrow mut words moduleNameStarts,
    borrow mut words moduleNameLengths,
    borrow mut words firstImports,
    borrow mut words directImportCounts,
    borrow mut words edgeTargets,
    borrow mut words moduleFirstSymbols,
    borrow mut words moduleSymbolCounts,
    borrow mut bytes packageIdentity,
    borrow mut bytes symbolIdentities,
    borrow mut words symbolValues,
    borrow mut words symbolResolved,
    borrow mut bytes moduleIdentities
  ) {
    if (0 < plan.moduleCount) {} else {
      return new ScalarModuleIdentityPlan(false, 0);
    }

    if (plan.moduleCount < MAX_LOCAL_MODULES + 1) {} else {
      return new ScalarModuleIdentityPlan(false, 0);
    }

    if (bufferLength(packageIdentity) == IDENTITY_BYTES) {} else {
      return new ScalarModuleIdentityPlan(false, 0);
    }

    if (bufferLength(moduleIdentities) == MODULE_IDENTITY_STORAGE_BYTES) {} else {
      return new ScalarModuleIdentityPlan(false, 0);
    }

    region identityArena = new region(/* bytes= */ 34600, /* allocations= */ 4);
    words processed = allocate(identityArena, MAX_LOCAL_MODULES);
    bytes scratchModuleIdentities = allocateBytes(identityArena, MODULE_IDENTITY_STORAGE_BYTES);
    bytes input = allocateBytes(identityArena, MAX_IDENTITY_INPUT_BYTES);
    bytes digest = allocateBytes(identityArena, IDENTITY_BYTES);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    long position = 0;
    boolean valid = true;
    while (position < plan.moduleCount) limit MAX_LOCAL_MODULES {
      long module = leafFirstOrder[position];
      if (-1 < module) {} else {
        valid = false;
        break;
      }

      if (module < plan.moduleCount) {} else {
        valid = false;
        break;
      }

      if (processed[module] == 0) {} else {
        valid = false;
        break;
      }

      long inputLength = writeModuleInput(
        archive,
        manifest,
        module,
        moduleIdentityStarts,
        moduleNameStarts,
        moduleNameLengths,
        firstImports,
        directImportCounts,
        edgeTargets,
        moduleFirstSymbols,
        moduleSymbolCounts,
        packageIdentity,
        symbolIdentities,
        symbolValues,
        symbolResolved,
        processed,
        scratchModuleIdentities,
        input
      );
      if (-1 < inputLength) {
        hashSha256Range(input, 0, inputLength, digest, hashArena);
        long digestByte = 0;
        while (digestByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
          setByte(
            scratchModuleIdentities,
            module * IDENTITY_BYTES + digestByte,
            digest[digestByte]
          );
          digestByte += 1;
        }
      } else {
        valid = false;
        break;
      }

      set(processed, module, 1);
      position += 1;
    }

    if (valid) {
      long published = 0;
      while (published < plan.moduleCount * IDENTITY_BYTES) limit MODULE_IDENTITY_STORAGE_BYTES {
        setByte(moduleIdentities, published, scratchModuleIdentities[published]);
        published += 1;
      }
    }

    drop(hashArena);
    drop(digest);
    drop(input);
    drop(scratchModuleIdentities);
    drop(processed);
    drop(identityArena);
    if (valid) {
      return new ScalarModuleIdentityPlan(true, plan.moduleCount);
    }

    return new ScalarModuleIdentityPlan(false, 0);
  }
}
