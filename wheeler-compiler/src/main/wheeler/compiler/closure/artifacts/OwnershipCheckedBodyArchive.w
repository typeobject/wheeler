//! Gates compiled-body archive publication on independent ownership coordinates.

module wheeler.compiler.closure.ownership_checked_body_archive;

import wheeler.compiler.closure.compiled_body_archive;
import wheeler.compiler.closure.instruction_ownership_products;

classical class OwnershipCheckedBodyArchive {
  private const long MAX_EVENTS = 8192;

  /// Reports checked archive publication without claiming publication on disagreement.
  public record OwnershipCheckedBodyArchivePlan(
    long artifactRank,
    long artifactCount,
    long archiveBytes,
    boolean valid
  ) {}

  /// Appends one artifact only when source and decoded ownership coordinates agree.
  public OwnershipCheckedBodyArchivePlan appendOwnershipCheckedBodyArtifact(
    borrow byteview artifact,
    long artifactLength,
    long moduleOwner,
    long sourceEventCount,
    borrow mut words sourceCoordinates,
    long decodedEventCount,
    borrow mut words decodedCoordinates,
    long artifactCount,
    long archiveBytes,
    borrow mut words modulePublished,
    borrow mut words moduleArtifactRanks,
    borrow mut words artifactStarts,
    borrow mut words artifactLengths,
    borrow mut bytes archive
  ) {
    assert(-1 < sourceEventCount);
    assert(sourceEventCount < MAX_EVENTS + 1);
    assert(-1 < decodedEventCount);
    assert(decodedEventCount < MAX_EVENTS + 1);
    assert(bufferLength(sourceCoordinates) == 32768);
    assert(bufferLength(decodedCoordinates) == 32768);

    if (sourceEventCount != decodedEventCount) {
      return new OwnershipCheckedBodyArchivePlan(-1, artifactCount, archiveBytes, false);
    }

    if (
      ownershipCoordinatesAgree(sourceEventCount, sourceCoordinates, decodedCoordinates) == false
    ) {
      return new OwnershipCheckedBodyArchivePlan(-1, artifactCount, archiveBytes, false);
    }

    CompiledBodyArchivePlan appended = appendCompiledBodyArtifact(
      artifact,
      artifactLength,
      moduleOwner,
      artifactCount,
      archiveBytes,
      modulePublished,
      moduleArtifactRanks,
      artifactStarts,
      artifactLengths,
      archive
    );
    return new OwnershipCheckedBodyArchivePlan(
      appended.artifactRank,
      appended.artifactCount,
      appended.archiveBytes,
      true
    );
  }
}
