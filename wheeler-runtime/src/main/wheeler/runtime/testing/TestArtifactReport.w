//! Executes one bounded classical artifact and derives its passing profile-2 report.

module wheeler.runtime.testing.test_artifact_report;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.runtime.artifact_execution;
import wheeler.runtime.bootstrap_coverage_fragments;
import wheeler.runtime.coverage_reducer;
import wheeler.runtime.testing.test_artifact_execution_identity;
import wheeler.runtime.testing.test_coverage_identity;
import wheeler.runtime.testing.test_report_identity;

classical class TestArtifactReport {
  private const long IDENTITY_BYTES = 32;
  private const long MAX_DIAGNOSTIC_BYTES = 4096;
  private const long MAX_METADATA_BYTES = 255;
  private const long REPORT_FRAME_BYTES = 5413;
  private const long STAGING_BYTES = 105223;

  private long sectionOffset(borrow byteview artifact, long section) {
    return readUnsigned(artifact, 40 + section * 32 + 8, /* width= */ 8);
  }

  private long entryFunction(borrow byteview artifact) {
    long manifest = sectionOffset(artifact, /* section= */ 0);
    return readUnsigned(artifact, manifest + 4, /* width= */ 4);
  }

  private long writeField(borrow byteview value, borrow mut bytes frame, long cursor) {
    long length = bufferLength(value);
    assert(length < MAX_DIAGNOSTIC_BYTES + 1);
    setByte(frame, cursor, length % 256);
    setByte(frame, cursor + 1, length / 256);
    cursor += 2;
    long offset = 0;
    while (offset < length) limit MAX_DIAGNOSTIC_BYTES {
      setByte(frame, cursor + offset, value[offset]);
      offset += 1;
    }

    return cursor + length;
  }

  private long hexDigit(long value) {
    if (value < 10) {
      return value + 48;
    }

    return value + 87;
  }

  private long writeIdentity(borrow byteview identity, borrow mut bytes frame, long cursor) {
    assert(bufferLength(identity) == IDENTITY_BYTES);
    setByte(frame, cursor, /* lengthLow= */ 64);
    setByte(frame, cursor + 1, /* lengthHigh= */ 0);
    cursor += 2;
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long value = identity[offset];
      setByte(frame, cursor + offset * 2, hexDigit(value / 16));
      setByte(frame, cursor + offset * 2 + 1, hexDigit(value % 16));
      offset += 1;
    }

    return cursor + 64;
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

  private long derivePassingArtifactOutcomeReportIdentity(
    borrow byteview artifact,
    ArtifactOutcome outcome,
    borrow byteview trace,
    borrow byteview runnerIdentity,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity,
    borrow mut bytes output
  ) {
    assert(bufferLength(runnerIdentity) == 64);
    assert(bufferLength(packageName) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(packageVersion) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(targetName) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(caseIdentity) == 64);
    assert(bufferLength(sourceIdentity) == 64);
    assert(bufferLength(output) == IDENTITY_BYTES);

    assert(outcome.passed);
    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 9);
    bytes artifactIdentity = allocateBytes(staging, IDENTITY_BYTES);
    hashSha256(artifact, artifactIdentity, staging);
    bytes executionIdentity = allocateBytes(staging, IDENTITY_BYTES);
    long executionIdentityLength = deriveArtifactExecutionIdentity(
      artifact,
      outcome,
      executionIdentity
    );
    assert(executionIdentityLength == IDENTITY_BYTES);

    long function = entryFunction(artifact);
    long fragmentLength = measuredTransitionFragments(trace, outcome.steps, function);
    bytes fragments = allocateBytes(staging, /* length= */ 32768);
    writeTransitionFragments(trace, outcome.steps, function, fragments);
    bytes coverageReport = allocateBytes(staging, /* length= */ 32768);
    long coverageLength = reduceRange(fragments, fragmentLength, coverageReport);
    bytes coverageIdentity = allocateBytes(staging, IDENTITY_BYTES);
    long coverageIdentityLength = deriveTestCoverageIdentityRange(
      coverageReport,
      coverageLength,
      coverageIdentity
    );
    assert(coverageIdentityLength == IDENTITY_BYTES);

    long assertions = 0;
    long step = 0;
    while (step < outcome.steps) limit MAX_INTERPRETED_STEPS {
      long opcode = trace[step * 2] + trace[step * 2 + 1] * 256;
      if (opcode == OPCODE_EXPECT_TRUE) {
        assertions += 1;
      }

      if (opcode == OPCODE_EXPECT_EQ) {
        assertions += 1;
      }

      step += 1;
    }

    long frameLength = 233 + bufferLength(runnerIdentity) + bufferLength(packageName)
      + bufferLength(
      packageVersion
    ) + bufferLength(targetName) + bufferLength(caseIdentity) + bufferLength(sourceIdentity);
    assert(frameLength < REPORT_FRAME_BYTES + 1);
    bytes frame = allocateBytes(staging, frameLength);
    long cursor = writeField(runnerIdentity, frame, /* cursor= */ 0);
    setByte(frame, cursor, /* caseCountLow= */ 1);
    setByte(frame, cursor + 1, /* caseCountHigh= */ 0);
    cursor += 2;
    cursor = writeField(packageName, frame, cursor);
    cursor = writeField(packageVersion, frame, cursor);
    cursor = writeField(targetName, frame, cursor);
    cursor = writeField(caseIdentity, frame, cursor);
    cursor = writeField(sourceIdentity, frame, cursor);
    cursor = writeIdentity(artifactIdentity, frame, cursor);
    setByte(frame, cursor, /* diagnosticCodeLengthLow= */ 0);
    setByte(frame, cursor + 1, /* diagnosticCodeLengthHigh= */ 0);
    setByte(frame, cursor + 2, /* diagnosticMessageLengthLow= */ 0);
    setByte(frame, cursor + 3, /* diagnosticMessageLengthHigh= */ 0);
    cursor += 4;
    cursor = writeIdentity(executionIdentity, frame, cursor);
    cursor = writeIdentity(coverageIdentity, frame, cursor);
    setByte(frame, cursor, /* pass= */ 0);
    cursor += 1;
    cursor = writeSigned(assertions, frame, cursor);
    cursor = writeSigned(/* workflowSteps= */ 0, frame, cursor);
    assert(cursor == frameLength);
    long length = deriveTestReportIdentity(frame, output);

    drop(frame);
    drop(coverageIdentity);
    drop(coverageReport);
    drop(fragments);
    drop(executionIdentity);
    drop(artifactIdentity);
    drop(staging);
    return length;
  }

  /// Executes and reduces one classical artifact into a semantic report identity.
  public long deriveArtifactReportIdentity(
    borrow byteview artifact,
    borrow byteview runnerIdentity,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity,
    borrow byteview failureCode,
    borrow byteview failureMessage,
    borrow mut bytes output
  ) {
    region execution = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes trace = allocateBytes(execution, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, trace);
    long length = 0;
    if (outcome.passed) {
      length = derivePassingArtifactOutcomeReportIdentity(
        artifact,
        outcome,
        trace,
        runnerIdentity,
        packageName,
        packageVersion,
        targetName,
        caseIdentity,
        sourceIdentity,
        output
      );
    } else {
      long assertions = 0;
      long step = 0;
      while (step < outcome.steps) limit MAX_INTERPRETED_STEPS {
        long opcode = trace[step * 2] + trace[step * 2 + 1] * 256;
        if (opcode == OPCODE_EXPECT_TRUE) {
          assertions += 1;
        }

        if (opcode == OPCODE_EXPECT_EQ) {
          assertions += 1;
        }

        step += 1;
      }

      length = deriveFailedArtifactReportIdentity(
        artifact,
        outcome,
        runnerIdentity,
        packageName,
        packageVersion,
        targetName,
        caseIdentity,
        sourceIdentity,
        failureCode,
        failureMessage,
        assertions,
        output
      );
    }

    drop(trace);
    drop(execution);
    return length;
  }

  /// Reduces one failed artifact outcome into a semantic report identity.
  public long deriveFailedArtifactReportIdentity(
    borrow byteview artifact,
    ArtifactOutcome outcome,
    borrow byteview runnerIdentity,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity,
    borrow byteview diagnosticCode,
    borrow byteview diagnosticMessage,
    long assertions,
    borrow mut bytes output
  ) {
    assert(!outcome.passed);
    assert(bufferLength(runnerIdentity) == 64);
    assert(bufferLength(packageName) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(packageVersion) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(targetName) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(caseIdentity) == 64);
    assert(bufferLength(sourceIdentity) == 64);
    assert(0 < bufferLength(diagnosticCode));
    assert(bufferLength(diagnosticCode) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(diagnosticMessage) < MAX_DIAGNOSTIC_BYTES + 1);
    assert(-1 < assertions);
    assert(bufferLength(output) == IDENTITY_BYTES);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 5);
    bytes artifactIdentity = allocateBytes(staging, IDENTITY_BYTES);
    hashSha256(artifact, artifactIdentity, staging);
    long frameLength = 105 + bufferLength(runnerIdentity) + bufferLength(packageName)
      + bufferLength(
      packageVersion
    ) + bufferLength(targetName) + bufferLength(caseIdentity) + bufferLength(sourceIdentity)
      + bufferLength(
      diagnosticCode
    ) + bufferLength(diagnosticMessage);
    assert(frameLength < REPORT_FRAME_BYTES + 1);
    bytes frame = allocateBytes(staging, frameLength);
    long cursor = writeField(runnerIdentity, frame, /* cursor= */ 0);
    setByte(frame, cursor, /* caseCountLow= */ 1);
    setByte(frame, cursor + 1, /* caseCountHigh= */ 0);
    cursor += 2;
    cursor = writeField(packageName, frame, cursor);
    cursor = writeField(packageVersion, frame, cursor);
    cursor = writeField(targetName, frame, cursor);
    cursor = writeField(caseIdentity, frame, cursor);
    cursor = writeField(sourceIdentity, frame, cursor);
    cursor = writeIdentity(artifactIdentity, frame, cursor);
    cursor = writeField(diagnosticCode, frame, cursor);
    cursor = writeField(diagnosticMessage, frame, cursor);
    setByte(frame, cursor, /* executionIdentityLengthLow= */ 0);
    setByte(frame, cursor + 1, /* executionIdentityLengthHigh= */ 0);
    setByte(frame, cursor + 2, /* coverageIdentityLengthLow= */ 0);
    setByte(frame, cursor + 3, /* coverageIdentityLengthHigh= */ 0);
    cursor += 4;
    setByte(frame, cursor, /* fail= */ 1);
    cursor += 1;
    cursor = writeSigned(assertions, frame, cursor);
    cursor = writeSigned(/* workflowSteps= */ 0, frame, cursor);
    assert(cursor == frameLength);
    long length = deriveTestReportIdentity(frame, output);
    drop(frame);
    drop(artifactIdentity);
    drop(staging);
    return length;
  }
}
