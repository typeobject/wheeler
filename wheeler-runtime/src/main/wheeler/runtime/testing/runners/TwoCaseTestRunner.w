//! Runs two transported test descriptors under canonical runtime policy.

module wheeler.runtime.testing.runners.two_case_test_runner;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.runtime.testing.test_artifact_report;
import wheeler.runtime.testing.test_case_identity;
import wheeler.runtime.testing.test_identity_text;
import wheeler.runtime.testing.test_report_identity;
import wheeler.runtime.testing.test_shard;
import wheeler.runtime.testing.test_summary;

classical class TwoCaseTestRunner {
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

  /// Runs, reduces, and writes one two-case identity and summary product.
  public long runTwoCaseTests(borrow byteview input, borrow mut bytes output) {
    assert(19 < bufferLength(input));
    long cursor = 4;
    long packageLength = input[cursor];
    assert(0 < packageLength);
    cursor += 1;
    assert(cursor + packageLength < bufferLength(input));
    long packageStart = cursor;
    cursor += packageLength;
    long versionLength = input[cursor];
    assert(0 < versionLength);
    cursor += 1;
    assert(cursor + versionLength < bufferLength(input));
    long versionStart = cursor;
    cursor += versionLength;
    long targetLength = input[cursor];
    assert(0 < targetLength);
    cursor += 1;
    assert(cursor + targetLength + 36 < bufferLength(input));
    long targetStart = cursor;
    cursor += targetLength;

    long firstDeclarationStart = cursor;
    cursor += 32;
    long firstNameLength = input[cursor];
    assert(0 < firstNameLength);
    cursor += 1;
    assert(cursor + firstNameLength + 7 < bufferLength(input));
    long firstNameStart = cursor;
    cursor += firstNameLength;
    long firstSourceLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < firstSourceLength);
    assert(firstSourceLength < 32769);
    cursor += 4;
    assert(cursor + firstSourceLength + 3 < bufferLength(input));
    long firstSourceStart = cursor;
    cursor += firstSourceLength;
    long firstLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(firstLength < 32769);
    cursor += 4;
    assert(cursor + firstLength + 36 < bufferLength(input));
    long firstArtifactStart = cursor;
    cursor += firstLength;

    long secondDeclarationStart = cursor;
    cursor += 32;
    long secondNameLength = input[cursor];
    assert(0 < secondNameLength);
    cursor += 1;
    assert(cursor + secondNameLength + 7 < bufferLength(input));
    long secondNameStart = cursor;
    cursor += secondNameLength;
    long secondSourceLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < secondSourceLength);
    assert(secondSourceLength < 32769);
    cursor += 4;
    assert(cursor + secondSourceLength + 3 < bufferLength(input));
    long secondSourceStart = cursor;
    cursor += secondSourceLength;
    long secondLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(secondLength < 32769);
    cursor += 4;
    assert(cursor + secondLength == bufferLength(input));
    long secondArtifactStart = cursor;

    region staging = new region(/* bytes= */ 90914, /* allocations= */ 30);
    bytes firstArtifact = allocateBytes(staging, firstLength);
    long firstCopied = copyRange(
      input,
      firstArtifactStart,
      firstLength,
      firstArtifact,
      /* outputStart= */ 0
    );
    assert(firstCopied == firstLength);
    bytes secondArtifact = allocateBytes(staging, secondLength);
    long secondCopied = copyRange(
      input,
      secondArtifactStart,
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
    bytes packageName = allocateBytes(staging, packageLength);
    long metadataCopied = copyRange(
      input,
      packageStart,
      packageLength,
      packageName,
      /* outputStart= */ 0
    );
    assert(metadataCopied == packageLength);
    bytes packageVersion = allocateBytes(staging, versionLength);
    metadataCopied = copyRange(
      input,
      versionStart,
      versionLength,
      packageVersion,
      /* outputStart= */ 0
    );
    assert(metadataCopied == versionLength);
    bytes target = allocateBytes(staging, targetLength);
    metadataCopied = copyRange(input, targetStart, targetLength, target, /* outputStart= */ 0);
    assert(metadataCopied == targetLength);

    bytes firstRawSource = allocateBytes(staging, /* length= */ 32);
    hashSha256Range(input, firstSourceStart, firstSourceLength, firstRawSource, staging);
    bytes firstSource = allocateBytes(staging, /* length= */ 64);
    long firstSourceTextLength = writeTestIdentityText(firstRawSource, firstSource);
    assert(firstSourceTextLength == 64);
    bytes secondRawSource = allocateBytes(staging, /* length= */ 32);
    hashSha256Range(input, secondSourceStart, secondSourceLength, secondRawSource, staging);
    bytes secondSource = allocateBytes(staging, /* length= */ 64);
    long secondSourceTextLength = writeTestIdentityText(secondRawSource, secondSource);
    assert(secondSourceTextLength == 64);

    bytes rawDeclaration = allocateBytes(staging, /* length= */ 32);
    metadataCopied = copyRange(
      input,
      firstDeclarationStart,
      /* length= */ 32,
      rawDeclaration,
      /* outputStart= */ 0
    );
    assert(metadataCopied == 32);
    bytes firstCaseInput = allocateBytes(staging, 130 + firstNameLength);
    long declarationLength = writeTestIdentityTextAt(
      rawDeclaration,
      firstCaseInput,
      /* outputStart= */ 0
    );
    assert(declarationLength == 64);
    long copiedSource = copyRange(
      firstSource,
      /* inputStart= */ 0,
      /* length= */ 64,
      firstCaseInput,
      /* outputStart= */ 64
    );
    assert(copiedSource == 128);
    setByte(firstCaseInput, /* index= */ 128, firstNameLength);
    setByte(firstCaseInput, /* index= */ 129, /* nameLengthHigh= */ 0);
    long nameEnd = copyRange(
      input,
      firstNameStart,
      firstNameLength,
      firstCaseInput,
      /* outputStart= */ 130
    );
    assert(nameEnd == bufferLength(firstCaseInput));
    bytes firstRawCase = allocateBytes(staging, /* length= */ 32);
    long rawLength = deriveTestCaseIdentity(firstCaseInput, firstRawCase);
    assert(rawLength == 32);
    bytes firstCase = allocateBytes(staging, /* length= */ 64);
    long firstCaseLength = writeTestIdentityText(firstRawCase, firstCase);
    assert(firstCaseLength == 64);
    metadataCopied = copyRange(
      input,
      secondDeclarationStart,
      /* length= */ 32,
      rawDeclaration,
      /* outputStart= */ 0
    );
    assert(metadataCopied == 32);
    bytes secondCaseInput = allocateBytes(staging, 130 + secondNameLength);
    declarationLength = writeTestIdentityTextAt(
      rawDeclaration,
      secondCaseInput,
      /* outputStart= */ 0
    );
    assert(declarationLength == 64);
    copiedSource = copyRange(
      secondSource,
      /* inputStart= */ 0,
      /* length= */ 64,
      secondCaseInput,
      /* outputStart= */ 64
    );
    assert(copiedSource == 128);
    setByte(secondCaseInput, /* index= */ 128, secondNameLength);
    setByte(secondCaseInput, /* index= */ 129, /* nameLengthHigh= */ 0);
    nameEnd = copyRange(
      input,
      secondNameStart,
      secondNameLength,
      secondCaseInput,
      /* outputStart= */ 130
    );
    assert(nameEnd == bufferLength(secondCaseInput));
    bytes secondRawCase = allocateBytes(staging, /* length= */ 32);
    rawLength = deriveTestCaseIdentity(secondCaseInput, secondRawCase);
    assert(rawLength == 32);
    bytes secondCase = allocateBytes(staging, /* length= */ 64);
    long secondCaseLength = writeTestIdentityText(secondRawCase, secondCase);
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
        secondResult
      );
    }

    long frameLength = 68 + firstResultLength + secondResultLength;
    bytes frame = allocateBytes(staging, frameLength);
    long reportCursor = writeField(runner, frame, /* cursor= */ 0);
    long caseCount = 0;
    if (firstSelected) {
      caseCount += 1;
    }

    if (secondSelected) {
      caseCount += 1;
    }

    setByte(frame, reportCursor, caseCount);
    setByte(frame, reportCursor + 1, /* caseCountHigh= */ 0);
    reportCursor += 2;
    if (firstSelected) {
      reportCursor = copyRange(
        firstResult,
        /* inputStart= */ 0,
        firstResultLength,
        frame,
        reportCursor
      );
    }

    if (secondSelected) {
      reportCursor = copyRange(
        secondResult,
        /* inputStart= */ 0,
        secondResultLength,
        frame,
        reportCursor
      );
    }

    assert(reportCursor == frameLength);
    assert(bufferLength(output) == 39);
    bytes reportIdentity = allocateBytes(staging, /* length= */ 32);
    long reportLength = deriveTestReportIdentity(frame, reportIdentity);
    assert(reportLength == 32);
    bytes summaryInput = allocateBytes(staging, 2 + caseCount * 33);
    setByte(summaryInput, /* index= */ 0, caseCount);
    setByte(summaryInput, /* index= */ 1, /* caseCountHigh= */ 0);
    long summaryCursor = 2;
    if (firstSelected) {
      summaryCursor = copyRange(
        firstRawCase,
        /* inputStart= */ 0,
        /* length= */ 32,
        summaryInput,
        summaryCursor
      );
      setByte(summaryInput, summaryCursor, /* pass= */ 0);
      summaryCursor += 1;
    }

    if (secondSelected) {
      summaryCursor = copyRange(
        secondRawCase,
        /* inputStart= */ 0,
        /* length= */ 32,
        summaryInput,
        summaryCursor
      );
      setByte(summaryInput, summaryCursor, /* fail= */ 1);
      summaryCursor += 1;
    }

    assert(summaryCursor == bufferLength(summaryInput));
    bytes summary = allocateBytes(staging, /* length= */ 7);
    long summaryLength = reduceTestSummary(summaryInput, summary);
    assert(summaryLength == 7);
    long published = copyRange(
      reportIdentity,
      /* inputStart= */ 0,
      /* length= */ 32,
      output,
      /* outputStart= */ 0
    );
    published = copyRange(summary, /* inputStart= */ 0, /* length= */ 7, output, published);
    assert(published == 39);

    drop(summary);
    drop(summaryInput);
    drop(reportIdentity);
    drop(frame);
    drop(secondResult);
    drop(firstResult);
    drop(shardInput);
    drop(secondCase);
    drop(firstCase);
    drop(secondRawCase);
    drop(firstRawCase);
    drop(secondCaseInput);
    drop(firstCaseInput);
    drop(rawDeclaration);
    drop(secondSource);
    drop(secondRawSource);
    drop(firstSource);
    drop(firstRawSource);
    drop(target);
    drop(packageVersion);
    drop(packageName);
    drop(runner);
    drop(secondArtifact);
    drop(firstArtifact);
    drop(staging);
    return published;
  }
}
