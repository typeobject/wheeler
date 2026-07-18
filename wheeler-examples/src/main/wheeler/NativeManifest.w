module examples.packages.main;
import examples.lexer.scanner;
import examples.packages.manifest;
classical class NativeManifest {
    state long nameLength = 0;
    state long nameStart = 0;
    state long profileLength = 0;
    state long versionLength = 0;
    state long targetCount = 0;
    state long targetNameLength = 0;
    state long targetRootLength = 0;
    state long finalCursor = 0;

    entry void main(utf8 source) {
        region arena = new region(384, 3);
        words kinds = allocate(arena, 16);
        words starts = allocate(arena, 16);
        words lengths = allocate(arena, 16);
        long count = 0;
        ScanResult scanned = scan(source, kinds, starts, lengths);
        match (scanned) {
            case ScanResult.Value(long tokenCount) {
                count = tokenCount;
            }
            case ScanResult.Error(ScanDiagnostic diagnostic) {
                assert finalCursor == 1;
            }
        }
        ManifestResult parsed = parseHeader(
            source, kinds, starts, lengths, count);
        match (parsed) {
            case ManifestResult.Value(ManifestHeader header) {
                nameStart = header.name.start;
                nameLength = header.name.length;
                versionLength = header.version.length;
                profileLength = header.profile.length;
                targetCount = header.targetCount;
                targetNameLength = header.targetName.length;
                targetRootLength = header.targetRoot.length;
            }
            case ManifestResult.Error(long parseOffset) {
                assert finalCursor == 1;
            }
        }
        finalCursor = bufferLength(source);
        assert nameLength == 11;
        assert versionLength == 5;
        assert profileLength == 11;
        assert targetCount == 1;
        assert targetNameLength == 3;
        assert targetRootLength == 9;

        drop(lengths);
        drop(starts);
        drop(kinds);
        drop(arena);
    }
}
