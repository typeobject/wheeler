//! Classifies one bounded artifact through the Wheeler-owned test execution seam.

module wheeler.conformance.testing.native_test_artifact_run;

import wheeler.compiler.opcodes;
import wheeler.runtime.artifact_execution;

classical class NativeTestArtifactRun {
  private void writeLong(long value, borrow mut bytes output, long cursor) {
    long remaining = value;
    long offset = 0;
    while (offset < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(output, cursor + offset, octet);
      remaining = (remaining - octet) / 256;
      offset += 1;
    }
  }

  /// Publishes one complete closed interpreter outcome for a runner-owned artifact.
  entry void main(borrow byteview artifact, borrow mut bytes output) {
    assert(bufferLength(output) == 89);
    region traceArena = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes traceOpcodes = allocateBytes(traceArena, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, traceOpcodes);
    if (outcome.passed) {
      setByte(output, /* index= */ 0, /* value= */ 0);
    } else {
      setByte(output, /* index= */ 0, /* value= */ 1);
    }

    writeLong(outcome.steps, output, /* cursor= */ 1);
    writeLong(outcome.globalCount, output, /* cursor= */ 9);
    writeLong(outcome.globalZero, output, /* cursor= */ 17);
    writeLong(outcome.globalOne, output, /* cursor= */ 25);
    writeLong(outcome.globalTwo, output, /* cursor= */ 33);
    writeLong(outcome.globalThree, output, /* cursor= */ 41);
    writeLong(outcome.globalFour, output, /* cursor= */ 49);
    writeLong(outcome.globalFive, output, /* cursor= */ 57);
    writeLong(outcome.globalSix, output, /* cursor= */ 65);
    writeLong(outcome.globalSeven, output, /* cursor= */ 73);
    writeLong(outcome.errorOffset, output, /* cursor= */ 81);
    drop(traceOpcodes);
    drop(traceArena);
  }
}
