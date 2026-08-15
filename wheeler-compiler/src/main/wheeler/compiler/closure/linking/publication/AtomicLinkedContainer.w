//! Publishes a verified linked container and identity under one copy boundary.

module wheeler.compiler.closure.atomic_linked_container;

import wheeler.compiler.closure.linked_container;
import wheeler.crypto.sha256;

classical class AtomicLinkedContainer {
  private const long CONTAINER_BYTES = 16777216;
  private const long IDENTITY_BYTES = 32;
  private const long SECTION_ROWS = 64;

  /// Reports one completely staged canonical container.
  public record AtomicLinkedContainerPlan(long length, long sectionCount) {}

  /// Assembles, verifies, hashes, and publishes all linked bytes atomically.
  public AtomicLinkedContainerPlan publishAtomicLinkedContainer(
    borrow byteview sections,
    long sectionBytes,
    long sectionCount,
    borrow mut words sectionTypes,
    borrow mut words sectionStarts,
    borrow mut words sectionLengths,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    assert(bufferLength(sectionTypes) == SECTION_ROWS);
    assert(bufferLength(sectionStarts) == SECTION_ROWS);
    assert(bufferLength(sectionLengths) == SECTION_ROWS);
    assert(0 < bufferLength(output));
    assert(bufferLength(output) < CONTAINER_BYTES + 1);
    assert(bufferLength(identity) == IDENTITY_BYTES);
    region containerArena = new region(/* bytes= */ CONTAINER_BYTES, /* allocations= */ 1);
    bytes stagedContainer = allocateBytes(containerArena, CONTAINER_BYTES);
    long length = emitCanonicalContainer(
      sections,
      sectionBytes,
      sectionCount,
      sectionTypes,
      sectionStarts,
      sectionLengths,
      stagedContainer
    );
    assert(length < bufferLength(output) + 1);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    region identityArena = new region(/* bytes= */ IDENTITY_BYTES, /* allocations= */ 1);
    bytes stagedIdentity = allocateBytes(identityArena, IDENTITY_BYTES);
    hashSha256Range(stagedContainer, /* start= */ 0, length, stagedIdentity, hashArena);
    long containerByte = 0;
    while (containerByte < length) limit CONTAINER_BYTES {
      setByte(output, containerByte, stagedContainer[containerByte]);
      containerByte += 1;
    }

    long identityByte = 0;
    while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(identity, identityByte, stagedIdentity[identityByte]);
      identityByte += 1;
    }

    drop(stagedIdentity);
    drop(identityArena);
    drop(hashArena);
    drop(stagedContainer);
    drop(containerArena);
    return new AtomicLinkedContainerPlan(length, sectionCount);
  }
}
