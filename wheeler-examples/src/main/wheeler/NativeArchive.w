module examples.packages.archive_main;
import examples.crypto.sha256;
import examples.packages.archive;
import examples.packages.binary;
classical class NativeArchive {
    state long manifestLength = 0;
    state long entryCount = 0;
    state long pathLength = 0;
    state long dataLength = 0;
    state long finalLength = 0;

    entry void main(byteview source) {
        region arena = new region(1120, 4);
        bytes digest = allocateBytes(arena, 32);
        ArchiveResult parsed = inspectArchive(source, digest, arena);
        match (parsed) {
            case ArchiveResult.Value(ArchiveModel archive) {
                manifestLength = archive.manifestLength;
                entryCount = archive.entryCount;
                pathLength = archive.pathLength;
                dataLength = archive.dataLength;
            }
            case ArchiveResult.Error(long offset) {
                assert finalLength == 1;
            }
        }
        finalLength = bufferLength(source);
        assert manifestLength == 103;
        assert entryCount == 1;
        assert pathLength == 10;
        assert dataLength == 4;
        drop(digest);
        drop(arena);
    }
}
