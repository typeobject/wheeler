//! Checks canonical package archives with Wheeler-native codecs.

module examples.packages.archive_main;
import wheeler.crypto.sha256;
import wheeler.packages.archive;
import wheeler.packages.binary;
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
    entry void main(byteview source) {
        region arena = new region(11300, 6);
        bytes digest = allocateBytes(arena, 32);
        ArchiveResult parsed = inspectArchive(source, digest, arena);
        match (parsed) {
            case ArchiveResult.Value(ArchiveModel archive) {
                manifestLength = archive.manifestLength;
                entryCount = archive.entryCount;
                pathLength = archive.pathLength;
                dataLength = archive.dataLength;
                secondPathLength = archive.secondPathLength;
                secondDataLength = archive.secondDataLength;
                packageLength = archive.packageLength;
                targetCount = archive.targetCount;
            }
            case ArchiveResult.Error(long offset) {
                assert finalLength == 1;
            }
        }
        finalLength = bufferLength(source);
        drop(digest);
        drop(arena);
    }
}
