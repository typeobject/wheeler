//! Resolves structured signature types and stable local target identities.

module wheeler.compiler.closure.structured_source_targets;

import wheeler.crypto.sha256;

classical class StructuredSourceTargets {
  /// Returns the sole type at one callable-local signature coordinate.
  public long signatureTypeAt(
    long owner,
    long local,
    long signatureTypeCount,
    borrow mut words signatureTypes
  ) {
    long selected = -1;
    long matches = 0;
    long type = 0;
    while (type < signatureTypeCount) limit 4096 {
      if (signatureTypes[type] == owner) {
        if (signatureTypes[4096 + type] == local) {
          selected = signatureTypes[8192 + type];
          matches += 1;
        }
      }

      type += 1;
    }

    if (matches != 1) {
      return -1;
    }

    return selected;
  }

  /// Publishes resolved call coordinates, owners, and stable target identities.
  public void publishStructuredCallRelocations(
    long callCount,
    borrow mut words statements,
    borrow mut words callStatements,
    borrow mut words callRelocations,
    borrow byteview callRelocationIdentities,
    borrow mut words publishedRelocations,
    borrow mut words publishedRelocationOwners,
    borrow mut bytes publishedRelocationIdentities
  ) {
    assert(-1 < callCount);
    assert(callCount < 257);
    long call = 0;
    while (call < callCount) limit 256 {
      set(publishedRelocations, call, callRelocations[call]);
      set(publishedRelocationOwners, call, statements[callStatements[call]]);
      set(publishedRelocations, 256 + call, callRelocations[256 + call]);
      set(publishedRelocations, 512 + call, callRelocations[512 + call]);
      long identityByte = 0;
      while (identityByte < 32) limit 32 {
        setByte(
          publishedRelocationIdentities,
          call * 32 + identityByte,
          callRelocationIdentities[call * 32 + identityByte]
        );
        identityByte += 1;
      }

      call += 1;
    }
  }

  /// Hashes one canonical local target name into its stable identity row.
  public void writeTargetIdentity(
    borrow byteview names,
    long start,
    long length,
    long target,
    borrow mut bytes identities
  ) {
    region hashArena = new region(/* bytes= */ 1232, /* allocations= */ 4);
    bytes digest = allocateBytes(hashArena, /* length= */ 32);
    hashSha256Range(names, start, length, digest, hashArena);
    long identityByte = 0;
    while (identityByte < 32) limit 32 {
      setByte(identities, target * 32 + identityByte, digest[identityByte]);
      identityByte += 1;
    }

    drop(digest);
    drop(hashArena);
  }
}
