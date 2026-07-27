//! Computes the content identity of one bounded canonical dependency lock.

module examples.packages.lock_identity;

import wheeler.crypto.content_identity;
import wheeler.lexer.scanner;
import wheeler.packages.lock;

classical class NativeLockIdentity {
  state long packageCount = 0;
  state long edgeCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  /// Validates and identifies one lock without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    region arena = new region(11000, 24);
    utf8 source = freezeBoundedUtf8(rawSource, 2048, arena);
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
        publishSha256(rawSource, identity, arena);
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
    drop(source);
    drop(arena);
  }
}
