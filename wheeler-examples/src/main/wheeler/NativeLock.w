module examples.packages.lock_main;
import examples.lexer.scanner;
import examples.packages.lock;
import examples.packages.lock_emitter;
classical class NativeLock {
    state long rootStart = 0;
    state long packageCount = 0;
    state long firstNameLength = 0;
    state long firstVersionLength = 0;
    state long secondNameLength = 0;
    state long edgeCount = 0;
    state long emittedLength = 0;
    state long finalCursor = 0;

    entry void main(utf8 source, bytes canonical) {
        region arena = new region(768, 3);
        words kinds = allocate(arena, 32);
        words starts = allocate(arena, 32);
        words lengths = allocate(arena, 32);
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
        LockResult parsed = parse(source, kinds, starts, lengths, count);
        match (parsed) {
            case LockResult.Value(LockModel lock) {
                rootStart = lock.rootStart;
                packageCount = lock.packageCount;
                firstNameLength = lock.first.nameLength;
                firstVersionLength = lock.first.versionLength;
                secondNameLength = lock.second.nameLength;
                edgeCount = lock.edgeCount;
                emittedLength = emitCanonicalLock(
                    source,
                    starts,
                    lengths,
                    count,
                    canonical);
            }
            case LockResult.Error(long parseOffset) {
                assert finalCursor == 1;
            }
        }
        finalCursor = bufferLength(source);
        assert rootStart == 13;
        assert packageCount == 2;
        assert firstNameLength == 8;
        assert firstVersionLength == 5;
        assert secondNameLength == 9;
        assert edgeCount == 1;
        setOutputLength(canonical, emittedLength);
        drop(lengths);
        drop(starts);
        drop(kinds);
        drop(arena);
    }
}
