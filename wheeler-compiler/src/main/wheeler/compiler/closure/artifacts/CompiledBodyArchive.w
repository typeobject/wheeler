//! Copies validated callable artifacts into one bounded immutable closure archive.

module wheeler.compiler.closure.compiled_body_archive;

classical class CompiledBodyArchive {
  private const long MAX_ARTIFACT_BYTES = 16777216;
  private const long MAX_MODULES = 512;

  /// Reports the artifact rank and complete archive extent after one append.
  public record CompiledBodyArchivePlan(long artifactRank, long artifactCount, long archiveBytes) {}

  /// Appends one nonempty artifact after duplicate-owner and capacity validation.
  public CompiledBodyArchivePlan appendCompiledBodyArtifact(
    borrow byteview artifact,
    long artifactLength,
    long moduleOwner,
    long artifactCount,
    long archiveBytes,
    borrow mut words modulePublished,
    borrow mut words moduleArtifactRanks,
    borrow mut words artifactStarts,
    borrow mut words artifactLengths,
    borrow mut bytes archive
  ) {
    assert(0 < artifactLength);
    assert(artifactLength < bufferLength(artifact) + 1);
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_MODULES);
    assert(-1 < artifactCount);
    assert(artifactCount < MAX_MODULES);
    assert(-1 < archiveBytes);
    assert(0 < bufferLength(archive));
    assert(bufferLength(archive) < MAX_ARTIFACT_BYTES + 1);
    assert(artifactLength < bufferLength(archive) - archiveBytes + 1);
    assert(bufferLength(modulePublished) == MAX_MODULES);
    assert(bufferLength(moduleArtifactRanks) == MAX_MODULES);
    assert(bufferLength(artifactStarts) == MAX_MODULES);
    assert(bufferLength(artifactLengths) == MAX_MODULES);
    assert(modulePublished[moduleOwner] == 0);

    long sourceByte = 0;
    while (sourceByte < artifactLength) limit MAX_ARTIFACT_BYTES {
      setByte(archive, archiveBytes + sourceByte, artifact[sourceByte]);
      sourceByte += 1;
    }

    set(modulePublished, moduleOwner, 1);
    set(moduleArtifactRanks, moduleOwner, artifactCount);
    set(artifactStarts, artifactCount, archiveBytes);
    set(artifactLengths, artifactCount, artifactLength);
    return new CompiledBodyArchivePlan(
      artifactCount,
      artifactCount + 1,
      archiveBytes + artifactLength
    );
  }

  /// Appends one supplemental code product for an already published module.
  public CompiledBodyArchivePlan appendSupplementalBodyArtifact(
    borrow byteview artifact,
    long artifactLength,
    long moduleOwner,
    long artifactCount,
    long archiveBytes,
    borrow mut words modulePublished,
    borrow mut words moduleSupplementalPublished,
    borrow mut words artifactStarts,
    borrow mut words artifactLengths,
    borrow mut bytes archive
  ) {
    assert(0 < artifactLength);
    assert(artifactLength < bufferLength(artifact) + 1);
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_MODULES);
    assert(-1 < artifactCount);
    assert(artifactCount < MAX_MODULES);
    assert(-1 < archiveBytes);
    assert(0 < bufferLength(archive));
    assert(bufferLength(archive) < MAX_ARTIFACT_BYTES + 1);
    assert(artifactLength < bufferLength(archive) - archiveBytes + 1);
    assert(bufferLength(modulePublished) == MAX_MODULES);
    assert(bufferLength(moduleSupplementalPublished) == MAX_MODULES);
    assert(bufferLength(artifactStarts) == MAX_MODULES);
    assert(bufferLength(artifactLengths) == MAX_MODULES);
    assert(modulePublished[moduleOwner] == 1);
    assert(moduleSupplementalPublished[moduleOwner] == 0);

    long sourceByte = 0;
    while (sourceByte < artifactLength) limit MAX_ARTIFACT_BYTES {
      setByte(archive, archiveBytes + sourceByte, artifact[sourceByte]);
      sourceByte += 1;
    }

    set(moduleSupplementalPublished, moduleOwner, 1);
    set(artifactStarts, artifactCount, archiveBytes);
    set(artifactLengths, artifactCount, artifactLength);
    return new CompiledBodyArchivePlan(
      artifactCount,
      artifactCount + 1,
      archiveBytes + artifactLength
    );
  }
}
