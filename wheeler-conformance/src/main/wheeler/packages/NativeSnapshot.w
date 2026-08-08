//! Parses and republishes one canonical immutable repository snapshot.

module wheeler.conformance.packages.snapshot;

import wheeler.lexer.scanner;
import wheeler.packages.emitter;
import wheeler.packages.snapshot;

classical class NativeSnapshot {
  state long releaseCount = 0;
  state long firstPackageLength = 0;
  state long lastVersionLength = 0;
  state long emittedLength = 0;
  state long finalCursor = 0;
  state long diagnosticOffset = 0;
  state long tokenCount = 0;

  /// Runs the bounded native snapshot fixture.
  ///
  /// - Effects: Mutates fixture state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes canonical) {
    region arena = new region(12800, 4);
    words kinds = allocate(arena, 512);
    words starts = allocate(arena, 512);
    words lengths = allocate(arena, 512);
    words rows = allocate(arena, 64);
    long count = 0;
    ScanResult scanned = scan(source, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long scannedCount) {
        count = scannedCount;
        tokenCount = scannedCount;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        diagnosticOffset = diagnostic.offset;
        assert(finalCursor == 1);
      }
    }

    SnapshotResult parsed = parseSnapshot(source, kinds, starts, lengths, count, rows);
    match (parsed) {
      case SnapshotResult.Value(SnapshotModel snapshot) {
        releaseCount = snapshot.releaseCount;
        if (0 < releaseCount) {
          firstPackageLength = rows[SNAPSHOT_PACKAGE_LENGTH];
          lastVersionLength = rows[(releaseCount - 1) * SNAPSHOT_ROW_WIDTH
            + SNAPSHOT_VERSION_LENGTH];
        }

        emittedLength = emitCanonical(source, starts, lengths, count, canonical);
      }
      case SnapshotResult.Error(long parseOffset) {
        diagnosticOffset = parseOffset;
        assert(finalCursor == 1);
      }
    }

    finalCursor = bufferLength(source);
    setOutputLength(canonical, emittedLength);
    drop(rows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(arena);
  }
}
