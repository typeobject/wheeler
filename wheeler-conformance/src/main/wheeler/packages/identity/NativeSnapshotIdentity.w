//! Computes the content identity of one bounded canonical repository snapshot.

module wheeler.conformance.packages.snapshot_identity;

import wheeler.crypto.content_identity;
import wheeler.lexer.scanner;
import wheeler.packages.snapshot;

classical class NativeSnapshotIdentity {
  state long releaseCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  /// Validates and identifies one snapshot without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    region arena = new region(10000, 10);
    utf8 source = freezeBoundedUtf8(rawSource, 2048, arena);
    words kinds = allocate(arena, 256);
    words starts = allocate(arena, 256);
    words lengths = allocate(arena, 256);
    words rows = allocate(arena, 24);
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

    SnapshotResult parsed = parseSnapshot(source, kinds, starts, lengths, count, rows);
    match (parsed) {
      case SnapshotResult.Value(SnapshotModel snapshot) {
        releaseCount = snapshot.releaseCount;
        sourceLength = bufferLength(source);
        publishSha256(rawSource, identity, arena);
        published = 1;
      }
      case SnapshotResult.Error(long offset) {
        diagnosticOffset = offset;
        assert(published == 1);
      }
    }

    setOutputLength(identity, published * 32);
    drop(rows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(source);
    drop(arena);
  }
}
