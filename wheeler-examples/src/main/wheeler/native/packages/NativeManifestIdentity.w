//! Computes the content identity of one bounded canonical package manifest.

module examples.packages.manifest_identity;

import wheeler.crypto.sha256;
import wheeler.lexer.scanner;
import wheeler.packages.manifest;

classical class NativeManifestIdentity {
  state long targetCount = 0;
  state long sourceCount = 0;
  state long dependencyCount = 0;
  state long capabilityCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  private void copyInput(borrow byteview source, borrow mut bytes target) {
    long cursor = 0;
    while (cursor < bufferLength(source)) limit 1024 {
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

  /// Validates and identifies one manifest without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    if (1024 < bufferLength(rawSource)) {
      long oversized = rawSource[-1];
    }

    region arena = new region(9000, 14);
    bytes sourceBytes = allocateBytes(arena, bufferLength(rawSource));
    copyInput(rawSource, sourceBytes);
    utf8 source = freezeUtf8(sourceBytes);
    bytes digest = allocateBytes(arena, 32);
    words kinds = allocate(arena, 256);
    words starts = allocate(arena, 256);
    words lengths = allocate(arena, 256);
    words targetRows = allocate(arena, 10);
    words sourceRows = allocate(arena, 2);
    words dependencyRows = allocate(arena, 5);
    words capabilityRows = allocate(arena, 4);
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

    ManifestResult parsed = parseManifest(
      source,
      kinds,
      starts,
      lengths,
      count,
      targetRows,
      sourceRows,
      dependencyRows,
      capabilityRows
    );
    match (parsed) {
      case ManifestResult.Value(ManifestModel manifest) {
        targetCount = manifest.targetCount;
        sourceCount = manifest.sourceCount;
        dependencyCount = manifest.dependencyCount;
        capabilityCount = manifest.capabilityCount;
        sourceLength = bufferLength(source);
        hashSha256(rawSource, digest, arena);
        publishDigest(digest, identity);
        published = 1;
      }
      case ManifestResult.Error(long offset) {
        diagnosticOffset = offset;
        assert(published == 1);
      }
    }

    setOutputLength(identity, published * 32);
    drop(capabilityRows);
    drop(dependencyRows);
    drop(sourceRows);
    drop(targetRows);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(digest);
    drop(source);
    drop(arena);
  }
}
