//! Publishes one verified source-local artifact from canonical product sections.

module wheeler.compiler.closure.source_product_artifact;

import wheeler.compiler.closure.linked_container;
import wheeler.compiler.verifier;
import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;

classical class SourceProductArtifact {
  private const long ARTIFACT_BYTES = 32768;
  private const long DIRECTORY_ROWS = 64;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_FUNCTIONS = 65;

  /// Reports one verified source-local module artifact.
  public record SourceProductArtifactPlan(
    long length,
    long codeStart,
    long functionCount,
    long maxLocalCount
  ) {}

  /// Assembles, verifies, hashes, and atomically publishes canonical product sections.
  public SourceProductArtifactPlan publishSourceProductArtifact(
    borrow byteview sectionArchive,
    long sectionBytes,
    long sectionCount,
    borrow mut words sectionStarts,
    borrow mut words sectionLengths,
    borrow mut bytes output,
    borrow mut bytes identity
  ) {
    assert(-1 < sectionBytes);
    assert(sectionBytes < ARTIFACT_BYTES + 1);
    assert(sectionBytes < bufferLength(sectionArchive) + 1);
    assert(5 < sectionCount);
    assert(sectionCount < 8);
    assert(bufferLength(sectionStarts) == DIRECTORY_ROWS);
    assert(bufferLength(sectionLengths) == DIRECTORY_ROWS);
    assert(bufferLength(output) == ARTIFACT_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);

    region staging = new region(/* bytes= */ 33312, /* allocations= */ 3);
    words sectionTypes = allocate(staging, DIRECTORY_ROWS);
    bytes stagedArtifact = allocateBytes(staging, ARTIFACT_BYTES);
    bytes stagedIdentity = allocateBytes(staging, IDENTITY_BYTES);
    long section = 0;
    while (section < 6) limit 6 {
      set(sectionTypes, section, section + 1);
      section += 1;
    }

    if (sectionCount == 7) {
      set(sectionTypes, 6, 10);
    }

    long artifactLength = emitCanonicalContainer(
      sectionArchive,
      sectionBytes,
      sectionCount,
      sectionTypes,
      sectionStarts,
      sectionLengths,
      stagedArtifact
    );
    assert(0 < artifactLength);
    assert(artifactLength < ARTIFACT_BYTES + 1);
    assert(verifyArtifact(stagedArtifact, artifactLength) == 1);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(stagedArtifact, 0, artifactLength, stagedIdentity, hashArena);

    long functionDirectory = 40 + 4 * 32;
    long functionStart = readUnsigned(stagedArtifact, functionDirectory + 8, 8);
    long functionCount = readUnsigned(stagedArtifact, functionStart, 4);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    long maxLocalCount = 0;
    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      long descriptor = functionStart + 4 + function * 40;
      long localCount = readUnsigned(stagedArtifact, descriptor + 32, 4);
      if (maxLocalCount < localCount) {
        maxLocalCount = localCount;
      }

      function += 1;
    }

    long codeDirectory = 40 + 5 * 32;
    long codeStart = readUnsigned(stagedArtifact, codeDirectory + 8, 8);
    long outputByte = 0;
    while (outputByte < ARTIFACT_BYTES) limit ARTIFACT_BYTES {
      setByte(output, outputByte, stagedArtifact[outputByte]);
      outputByte += 1;
    }

    long identityByte = 0;
    while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(identity, identityByte, stagedIdentity[identityByte]);
      identityByte += 1;
    }

    SourceProductArtifactPlan result = new SourceProductArtifactPlan(
      artifactLength,
      codeStart,
      functionCount,
      maxLocalCount
    );
    drop(hashArena);
    drop(stagedIdentity);
    drop(stagedArtifact);
    drop(sectionTypes);
    drop(staging);
    return result;
  }
}
