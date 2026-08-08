//! Publishes package-bound identities for validated counted symbol products.

module wheeler.compiler.closure.symbol_identities;

import wheeler.compiler.closure.manifest_syntax;
import wheeler.compiler.closure.plan;
import wheeler.crypto.sha256;

classical class CountedSymbolIdentities {
  private const long MAX_CLOSURE_SYMBOLS = 16384;
  private const long MODULE_SYMBOL_CONSTANT = 1;
  private const long SYMBOL_IDENTITY_BYTES = 32;
  private const long SYMBOL_IDENTITY_INPUT_BYTES = 350;
  private const long SYMBOL_IDENTITY_STORAGE_BYTES = 524288;

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
}
