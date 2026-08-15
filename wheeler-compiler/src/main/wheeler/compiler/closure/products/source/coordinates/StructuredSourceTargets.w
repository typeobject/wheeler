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
