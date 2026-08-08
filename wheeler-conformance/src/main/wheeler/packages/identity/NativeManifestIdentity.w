//! Computes the content identity of one bounded canonical package manifest.

module wheeler.conformance.packages.manifest_identity;

import wheeler.compiler.packages.manifest;
import wheeler.crypto.content_identity;
import wheeler.lexer.scanner;

classical class NativeManifestIdentity {
  state long targetCount = 0;
  state long sourceCount = 0;
  state long dependencyCount = 0;
  state long capabilityCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  /// Validates and identifies one manifest without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    region arena = new region(9000, 14);
    utf8 source = freezeBoundedUtf8(rawSource, 1024, arena);
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
        publishSha256(rawSource, identity, arena);
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
    drop(source);
    drop(arena);
  }
}
