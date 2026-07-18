//! Parses and re-emits a canonical workspace manifest in Wheeler.

module examples.packages.workspace_main;
import examples.lexer.scanner;
import examples.packages.line_emitter;
import examples.packages.workspace;
classical class NativeWorkspace {
    state long nameStart = 0;
    state long nameLength = 0;
    state long profileLength = 0;
    state long memberCount = 0;
    state long firstMemberNameLength = 0;
    state long firstMemberPathLength = 0;
    state long secondMemberNameLength = 0;
    state long secondMemberPathLength = 0;
    state long emittedLength = 0;
    state long finalCursor = 0;

    /// Runs the bounded `NativeWorkspace` fixture.
    ///
    /// - Effects: Mutates declared state and caller-owned byte output.
    entry void main(utf8 source, bytes canonical) {
        region arena = new region(576, 3);
        words kinds = allocate(arena, 24);
        words starts = allocate(arena, 24);
        words lengths = allocate(arena, 24);
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
        WorkspaceResult parsed = parseWorkspace(source, kinds, starts, lengths, count);
        match (parsed) {
            case WorkspaceResult.Value(WorkspaceModel workspace) {
                nameStart = workspace.nameStart;
                nameLength = workspace.nameLength;
                profileLength = workspace.profileLength;
                memberCount = workspace.memberCount;
                firstMemberNameLength = workspace.firstMemberNameLength;
                firstMemberPathLength = workspace.firstMemberPathLength;
                secondMemberNameLength = workspace.secondMemberNameLength;
                secondMemberPathLength = workspace.secondMemberPathLength;
                emittedLength = emitCanonicalLines(source, starts, lengths, count, canonical);
            }
            case WorkspaceResult.Error(long parseOffset) {
                assert finalCursor == 1;
            }
        }
        finalCursor = bufferLength(source);
        assert nameStart == 11;
        assert nameLength == 14;
        assert profileLength == 11;
        assert memberCount == 2;
        assert firstMemberNameLength == 3;
        assert firstMemberPathLength == 12;
        assert secondMemberNameLength == 4;
        assert secondMemberPathLength == 13;
        setOutputLength(canonical, emittedLength);
        drop(lengths);
        drop(starts);
        drop(kinds);
        drop(arena);
    }
}
