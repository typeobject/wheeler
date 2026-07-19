//! Parses and re-emits a canonical dependency lock in Wheeler.

module examples.packages.lock_main;

import wheeler.lexer.scanner;
import wheeler.packages.line_emitter;
import wheeler.packages.lock;

classical class NativeLock {
  state long rootStart = 0;
  state long packageCount = 0;
  state long firstNameLength = 0;
  state long firstVersionLength = 0;
  state long secondNameLength = 0;
  state long lastNameLength = 0;
  state long edgeCount = 0;
  state long emittedLength = 0;
  state long finalCursor = 0;

  /// Runs the bounded `NativeLock` fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes canonical) {
    region arena = new region(14336, 14);
    words kinds = allocate(arena, 512);
    words starts = allocate(arena, 512);
    words lengths = allocate(arena, 512);
    words packageNameStarts = allocate(arena, 8);
    words packageNameLengths = allocate(arena, 8);
    words versionStarts = allocate(arena, 8);
    words versionLengths = allocate(arena, 8);
    words repositoryStarts = allocate(arena, 8);
    words archiveStarts = allocate(arena, 8);
    words manifestStarts = allocate(arena, 8);
    words dependencyOffsets = allocate(arena, 8);
    words dependencyCounts = allocate(arena, 8);
    words edgeTargetStarts = allocate(arena, 16);
    words edgeTargetLengths = allocate(arena, 16);
    long count = 0;
    ScanResult scanned = scan(source, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long tokenCount) {
        count = tokenCount;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(finalCursor == 1);
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
      archiveStarts,
      manifestStarts,
      dependencyOffsets,
      dependencyCounts,
      edgeTargetStarts,
      edgeTargetLengths
    );
    match (parsed) {
      case LockResult.Value(LockModel lock) {
        rootStart = lock.rootStart;
        packageCount = lock.packageCount;
        if (0 < packageCount) {
          firstNameLength = packageNameLengths[0];
          firstVersionLength = versionLengths[0];
          lastNameLength = packageNameLengths[packageCount - 1];
        }

        if (1 < packageCount) {
          secondNameLength = packageNameLengths[1];
        }

        edgeCount = lock.edgeCount;
        emittedLength = emitCanonicalLines(source, starts, lengths, count, canonical);
      }
      case LockResult.Error(long parseOffset) {
        assert(finalCursor == 1);
      }
    }

    finalCursor = bufferLength(source);
    assert(rootStart == 17);
    setOutputLength(canonical, emittedLength);
    drop(edgeTargetLengths);
    drop(edgeTargetStarts);
    drop(dependencyCounts);
    drop(dependencyOffsets);
    drop(manifestStarts);
    drop(archiveStarts);
    drop(repositoryStarts);
    drop(versionLengths);
    drop(versionStarts);
    drop(packageNameLengths);
    drop(packageNameStarts);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(arena);
  }
}
