//! Publishes one native source compilation and execution outcome.

module wheeler.conformance.testing.runners.native_source_test_run;

import wheeler.runtime.artifact_execution;
import wheeler.runtime.testing.runners.test_source_execution;

classical class NativeSourceTestRun {
  state long artifactLength = 0;
  state long executedSteps = 0;
  state long published = 0;

  private void writeUnsigned(borrow mut bytes output, long start, long value) {
    long remaining = value;
    long offset = 0;
    while (offset < 4) limit 4 {
      setByte(output, start + offset, remaining % 256);
      remaining = remaining / 256;
      offset += 1;
    }

    assert(remaining == 0);
  }

  /// Compiles and executes one source exactly once with fresh owned storage.
  entry void main(borrow utf8 source, borrow mut bytes output) {
    assert(bufferLength(output) == 14);
    region arena = new region(/* bytes= */ 67000, /* allocations= */ 4);
    bytes artifact = allocateBytes(arena, /* length= */ 32768);
    bytes trace = allocateBytes(arena, /* length= */ 1024);
    artifactLength = compileTestSource(source, artifact);
    bytes executable = allocateBytes(arena, artifactLength);
    long artifactByte = 0;
    while (artifactByte < artifactLength) limit 32768 {
      setByte(executable, artifactByte, artifact[artifactByte]);
      artifactByte += 1;
    }

    ArtifactOutcome outcome = executeBoundedArtifact(executable, trace);
    writeUnsigned(output, /* start= */ 0, artifactLength);
    if (outcome.passed) {
      setByte(output, /* index= */ 4, /* passed= */ 1);
    } else {
      setByte(output, /* index= */ 4, /* passed= */ 0);
    }

    writeUnsigned(output, /* start= */ 5, outcome.steps);
    setByte(output, /* index= */ 9, outcome.globalCount);
    writeUnsigned(output, /* start= */ 10, outcome.errorOffset);
    executedSteps = outcome.steps;
    published = 1;
    setOutputLength(output, 14);
    drop(executable);
    drop(trace);
    drop(artifact);
    drop(arena);
  }
}
