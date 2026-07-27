//! Reproduces one bounded canonical durability receipt transition in Wheeler.

module examples.native.durability_receipts;

import wheeler.runtime.io.receipts;

classical class NativeDurabilityReceipts {
  state long finalKind = 0;
  state long finalDepth = 0;
  state long accepted = 0;

  private void copyInput(borrow byteview input, long inputOffset, borrow mut bytes digest) {
    long index = 0;
    while (index < 32) limit 32 {
      long value = input[inputOffset + index];
      setByte(digest, index, value);
      index += 1;
    }
  }

  /// Builds and publishes one canonical native receipt identity.
  ///
  /// - Effects: Mutates fixture state and caller-owned byte output.
  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(input) == 168);
    assert(31 < bufferLength(output));
    region arena = new region(4096, 16);
    bytes subject = allocateBytes(arena, 32);
    bytes profile = allocateBytes(arena, 32);
    bytes evidence = allocateBytes(arena, 32);
    bytes priorEvidence = allocateBytes(arena, 32);
    bytes parent = allocateBytes(arena, 32);
    copyInput(input, 8, subject);
    copyInput(input, 40, profile);
    copyInput(input, 72, evidence);
    copyInput(input, 104, priorEvidence);
    copyInput(input, 136, parent);

    long priorKind = input[0];
    long priorDepth = input[1];
    long targetKind = input[2];
    long evidenceSource = input[3];
    boolean hasNamespace = input[4] == 1;
    long replicas = input[5];
    long quorum = input[6];
    Receipt receipt = new Receipt(0, 0, false);
    if (priorKind == 0) {
      receipt = writeCompleted(subject, profile, evidence, evidenceSource, output, arena);
    } else {
      Receipt prior = new Receipt(priorKind, priorDepth, true);
      receipt = promote(
        prior,
        parent,
        priorEvidence,
        subject,
        profile,
        evidence,
        targetKind,
        evidenceSource,
        hasNamespace,
        replicas,
        quorum,
        output,
        arena
      );
    }

    if (receipt.valid) {
      accepted = 1;
      finalKind = receipt.kind;
      finalDepth = receipt.depth;
      setOutputLength(output, 32);
    }

    drop(parent);
    drop(priorEvidence);
    drop(evidence);
    drop(profile);
    drop(subject);
    drop(arena);
  }
}
