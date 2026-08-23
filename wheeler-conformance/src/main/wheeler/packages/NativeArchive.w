//! Checks canonical package archives with Wheeler-native codecs.

module wheeler.conformance.packages.archive_main;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.packages.archive;

classical class NativeArchive {
  state long manifestLength = 0;
  state long entryCount = 0;
  state long pathLength = 0;
  state long dataLength = 0;
  state long secondPathLength = 0;
  state long secondDataLength = 0;
  state long packageLength = 0;
  state long targetCount = 0;
  state long finalLength = 0;

  /// Runs the bounded `NativeArchive` fixture.
  ///
  /// - Effects: Mutates only the fixture's declared state.
  entry void main(borrow byteview source) {
    region arena = new region(12288, 12);
    bytes digest = allocateBytes(arena, 32);
    ArchiveResult parsed = inspectArchive(source, digest, arena);
    match (parsed) {
      case ArchiveResult.Value(ArchiveModel archive) {
        manifestLength = archive.manifestLength;
        entryCount = archive.entryCount;
        ArchiveEntry first = validatedArchiveEntry(
          source,
          archive.manifestLength,
          /* ordinal= */ 0
        );
        pathLength = first.pathLength;
        dataLength = first.sourceLength;
        if (1 < archive.entryCount) {
          ArchiveEntry second = validatedArchiveEntry(
            source,
            archive.manifestLength,
            /* ordinal= */ 1
          );
          secondPathLength = second.pathLength;
          secondDataLength = second.sourceLength;
        }

        packageLength = archive.packageLength;
        targetCount = archive.targetCount;
      }
      case ArchiveResult.Error(long offset) {
        assert(finalLength == 1);
      }
    }

    finalLength = bufferLength(source);
    drop(digest);
    drop(arena);
  }
}
