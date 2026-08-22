//! Classifies one bounded artifact through the Wheeler-owned test execution seam.

module wheeler.conformance.testing.native_test_artifact_run;

import wheeler.compiler.opcodes;
import wheeler.runtime.artifact_execution;

classical class NativeTestArtifactRun {
  private void writeLong(long value, borrow mut bytes output, long cursor) {
    long offset = 0;
    while (offset < 8) limit 8 {
      setByte(output, cursor + offset, value % 256);
      value = value / 256;
      offset += 1;
    }
  }

  /// Publishes one closed interpreter outcome for a runner-owned artifact.
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    assert(bufferLength(output) == 25);
    region traceArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes traceOpcodes = allocateBytes(traceArena, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, traceOpcodes);
    if (outcome.passed) {
      setByte(output, /* index= */ 0, /* value= */ 0);
    } else {
      setByte(output, /* index= */ 0, /* value= */ 1);
    }

    writeLong(outcome.steps, output, /* cursor= */ 1);
    writeLong(outcome.finalGlobal, output, /* cursor= */ 9);
    writeLong(outcome.errorOffset, output, /* cursor= */ 17);
    drop(traceOpcodes);
    drop(traceArena);
  }
}
