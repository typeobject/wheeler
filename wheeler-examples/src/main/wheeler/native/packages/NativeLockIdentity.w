//! Computes the content identity of one bounded canonical dependency lock.

module examples.packages.lock_identity;

import wheeler.crypto.sha256;
import wheeler.lexer.scanner;
import wheeler.packages.lock;

classical class NativeLockIdentity {
  state long packageCount = 0;
  state long edgeCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  private void copyInput(borrow byteview source, borrow mut bytes target) {
    long cursor = 0;
    while (cursor < bufferLength(source)) limit 2048 {
      setByte(target, cursor, source[cursor]);
      cursor += 1;
    }
  }

  private void publishDigest(borrow mut bytes digest, borrow mut bytes output) {
    long cursor = 0;
    while (cursor < 32) limit 32 {
      setByte(output, cursor, digest[cursor]);
      cursor += 1;
    }
  }

  /// Validates and identifies one lock without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    if (2048 < bufferLength(rawSource)) {
      long oversized = rawSource[-1];
    }

    region arena = new region(11000, 24);
    bytes sourceBytes = allocateBytes(arena, bufferLength(rawSource));
    copyInput(rawSource, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    bytes digest = allocateBytes(arena, 32);
    words kinds = allocate(arena, 256);
    words starts = allocate(arena, 256);
    words lengths = allocate(arena, 256);
    words packageNameStarts = allocate(arena, 1);
    words packageNameLengths = allocate(arena, 1);
    words versionStarts = allocate(arena, 1);
    words versionLengths = allocate(arena, 1);
    words repositoryStarts = allocate(arena, 1);
    words snapshotStarts = allocate(arena, 1);
    words archiveStarts = allocate(arena, 1);
    words manifestStarts = allocate(arena, 1);
    words dependencyOffsets = allocate(arena, 1);
    words dependencyCounts = allocate(arena, 1);
    words edgeTargetStarts = allocate(arena, 1);
    words edgeTargetLengths = allocate(arena, 1);
    long count = 0;
    ScanResult scanned = scan(source, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long scannedCount) {
        count = scannedCount;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        diagnosticOffset = diagnostic.offset;
        assert(published == 1);
      }
    }

    LockResult parsed = parse(
      source,
      kinds,
      starts,
      lengths,
      count,
      packageNameStarts,
      packageNameLengths,
      versionStarts,
      versionLengths,
      repositoryStarts,
      snapshotStarts,
      archiveStarts,
      manifestStarts,
      dependencyOffsets,
      dependencyCounts,
      edgeTargetStarts,
      edgeTargetLengths
    );
    match (parsed) {
      case LockResult.Value(LockModel lock) {
        packageCount = lock.packageCount;
        edgeCount = lock.edgeCount;
        sourceLength = bufferLength(source);
        hashSha256(rawSource, digest, arena);
        publishDigest(digest, identity);
        published = 1;
      }
      case LockResult.Error(long offset) {
        diagnosticOffset = offset;
        assert(published == 1);
      }
    }

    setOutputLength(identity, published * 32);
    drop(edgeTargetLengths);
    drop(edgeTargetStarts);
    drop(dependencyCounts);
    drop(dependencyOffsets);
    drop(manifestStarts);
    drop(archiveStarts);
    drop(snapshotStarts);
    drop(repositoryStarts);
    drop(versionLengths);
    drop(versionStarts);
    drop(packageNameLengths);
    drop(packageNameStarts);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(digest);
    drop(source);
    drop(arena);
  }
}
