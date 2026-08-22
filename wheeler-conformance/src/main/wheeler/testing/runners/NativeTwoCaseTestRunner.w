//! Executes two bounded artifacts and publishes one canonical profile-2 report identity.

module wheeler.conformance.testing.runners.native_two_case_test_runner;

import wheeler.core.encoding.binary;
import wheeler.runtime.testing.test_artifact_report;
import wheeler.runtime.testing.test_case_identity;
import wheeler.runtime.testing.test_identity_text;
import wheeler.runtime.testing.test_report_identity;
import wheeler.runtime.testing.test_shard;

classical class NativeTwoCaseTestRunner {
  private long copyRange(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit 32768 {
      setByte(output, outputStart + offset, input[inputStart + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  private long writeField(borrow byteview input, borrow mut bytes output, long cursor) {
    long length = bufferLength(input);
    setByte(output, cursor, length % 256);
    setByte(output, cursor + 1, length / 256);
    return copyRange(input, /* inputStart= */ 0, length, output, cursor + 2);
  }

  entry void main(borrow byteview input, borrow mut bytes output) {
    assert(11 < bufferLength(input));
    long firstLength = readUnsigned(input, /* offset= */ 4, /* width= */ 4);
    assert(firstLength < 32769);
    assert(firstLength < bufferLength(input) - 11);
    long secondHeader = 8 + firstLength;
    long secondLength = readUnsigned(input, secondHeader, /* width= */ 4);
    assert(secondLength < 32769);
    assert(secondHeader + 4 + secondLength == bufferLength(input));

    region staging = new region(/* bytes= */ 88234, /* allocations= */ 18);
    bytes firstArtifact = allocateBytes(staging, firstLength);
    long firstCopied = copyRange(
      input,
      /* inputStart= */ 8,
      firstLength,
      firstArtifact,
      /* outputStart= */ 0
    );
    assert(firstCopied == firstLength);
    bytes secondArtifact = allocateBytes(staging, secondLength);
    long secondCopied = copyRange(
      input,
      secondHeader + 4,
      secondLength,
      secondArtifact,
      /* outputStart= */ 0
    );
    assert(secondCopied == secondLength);
    bytes runner = allocateBytes(staging, /* length= */ 64);
    writeAscii(
      runner,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000001"
    );
    bytes packageName = allocateBytes(staging, /* length= */ 3);
    writeAscii(packageName, /* offset= */ 0, "pkg");
    bytes packageVersion = allocateBytes(staging, /* length= */ 1);
    writeAscii(packageVersion, /* offset= */ 0, "1");
    bytes target = allocateBytes(staging, /* length= */ 4);
    writeAscii(target, /* offset= */ 0, "test");
    bytes firstSource = allocateBytes(staging, /* length= */ 64);
    writeAscii(
      firstSource,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000005"
    );
    bytes secondSource = allocateBytes(staging, /* length= */ 64);
    writeAscii(
      secondSource,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000003"
    );
    bytes caseInput = allocateBytes(staging, /* length= */ 134);
    writeAscii(
      caseInput,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000006"
    );
    long copiedSource = copyRange(
      firstSource,
      /* inputStart= */ 0,
      /* length= */ 64,
      caseInput,
      /* outputStart= */ 64
    );
    assert(copiedSource == 128);
    setByte(caseInput, /* index= */ 128, /* nameLengthLow= */ 4);
    setByte(caseInput, /* index= */ 129, /* nameLengthHigh= */ 0);
    writeAscii(caseInput, /* offset= */ 130, "test");
    bytes rawCase = allocateBytes(staging, /* length= */ 32);
    long rawLength = deriveTestCaseIdentity(caseInput, rawCase);
    assert(rawLength == 32);
    bytes firstCase = allocateBytes(staging, /* length= */ 64);
    long firstCaseLength = writeTestIdentityText(rawCase, firstCase);
    assert(firstCaseLength == 64);
    copiedSource = copyRange(
      secondSource,
      /* inputStart= */ 0,
      /* length= */ 64,
      caseInput,
      /* outputStart= */ 64
    );
    assert(copiedSource == 128);
    rawLength = deriveTestCaseIdentity(caseInput, rawCase);
    assert(rawLength == 32);
    bytes secondCase = allocateBytes(staging, /* length= */ 64);
    long secondCaseLength = writeTestIdentityText(rawCase, secondCase);
    assert(secondCaseLength == 64);
    bytes shardInput = allocateBytes(staging, /* length= */ 68);
    long shardCursor = copyRange(
      firstCase,
      /* inputStart= */ 0,
      /* length= */ 64,
      shardInput,
      /* outputStart= */ 0
    );
    assert(shardCursor == 64);
    setByte(shardInput, /* index= */ 64, input[0]);
    setByte(shardInput, /* index= */ 65, input[1]);
    setByte(shardInput, /* index= */ 66, input[2]);
    setByte(shardInput, /* index= */ 67, input[3]);
    boolean firstSelected = assignedToShard(shardInput);
    shardCursor = copyRange(
      secondCase,
      /* inputStart= */ 0,
      /* length= */ 64,
      shardInput,
      /* outputStart= */ 0
    );
    assert(shardCursor == 64);
    boolean secondSelected = assignedToShard(shardInput);
    bytes failureCode = allocateBytes(staging, /* length= */ 8);
    writeAscii(failureCode, /* offset= */ 0, "WTEST003");
    bytes failureMessage = allocateBytes(staging, /* length= */ 28);
    writeAscii(failureMessage, /* offset= */ 0, "native test assertion failed");
    bytes firstResult = allocateBytes(staging, /* length= */ 5345);
    long firstResultLength = 0;
    if (firstSelected) {
      firstResultLength = writeArtifactCaseResult(
        firstArtifact,
        packageName,
        packageVersion,
        target,
        firstCase,
        firstSource,
        failureCode,
        failureMessage,
        firstResult
      );
    }

    bytes secondResult = allocateBytes(staging, /* length= */ 5345);
    long secondResultLength = 0;
    if (secondSelected) {
      secondResultLength = writeArtifactCaseResult(
        secondArtifact,
        packageName,
        packageVersion,
        target,
        secondCase,
        secondSource,
        failureCode,
        failureMessage,
        secondResult
      );
    }

    long frameLength = 68 + firstResultLength + secondResultLength;
    bytes frame = allocateBytes(staging, frameLength);
    long cursor = writeField(runner, frame, /* cursor= */ 0);
    long caseCount = 0;
    if (firstSelected) {
      caseCount += 1;
    }

    if (secondSelected) {
      caseCount += 1;
    }

    setByte(frame, cursor, caseCount);
    setByte(frame, cursor + 1, /* caseCountHigh= */ 0);
    cursor += 2;
    if (firstSelected) {
      cursor = copyRange(firstResult, /* inputStart= */ 0, firstResultLength, frame, cursor);
    }

    if (secondSelected) {
      cursor = copyRange(secondResult, /* inputStart= */ 0, secondResultLength, frame, cursor);
    }

    assert(cursor == frameLength);
    long length = deriveTestReportIdentity(frame, output);
    setOutputLength(output, length);

    drop(frame);
    drop(secondResult);
    drop(firstResult);
    drop(failureMessage);
    drop(shardInput);
    drop(failureCode);
    drop(secondCase);
    drop(firstCase);
    drop(rawCase);
    drop(caseInput);
    drop(secondSource);
    drop(firstSource);
    drop(target);
    drop(packageVersion);
    drop(packageName);
    drop(runner);
    drop(secondArtifact);
    drop(firstArtifact);
    drop(staging);
  }
}
