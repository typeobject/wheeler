//! Derives one profile-2 execution identity from a native artifact outcome.

module wheeler.runtime.testing.test_artifact_execution_identity;

import wheeler.runtime.artifact_execution;
import wheeler.runtime.artifact_metadata;
import wheeler.runtime.testing.test_execution_identity;

classical class TestArtifactExecutionIdentity {
  private const long FRAME_BYTES = 2396;

  private long writeText(
    borrow byteview artifact,
    ArtifactText text,
    borrow mut bytes frame,
    long cursor
  ) {
    setByte(frame, cursor, text.length % 256);
    setByte(frame, cursor + 1, text.length / 256);
    cursor += 2;
    long offset = 0;
    while (offset < text.length) limit 255 {
      setByte(frame, cursor + offset, artifact[text.start + offset]);
      offset += 1;
    }

    return cursor + text.length;
  }

  private long writeSigned(long value, borrow mut bytes frame, long cursor) {
    long remaining = value;
    long offset = 0;
    while (offset < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(frame, cursor + offset, octet);
      remaining = (remaining - octet) / 256;
      offset += 1;
    }

    return cursor + 8;
  }

  private long globalValue(ArtifactOutcome outcome, long global) {
    if (global == 0) {
      return outcome.globalZero;
    }

    if (global == 1) {
      return outcome.globalOne;
    }

    if (global == 2) {
      return outcome.globalTwo;
    }

    if (global == 3) {
      return outcome.globalThree;
    }

    if (global == 4) {
      return outcome.globalFour;
    }

    if (global == 5) {
      return outcome.globalFive;
    }

    if (global == 6) {
      return outcome.globalSix;
    }

    assert(global == 7);
    return outcome.globalSeven;
  }

  /// Writes the profile-2 identity for one successful native classical execution.
  public long deriveArtifactExecutionIdentity(
    borrow byteview artifact,
    ArtifactOutcome outcome,
    borrow mut bytes output
  ) {
    assert(outcome.passed);
    assert(outcome.globalCount < 9);
    ArtifactText program = artifactProgramText(artifact);
    assert(program.length < 256);
    long kind = artifactProgramKind(artifact);
    assert(kind < 3);
    assert(artifactGlobalCount(artifact) == outcome.globalCount);

    long frameLength = 21 + program.length;
    long global = 0;
    while (global < outcome.globalCount) limit 8 {
      ArtifactText sizedName = artifactGlobalText(artifact, global);
      assert(sizedName.length < 256);
      frameLength += 10 + sizedName.length;
      global += 1;
    }

    assert(frameLength < FRAME_BYTES + 1);
    region framing = new region(/* bytes= */ FRAME_BYTES, /* allocations= */ 1);
    bytes frame = allocateBytes(framing, frameLength);
    long cursor = writeText(artifact, program, frame, /* cursor= */ 0);
    setByte(frame, cursor, kind);
    cursor += 1;
    setByte(frame, cursor, outcome.globalCount);
    setByte(frame, cursor + 1, /* value= */ 0);
    cursor += 2;
    global = 0;
    while (global < outcome.globalCount) limit 8 {
      ArtifactText name = artifactGlobalText(artifact, global);
      assert(name.length < 256);
      cursor = writeText(artifact, name, frame, cursor);
      cursor = writeSigned(globalValue(outcome, global), frame, cursor);
      global += 1;
    }

    setByte(frame, cursor, /* measurementCountLow= */ 0);
    setByte(frame, cursor + 1, /* measurementCountHigh= */ 0);
    setByte(frame, cursor + 2, /* jobCountLow= */ 0);
    setByte(frame, cursor + 3, /* jobCountHigh= */ 0);
    cursor += 4;
    cursor = writeSigned(/* workflowSteps= */ 0, frame, cursor);
    setByte(frame, cursor, /* outputLength0= */ 0);
    setByte(frame, cursor + 1, /* outputLength1= */ 0);
    setByte(frame, cursor + 2, /* outputLength2= */ 0);
    setByte(frame, cursor + 3, /* outputLength3= */ 0);
    cursor += 4;
    assert(cursor == frameLength);
    long length = deriveTestExecutionIdentity(frame, output);
    drop(frame);
    drop(framing);
    return length;
  }
}
