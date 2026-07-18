module examples.packages.main;
import examples.lexer.scanner;
import examples.packages.emitter;
import examples.packages.manifest;
classical class NativeManifest {
    state long nameLength = 0;
    state long nameStart = 0;
    state long profileLength = 0;
    state long versionLength = 0;
    state long targetCount = 0;
    state long targetNameLength = 0;
    state long targetRootLength = 0;
    state long targetModuleLength = 0;
    state long targetSourceCount = 0;
    state long targetSourceLength = 0;
    state long targetSecondSourceLength = 0;
    state long dependencyCount = 0;
    state long dependencyNameLength = 0;
    state long dependencyVersionLength = 0;
    state long capabilityCount = 0;
    state long capabilityNameLength = 0;
    state long capabilityPathLength = 0;
    state long emittedLength = 0;
    state long finalCursor = 0;

    entry void main(utf8 source, bytes canonical) {
        region arena = new region(1152, 3);
        words kinds = allocate(arena, 48);
        words starts = allocate(arena, 48);
        words lengths = allocate(arena, 48);
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
                targetModuleLength = header.targetModule.length;
                targetSourceCount = header.targetSourceCount;
                targetSourceLength = header.targetSource.length;
                targetSecondSourceLength = header.targetSecondSource.length;
                dependencyCount = header.dependencyCount;
                dependencyNameLength = header.dependencyName.length;
                dependencyVersionLength = header.dependencyVersion.length;
                capabilityCount = header.capabilityCount;
                capabilityNameLength = header.capabilityName.length;
                capabilityPathLength = header.capabilityPath.length;
                emittedLength = emitCanonical(
                    source,
                    starts,
                    lengths,
                    count,
                    canonical);
            }
            case ManifestResult.Error(long parseOffset) {
                assert finalCursor == 1;
            }
        }
        finalCursor = bufferLength(source);
        assert nameLength == 11;
        assert versionLength == 10;
        assert profileLength == 11;
        assert targetCount == 1;
        assert targetNameLength == 3;
        assert targetRootLength == 11;
        assert targetModuleLength == 8;
        assert targetSourceCount == 2;
        assert targetSourceLength == 11;
        assert targetSecondSourceLength == 12;
        assert dependencyCount == 1;
        assert dependencyNameLength == 9;
        assert dependencyVersionLength == 6;
        assert capabilityCount == 1;
        assert capabilityNameLength == 7;
        assert capabilityPathLength == 9;
        setOutputLength(canonical, emittedLength);

        drop(lengths);
        drop(starts);
        drop(kinds);
        drop(arena);
    }
}
