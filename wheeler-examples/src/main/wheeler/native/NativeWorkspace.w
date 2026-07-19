//! Parses and re-emits a canonical workspace manifest in Wheeler.

module examples.packages.workspace_main;

import wheeler.lexer.scanner;
import wheeler.packages.line_emitter;
import wheeler.packages.workspace;

classical class NativeWorkspace {
  state long nameStart = 0;
  state long nameLength = 0;
  state long profileLength = 0;
  state long memberCount = 0;
  state long firstMemberNameLength = 0;
  state long firstMemberPathLength = 0;
  state long secondMemberNameLength = 0;
  state long secondMemberPathLength = 0;
  state long lastMemberNameLength = 0;
  state long lastMemberPathLength = 0;
  state long emittedLength = 0;
  state long finalCursor = 0;

  /// Runs the bounded `NativeWorkspace` fixture.
  ///
  /// - Effects: Mutates declared state and caller-owned byte output.
  entry void main(borrow utf8 source, borrow mut bytes canonical) {
    region arena = new region(7168, 7);
    words kinds = allocate(arena, 256);
    words starts = allocate(arena, 256);
    words lengths = allocate(arena, 256);
    words memberNameStarts = allocate(arena, 16);
    words memberNameLengths = allocate(arena, 16);
    words memberPathStarts = allocate(arena, 16);
    words memberPathLengths = allocate(arena, 16);
    long count = 0;
    ScanResult scanned = scan(source, kinds, starts, lengths);
    match (scanned) {
      case ScanResult.Value(long tokenCount) {
        count = tokenCount;
      }
      case ScanResult.Error(ScanDiagnostic diagnostic) {
        assert(finalCursor == 1);
      }
    }

    WorkspaceResult parsed = parseWorkspace(
      source,
      kinds,
      starts,
      lengths,
      count,
      memberNameStarts,
      memberNameLengths,
      memberPathStarts,
      memberPathLengths
    );
    match (parsed) {
      case WorkspaceResult.Value(WorkspaceModel workspace) {
        nameStart = workspace.nameStart;
        nameLength = workspace.nameLength;
        profileLength = workspace.profileLength;
        memberCount = workspace.memberCount;
        firstMemberNameLength = memberNameLengths[0];
        firstMemberPathLength = memberPathLengths[0];
        secondMemberNameLength = memberNameLengths[1];
        secondMemberPathLength = memberPathLengths[1];
        lastMemberNameLength = memberNameLengths[memberCount - 1];
        lastMemberPathLength = memberPathLengths[memberCount - 1];
        emittedLength = emitCanonicalLines(source, starts, lengths, count, canonical);
      }
      case WorkspaceResult.Error(long parseOffset) {
        assert(finalCursor == 1);
      }
    }

    finalCursor = bufferLength(source);
    assert(nameStart == 30);
    assert(nameLength == 14);
    assert(profileLength == 11);
    setOutputLength(canonical, emittedLength);
    drop(memberPathLengths);
    drop(memberPathStarts);
    drop(memberNameLengths);
    drop(memberNameStarts);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(arena);
  }
}
