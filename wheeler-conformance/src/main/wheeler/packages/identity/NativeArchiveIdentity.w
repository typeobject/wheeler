//! Computes the content identity of one bounded canonical package archive.

module wheeler.conformance.packages.archive_identity;

import wheeler.crypto.content_identity;
import wheeler.packages.archive;

classical class NativeArchiveIdentity {
  state long manifestLength = 0;
  state long entryCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  /// Validates and identifies one archive without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview source, borrow mut bytes identity) {
    if (4096 < bufferLength(source)) {
      long oversized = source[-1];
    }

    region arena = new region(14000, 12);
    bytes scratchDigest = allocateBytes(arena, 32);
    ArchiveResult inspected = inspectArchive(source, scratchDigest, arena);
    match (inspected) {
      case ArchiveResult.Value(ArchiveModel archive) {
        manifestLength = archive.manifestLength;
        entryCount = archive.entryCount;
        sourceLength = bufferLength(source);
        publishSha256(source, identity, arena);
        published = 1;
      }
      case ArchiveResult.Error(long offset) {
        diagnosticOffset = offset;
        assert(published == 1);
      }
    }

    setOutputLength(identity, published * 32);
    drop(scratchDigest);
    drop(arena);
  }
}
