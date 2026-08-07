//! Computes the content identity of one bounded canonical workspace manifest.

module wheeler.conformance.packages.workspace_identity;

import wheeler.crypto.content_identity;
import wheeler.lexer.scanner;
import wheeler.packages.workspace;

classical class NativeWorkspaceIdentity {
  state long memberCount = 0;
  state long sourceLength = 0;
  state long diagnosticOffset = 0;
  state long published = 0;

  /// Validates and identifies one workspace without publishing partial output.
  ///
  /// - Effects: Mutates fixture state and caller-owned identity output.
  entry void main(borrow byteview rawSource, borrow mut bytes identity) {
    region arena = new region(9000, 14);
    utf8 source = freezeBoundedUtf8(rawSource, 1024, arena);
    words kinds = allocate(arena, 256);
    words starts = allocate(arena, 256);
    words lengths = allocate(arena, 256);
    words memberNameStarts = allocate(arena, 2);
    words memberNameLengths = allocate(arena, 2);
    words memberPathStarts = allocate(arena, 2);
    words memberPathLengths = allocate(arena, 2);
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
        memberCount = workspace.memberCount;
        sourceLength = bufferLength(source);
        publishSha256(rawSource, identity, arena);
        published = 1;
      }
      case WorkspaceResult.Error(long offset) {
        diagnosticOffset = offset;
        assert(published == 1);
      }
    }

    setOutputLength(identity, published * 32);
    drop(memberPathLengths);
    drop(memberPathStarts);
    drop(memberNameLengths);
    drop(memberNameStarts);
    drop(lengths);
    drop(starts);
    drop(kinds);
    drop(source);
    drop(arena);
  }
}
