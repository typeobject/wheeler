//! Publishes report metadata from one successfully verified test artifact.

module wheeler.conformance.testing.native_test_artifact_metadata;

import wheeler.compiler.opcodes;
import wheeler.runtime.artifact_execution;
import wheeler.runtime.artifact_metadata;

classical class NativeTestArtifactMetadata {
  private long writeText(
    borrow byteview artifact,
    ArtifactText text,
    borrow mut bytes output,
    long cursor
  ) {
    setByte(output, cursor, text.length % 256);
    setByte(output, cursor + 1, text.length / 256);
    cursor += 2;
    long offset = 0;
    while (offset < text.length) limit 255 {
      setByte(output, cursor + offset, artifact[text.start + offset]);
      offset += 1;
    }

    return cursor + text.length;
  }

  /// Publishes the program name, kind, and ordered global names after execution verifies.
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    assert(bufferLength(output) == 4096);
    region staging = new region(/* bytes= */ 32896, /* allocations= */ 3);
    bytes traceOpcodes = allocateBytes(staging, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, traceOpcodes);
    assert(outcome.passed);
    ArtifactText program = artifactProgramText(artifact);
    assert(program.length < 256);
    long kind = artifactProgramKind(artifact);
    assert(kind < 3);
    long globalCount = artifactGlobalCount(artifact);
    assert(globalCount == outcome.globalCount);
    assert(globalCount < 9);
    words starts = allocate(staging, /* length= */ 8);
    words lengths = allocate(staging, /* length= */ 8);
    long resultLength = 4 + program.length;
    long global = 0;
    while (global < globalCount) limit 8 {
      ArtifactText name = artifactGlobalText(artifact, global);
      assert(name.length < 256);
      set(starts, global, name.start);
      set(lengths, global, name.length);
      resultLength += 2 + name.length;
      global += 1;
    }

    assert(resultLength < bufferLength(output) + 1);

    long cursor = writeText(artifact, program, output, /* cursor= */ 0);
    setByte(output, cursor, kind);
    setByte(output, cursor + 1, globalCount);
    cursor += 2;
    global = 0;
    while (global < globalCount) limit 8 {
      ArtifactText emittedName = new ArtifactText(starts[global], lengths[global]);
      cursor = writeText(artifact, emittedName, output, cursor);
      global += 1;
    }

    setOutputLength(output, cursor);
    drop(lengths);
    drop(starts);
    drop(traceOpcodes);
    drop(staging);
  }
}
