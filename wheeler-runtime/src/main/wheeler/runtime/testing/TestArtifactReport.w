//! Executes bounded classical artifacts and constructs canonical profile-2 case results.

module wheeler.runtime.testing.test_artifact_report;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.runtime.artifact_execution;
import wheeler.runtime.bootstrap_coverage_fragments;
import wheeler.runtime.coverage_reducer;
import wheeler.runtime.testing.test_artifact_execution_identity;
import wheeler.runtime.testing.test_coverage_identity;
import wheeler.runtime.testing.test_identity_text;
import wheeler.runtime.testing.test_report_identity;

classical class TestArtifactReport {
  private const long CASE_RESULT_BYTES = 5345;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_DIAGNOSTIC_BYTES = 4096;
  private const long MAX_METADATA_BYTES = 255;
  private const long PASS_STAGING_BYTES = 66720;
  private const long REPORT_FRAME_BYTES = 5413;

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

  private long copyRange(
    borrow byteview input,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    long offset = 0;
    while (offset < length) limit CASE_RESULT_BYTES {
      setByte(output, cursor + offset, input[offset]);
      offset += 1;
    }

    return cursor + length;
  }

  private long writeIdentity(borrow byteview identity, borrow mut bytes frame, long cursor) {
    assert(bufferLength(identity) == IDENTITY_BYTES);
    setByte(frame, cursor, /* lengthLow= */ 64);
    setByte(frame, cursor + 1, /* lengthHigh= */ 0);
    cursor += 2;
    return writeTestIdentityTextAt(identity, frame, cursor);
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

  private void validateMetadata(
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity
  ) {
    assert(bufferLength(packageName) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(packageVersion) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(targetName) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(caseIdentity) == 64);
    assert(bufferLength(sourceIdentity) == 64);
  }

  private long countAssertions(borrow byteview trace, long steps) {
    long assertions = 0;
    long step = 0;
    while (step < steps) limit MAX_INTERPRETED_STEPS {
      long opcode = trace[step * 2] + trace[step * 2 + 1] * 256;
      if (opcode == OPCODE_EXPECT_TRUE) {
        assertions += 1;
      }

      if (opcode == OPCODE_EXPECT_EQ) {
        assertions += 1;
      }

      step += 1;
    }

    return assertions;
  }

  private long writePassingCaseResult(
    borrow byteview artifact,
    ArtifactOutcome outcome,
    borrow byteview trace,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity,
    borrow mut bytes output
  ) {
    assert(outcome.passed);
    region staging = new region(/* bytes= */ PASS_STAGING_BYTES, /* allocations= */ 8);
    bytes artifactIdentity = allocateBytes(staging, IDENTITY_BYTES);
    hashSha256(artifact, artifactIdentity, staging);
    bytes executionIdentity = allocateBytes(staging, IDENTITY_BYTES);
    long executionLength = deriveArtifactExecutionIdentity(artifact, outcome, executionIdentity);
    assert(executionLength == IDENTITY_BYTES);

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

    long cursor = writeField(packageName, output, /* cursor= */ 0);
    cursor = writeField(packageVersion, output, cursor);
    cursor = writeField(targetName, output, cursor);
    cursor = writeField(caseIdentity, output, cursor);
    cursor = writeField(sourceIdentity, output, cursor);
    cursor = writeIdentity(artifactIdentity, output, cursor);
    setByte(output, cursor, /* diagnosticCodeLengthLow= */ 0);
    setByte(output, cursor + 1, /* diagnosticCodeLengthHigh= */ 0);
    setByte(output, cursor + 2, /* diagnosticMessageLengthLow= */ 0);
    setByte(output, cursor + 3, /* diagnosticMessageLengthHigh= */ 0);
    cursor += 4;
    cursor = writeIdentity(executionIdentity, output, cursor);
    cursor = writeIdentity(coverageIdentity, output, cursor);
    setByte(output, cursor, /* pass= */ 0);
    cursor += 1;
    cursor = writeSigned(countAssertions(trace, outcome.steps), output, cursor);
    cursor = writeSigned(/* workflowSteps= */ 0, output, cursor);

    drop(coverageIdentity);
    drop(coverageReport);
    drop(fragments);
    drop(executionIdentity);
    drop(artifactIdentity);
    drop(staging);
    return cursor;
  }

  private long writeFailedCaseResult(
    borrow byteview artifact,
    ArtifactOutcome outcome,
    borrow byteview trace,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity,
    borrow byteview diagnosticCode,
    borrow byteview diagnosticMessage,
    borrow mut bytes output
  ) {
    assert(!outcome.passed);
    assert(0 < bufferLength(diagnosticCode));
    assert(bufferLength(diagnosticCode) < MAX_METADATA_BYTES + 1);
    assert(bufferLength(diagnosticMessage) < MAX_DIAGNOSTIC_BYTES + 1);
    region staging = new region(/* bytes= */ 1120, /* allocations= */ 4);
    bytes artifactIdentity = allocateBytes(staging, IDENTITY_BYTES);
    hashSha256(artifact, artifactIdentity, staging);

    long cursor = writeField(packageName, output, /* cursor= */ 0);
    cursor = writeField(packageVersion, output, cursor);
    cursor = writeField(targetName, output, cursor);
    cursor = writeField(caseIdentity, output, cursor);
    cursor = writeField(sourceIdentity, output, cursor);
    cursor = writeIdentity(artifactIdentity, output, cursor);
    cursor = writeField(diagnosticCode, output, cursor);
    cursor = writeField(diagnosticMessage, output, cursor);
    setByte(output, cursor, /* executionIdentityLengthLow= */ 0);
    setByte(output, cursor + 1, /* executionIdentityLengthHigh= */ 0);
    setByte(output, cursor + 2, /* coverageIdentityLengthLow= */ 0);
    setByte(output, cursor + 3, /* coverageIdentityLengthHigh= */ 0);
    cursor += 4;
    setByte(output, cursor, /* fail= */ 1);
    cursor += 1;
    cursor = writeSigned(countAssertions(trace, outcome.steps), output, cursor);
    cursor = writeSigned(/* workflowSteps= */ 0, output, cursor);

    drop(artifactIdentity);
    drop(staging);
    return cursor;
  }

  /// Executes one artifact and writes its complete counted-report case row.
  public long writeArtifactCaseResult(
    borrow byteview artifact,
    borrow byteview packageName,
    borrow byteview packageVersion,
    borrow byteview targetName,
    borrow byteview caseIdentity,
    borrow byteview sourceIdentity,
    borrow byteview failureCode,
    borrow byteview failureMessage,
    borrow mut bytes output
  ) {
    validateMetadata(packageName, packageVersion, targetName, caseIdentity, sourceIdentity);
    assert(bufferLength(output) == CASE_RESULT_BYTES);
    region execution = new region(/* bytes= */ 32768, /* allocations= */ 1);
    bytes trace = allocateBytes(execution, MAX_INTERPRETED_STEPS * 2);
    ArtifactOutcome outcome = executeBoundedArtifact(artifact, trace);
    long length = 0;
    if (outcome.passed) {
      length = writePassingCaseResult(
        artifact,
        outcome,
        trace,
        packageName,
        packageVersion,
        targetName,
        caseIdentity,
        sourceIdentity,
        output
      );
    } else {
      length = writeFailedCaseResult(
        artifact,
        outcome,
        trace,
        packageName,
        packageVersion,
        targetName,
        caseIdentity,
        sourceIdentity,
        failureCode,
        failureMessage,
        output
      );
    }

    assert(length < CASE_RESULT_BYTES + 1);
    drop(trace);
    drop(execution);
    return length;
  }

  /// Executes one artifact and reduces its one-case semantic report identity.
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
    assert(bufferLength(runnerIdentity) == 64);
    assert(bufferLength(output) == IDENTITY_BYTES);
    region framing = new region(/* bytes= */ 10758, /* allocations= */ 2);
    bytes caseResult = allocateBytes(framing, CASE_RESULT_BYTES);
    long caseLength = writeArtifactCaseResult(
      artifact,
      packageName,
      packageVersion,
      targetName,
      caseIdentity,
      sourceIdentity,
      failureCode,
      failureMessage,
      caseResult
    );
    long frameLength = 68 + caseLength;
    assert(frameLength < REPORT_FRAME_BYTES + 1);
    bytes frame = allocateBytes(framing, frameLength);
    long cursor = writeField(runnerIdentity, frame, /* cursor= */ 0);
    setByte(frame, cursor, /* caseCountLow= */ 1);
    setByte(frame, cursor + 1, /* caseCountHigh= */ 0);
    cursor += 2;
    cursor = copyRange(caseResult, caseLength, frame, cursor);
    assert(cursor == frameLength);
    long length = deriveTestReportIdentity(frame, output);
    drop(frame);
    drop(caseResult);
    drop(framing);
    return length;
  }
}
