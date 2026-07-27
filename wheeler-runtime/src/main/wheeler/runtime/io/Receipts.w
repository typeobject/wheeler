//! Builds canonical monotonic durability receipt identities from verified evidence digests.

module wheeler.runtime.io.receipts;

import wheeler.crypto.sha256;

classical class DurabilityReceipts {
  /// Names write completion without a persistence claim.
  public const long RECEIPT_WRITE_COMPLETED = 1;
  /// Names stable protected data.
  public const long RECEIPT_DATA_STABLE = 2;
  /// Names stable file data and required metadata.
  public const long RECEIPT_FILE_STABLE = 3;
  /// Names a visible namespace generation.
  public const long RECEIPT_NAMESPACE_VISIBLE = 4;
  /// Names a crash-stable namespace generation.
  public const long RECEIPT_NAMESPACE_STABLE = 5;
  /// Names stable evidence from a declared replica quorum.
  public const long RECEIPT_QUORUM_STABLE = 6;

  /// Names provider operation-completion evidence.
  public const long EVIDENCE_OPERATION_COMPLETION = 1;
  /// Names data-flush evidence.
  public const long EVIDENCE_DATA_FLUSH = 2;
  /// Names metadata-flush evidence.
  public const long EVIDENCE_METADATA_FLUSH = 3;
  /// Names atomic-rename visibility evidence.
  public const long EVIDENCE_ATOMIC_RENAME = 4;
  /// Names namespace-flush evidence.
  public const long EVIDENCE_NAMESPACE_FLUSH = 5;
  /// Names declared quorum-protocol evidence.
  public const long EVIDENCE_QUORUM_PROTOCOL = 6;

  /// Defines immutable native durability receipt states.
  public record Receipt(long kind, long depth, boolean valid) {}

  private boolean digestValid(borrow byteview digest) {
    return bufferLength(digest) == 32;
  }

  private boolean digestsDiffer(borrow byteview left, borrow byteview right) {
    long index = 0;
    while (index < 32) limit 32 {
      if (left[index] == right[index]) {} else {
        return true;
      }

      index += 1;
    }

    return false;
  }

  private void copyDigest(borrow byteview source, borrow mut bytes target, long targetOffset) {
    long index = 0;
    while (index < 32) limit 32 {
      long value = source[index];
      setByte(target, targetOffset + index, value);
      index += 1;
    }
  }

  private void writeDomain(borrow mut bytes canonical) {
    long[32] domain = new long[32](
      90,
      179,
      104,
      16,
      241,
      80,
      56,
      20,
      124,
      23,
      83,
      137,
      235,
      232,
      110,
      147,
      23,
      3,
      145,
      10,
      186,
      205,
      244,
      209,
      106,
      113,
      125,
      141,
      241,
      207,
      158,
      130
    );
    long index = 0;
    while (index < 32) limit 32 {
      long value = domain[index];
      setByte(canonical, index, value);
      index += 1;
    }
  }

  private void receiptIdentity(
    long kind,
    long evidenceSource,
    long depth,
    borrow byteview subjectIdentity,
    borrow byteview profileIdentity,
    borrow byteview evidenceIdentity,
    borrow byteview parentIdentity,
    boolean hasParent,
    borrow mut bytes identity,
    borrow mut region arena
  ) {
    bytes canonical = allocateBytes(arena, 163);
    writeDomain(canonical);
    setByte(canonical, 32, kind);
    setByte(canonical, 33, evidenceSource);
    setByte(canonical, 34, depth);
    copyDigest(subjectIdentity, canonical, 35);
    copyDigest(profileIdentity, canonical, 67);
    copyDigest(evidenceIdentity, canonical, 99);
    if (hasParent) {
      copyDigest(parentIdentity, canonical, 131);
    }

    hashSha256(canonical, identity, arena);
    drop(canonical);
  }

  private boolean commonInputsValid(
    borrow byteview subjectIdentity,
    borrow byteview profileIdentity,
    borrow byteview evidenceIdentity,
    borrow mut bytes identity
  ) {
    if (digestValid(subjectIdentity)) {
      if (digestValid(profileIdentity)) {
        if (digestValid(evidenceIdentity)) {
          return 31 < bufferLength(identity);
        }
      }
    }

    return false;
  }

  /// Issues initial write completion from exact operation evidence.
  public Receipt writeCompleted(
    borrow byteview subjectIdentity,
    borrow byteview profileIdentity,
    borrow byteview evidenceIdentity,
    long evidenceSource,
    borrow mut bytes identity,
    borrow mut region arena
  ) {
    Receipt invalid = new Receipt(0, 0, false);
    if (
      commonInputsValid(subjectIdentity, profileIdentity, evidenceIdentity, identity) == false
    ) {
      return invalid;
    }

    if (evidenceSource == EVIDENCE_OPERATION_COMPLETION) {} else {
      return invalid;
    }

    receiptIdentity(
      RECEIPT_WRITE_COMPLETED,
      evidenceSource,
      1,
      subjectIdentity,
      profileIdentity,
      evidenceIdentity,
      subjectIdentity,
      false,
      identity,
      arena
    );
    return new Receipt(RECEIPT_WRITE_COMPLETED, 1, true);
  }

  /// Promotes exactly one receipt stage using new matching evidence.
  public Receipt promote(
    Receipt prior,
    borrow byteview priorIdentity,
    borrow byteview priorEvidenceIdentity,
    borrow byteview subjectIdentity,
    borrow byteview profileIdentity,
    borrow byteview evidenceIdentity,
    long targetKind,
    long evidenceSource,
    boolean hasNamespace,
    long replicas,
    long quorum,
    borrow mut bytes identity,
    borrow mut region arena
  ) {
    Receipt invalid = new Receipt(prior.kind, prior.depth, false);
    if (prior.valid == false) {
      return invalid;
    }

    if (prior.kind < RECEIPT_WRITE_COMPLETED) {
      return invalid;
    }

    if (RECEIPT_QUORUM_STABLE < prior.kind) {
      return invalid;
    }

    if (prior.depth == prior.kind) {} else {
      return invalid;
    }

    if (targetKind == prior.kind + 1) {} else {
      return invalid;
    }

    if (evidenceSource == targetKind) {} else {
      return invalid;
    }

    if (digestValid(priorIdentity)) {} else {
      return invalid;
    }

    if (digestValid(priorEvidenceIdentity)) {} else {
      return invalid;
    }

    if (
      commonInputsValid(subjectIdentity, profileIdentity, evidenceIdentity, identity) == false
    ) {
      return invalid;
    }

    if (digestsDiffer(priorEvidenceIdentity, evidenceIdentity)) {} else {
      return invalid;
    }

    if (targetKind == RECEIPT_NAMESPACE_VISIBLE) {
      if (hasNamespace) {} else {
        return invalid;
      }
    }

    if (targetKind == RECEIPT_QUORUM_STABLE) {
      if (1 < replicas) {} else {
        return invalid;
      }

      if (1 < quorum) {} else {
        return invalid;
      }

      if (quorum < replicas + 1) {} else {
        return invalid;
      }
    }

    receiptIdentity(
      targetKind,
      evidenceSource,
      prior.depth + 1,
      subjectIdentity,
      profileIdentity,
      evidenceIdentity,
      priorIdentity,
      true,
      identity,
      arena
    );
    return new Receipt(targetKind, prior.depth + 1, true);
  }
}
