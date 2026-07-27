//! Computes the content identity of one bounded canonical repository snapshot.

module examples.packages.snapshot_identity;

import wheeler.crypto.sha256;
import wheeler.lexer.scanner;
import wheeler.packages.snapshot;

classical class NativeSnapshotIdentity {
  state long releaseCount = 0;
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

  /// Validates and identifies one snapshot without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    if (2048 < bufferLength(rawSource)) {
      long oversized = rawSource[-1];
    }

    region arena = new region(10000, 10);
    bytes sourceBytes = allocateBytes(arena, bufferLength(rawSource));
    copyInput(rawSource, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    bytes digest = allocateBytes(arena, 32);
    hashSha256(rawSource, digest, arena);
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
        publishDigest(digest, identity);
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
    drop(digest);
    drop(source);
    drop(arena);
  }
}
