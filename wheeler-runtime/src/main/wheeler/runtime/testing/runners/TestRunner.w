//! Runs bounded transported test descriptors under canonical runtime policy.

module wheeler.runtime.testing.runners.test_runner;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.runtime.testing.runners.test_descriptors;
import wheeler.runtime.testing.runners.test_manifest;
import wheeler.runtime.testing.runners.test_package_lock;
import wheeler.runtime.testing.runners.test_source_compilation;
import wheeler.runtime.testing.runners.test_source_plan;
import wheeler.runtime.testing.test_artifact_report;
import wheeler.runtime.testing.test_case_identity;
import wheeler.runtime.testing.test_identity_text;
import wheeler.runtime.testing.test_report_identity;
import wheeler.runtime.testing.test_shard;
import wheeler.runtime.testing.test_summary;

classical class TestRunner {
  private const long CASE_RESULT_BYTES = 5345;
  private const long MAX_CASES = 64;
  private const long MAX_COPY_BYTES = 342080;
  private const long MAX_PAYLOAD_BYTES = 32768;
  private const long REPORT_ROWS_BYTES = 342080;
  private const long SUMMARY_ROWS_BYTES = 2048;

  private long copyRange(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit MAX_COPY_BYTES {
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

  private long checkedCaseEnd(borrow byteview input, long start) {
    long cursor = start;
    assert(cursor < bufferLength(input));
    long nameLength = input[cursor];
    assert(0 < nameLength);
    cursor += 1;
    assert(cursor + nameLength + 3 < bufferLength(input));
    cursor += nameLength;
    long artifactLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(artifactLength < MAX_PAYLOAD_BYTES + 1);
    cursor += 4;
    assert(cursor + artifactLength < bufferLength(input) + 1);
    return cursor + artifactLength;
  }

  private long resultStatus(borrow byteview result, long resultLength) {
    long cursor = 0;
    long field = 0;
    while (field < 10) limit 10 {
      assert(cursor + 1 < resultLength);
      long length = readUnsigned(result, cursor, /* width= */ 2);
      cursor += 2;
      assert(cursor + length < resultLength + 1);
      cursor += length;
      field += 1;
    }

    assert(cursor < resultLength);
    long status = result[cursor];
    assert(status < 2);
    return status;
  }

  /// Runs, reduces, and writes one bounded identity and summary product.
  public long runTests(borrow byteview input, borrow mut bytes output) {
    assert(8 < bufferLength(input));
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
    assert(cursor + targetLength < bufferLength(input));
    long targetStart = cursor;
    cursor += targetLength;
    assert(cursor + 4 < bufferLength(input));
    long manifestLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < manifestLength);
    assert(manifestLength < 4097);
    cursor += 4;
    assert(cursor + manifestLength + 4 < bufferLength(input));
    long manifestStart = cursor;
    cursor += manifestLength;
    long lockLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < lockLength);
    assert(lockLength < 4097);
    cursor += 4;
    assert(cursor + lockLength + 4 < bufferLength(input));
    long lockStart = cursor;
    cursor += lockLength;
    long sourcePlanLength = readUnsigned(input, cursor, /* width= */ 4);
    assert(0 < sourcePlanLength);
    assert(sourcePlanLength < MAX_PAYLOAD_BYTES + 1);
    cursor += 4;
    assert(cursor + sourcePlanLength < bufferLength(input));
    long sourcePlanStart = cursor;
    cursor += sourcePlanLength;
    long caseCount = input[cursor];
    assert(caseCount < MAX_CASES + 1);
    cursor += 1;

    long scan = cursor;
    long scannedCase = 0;
    long previousNameStart = 0;
    long previousNameLength = 0;
    boolean compileSource = false;
    while (scannedCase < caseCount) limit MAX_CASES {
      long scannedNameLength = input[scan];
      long scannedNameStart = scan + 1;
      assert(validCaseName(input, scannedNameStart, scannedNameLength));
      if (0 < scannedCase) {
        assert(
          compareCaseName(
            input,
            previousNameStart,
            previousNameLength,
            scannedNameStart,
            scannedNameLength
          ) == -1
        );
      }

      previousNameStart = scannedNameStart;
      previousNameLength = scannedNameLength;
      long scannedArtifactLength = readUnsigned(
        input,
        scannedNameStart + scannedNameLength,
        /* width= */ 4
      );
      if (scannedArtifactLength == 0) {
        assert(caseCount == 1);
        compileSource = true;
      }

      scan = checkedCaseEnd(input, scan);
      scannedCase += 1;
    }

    assert(scan == bufferLength(input));

    region staging = new region(/* bytes= */ 740000, /* allocations= */ 36);
    bytes runner = allocateBytes(staging, /* length= */ 64);
    writeAscii(
      runner,
      /* offset= */ 0,
      "0000000000000000000000000000000000000000000000000000000000000001"
    );
    bytes packageName = allocateBytes(staging, packageLength);
    long copied = copyRange(
      input,
      packageStart,
      packageLength,
      packageName,
      /* outputStart= */ 0
    );
    assert(copied == packageLength);
    bytes packageVersion = allocateBytes(staging, versionLength);
    copied = copyRange(
      input,
      versionStart,
      versionLength,
      packageVersion,
      /* outputStart= */ 0
    );
    assert(copied == versionLength);
    bytes target = allocateBytes(staging, targetLength);
    copied = copyRange(input, targetStart, targetLength, target, /* outputStart= */ 0);
    assert(copied == targetLength);
    assert(validTargetSourcePlan(input, sourcePlanStart, sourcePlanLength));
    long compiledSourceCount = 0;
    long compiledRootOrdinal = 0;
    if (compileSource) {
      assert(validCompilableSourcePlan(input, sourcePlanStart, sourcePlanLength));
      compiledSourceCount = validatedSourceCount(input, sourcePlanStart, sourcePlanLength);
    }

    assert(
      validTestManifest(
        input,
        manifestStart,
        manifestLength,
        packageName,
        packageVersion,
        target,
        sourcePlanStart,
        sourcePlanLength
      )
    );
    if (compileSource) {
      compiledRootOrdinal = validatedRootSourceOrdinal(
        input,
        manifestStart,
        manifestLength,
        target,
        sourcePlanStart
      );
      assert(-1 < compiledRootOrdinal);
      assert(compiledRootOrdinal < compiledSourceCount);
    }

    bytes rawManifestIdentity = allocateBytes(staging, /* length= */ 32);
    hashSha256Range(input, manifestStart, manifestLength, rawManifestIdentity, staging);
    bytes manifestIdentity = allocateBytes(staging, /* length= */ 64);
    long manifestIdentityLength = writeTestIdentityText(rawManifestIdentity, manifestIdentity);
    assert(manifestIdentityLength == 64);
    assert(validEmptyPackageLock(input, lockStart, lockLength, manifestIdentity));
    bytes rawSourceIdentity = allocateBytes(staging, /* length= */ 32);
    hashSha256Range(input, sourcePlanStart, sourcePlanLength, rawSourceIdentity, staging);
    bytes sourceIdentity = allocateBytes(staging, /* length= */ 64);
    long sourceIdentityLength = writeTestIdentityText(rawSourceIdentity, sourceIdentity);
    assert(sourceIdentityLength == 64);
    bytes reportRows = allocateBytes(staging, REPORT_ROWS_BYTES);
    bytes summaryRows = allocateBytes(staging, SUMMARY_ROWS_BYTES);
    bytes statusRows = allocateBytes(staging, MAX_CASES);

    long selectedCount = 0;
    long reportRowsLength = 0;
    long descriptor = 0;
    while (descriptor < caseCount) limit MAX_CASES {
      long nameLength = input[cursor];
      cursor += 1;
      long nameStart = cursor;
      cursor += nameLength;
      long artifactLength = readUnsigned(input, cursor, /* width= */ 4);
      cursor += 4;
      long artifactStart = cursor;
      cursor += artifactLength;

      bytes caseName = allocateBytes(staging, nameLength);
      copied = copyRange(input, nameStart, nameLength, caseName, /* outputStart= */ 0);
      assert(copied == nameLength);
      if (compileSource) {
        assert(validEntryCaseName(caseName, /* start= */ 0, nameLength, target));
      }

      bytes caseInput = allocateBytes(staging, 130 + nameLength);
      copied = copyRange(
        manifestIdentity,
        /* inputStart= */ 0,
        /* length= */ 64,
        caseInput,
        /* outputStart= */ 0
      );
      assert(copied == 64);
      copied = copyRange(
        sourceIdentity,
        /* inputStart= */ 0,
        /* length= */ 64,
        caseInput,
        /* outputStart= */ 64
      );
      assert(copied == 128);
      setByte(caseInput, /* index= */ 128, nameLength);
      setByte(caseInput, /* index= */ 129, /* nameLengthHigh= */ 0);
      copied = copyRange(
        caseName,
        /* inputStart= */ 0,
        nameLength,
        caseInput,
        /* outputStart= */ 130
      );
      assert(copied == bufferLength(caseInput));
      bytes rawCase = allocateBytes(staging, /* length= */ 32);
      long rawCaseLength = deriveTestCaseIdentity(caseInput, rawCase);
      assert(rawCaseLength == 32);
      bytes caseIdentity = allocateBytes(staging, /* length= */ 64);
      long caseIdentityLength = writeTestIdentityText(rawCase, caseIdentity);
      assert(caseIdentityLength == 64);
      bytes shardInput = allocateBytes(staging, /* length= */ 68);
      copied = copyRange(
        caseIdentity,
        /* inputStart= */ 0,
        /* length= */ 64,
        shardInput,
        /* outputStart= */ 0
      );
      assert(copied == 64);
      setByte(shardInput, /* index= */ 64, input[0]);
      setByte(shardInput, /* index= */ 65, input[1]);
      setByte(shardInput, /* index= */ 66, input[2]);
      setByte(shardInput, /* index= */ 67, input[3]);

      if (assignedToShard(shardInput)) {
        bytes artifactStorage = allocateBytes(staging, MAX_PAYLOAD_BYTES);
        long executionArtifactLength = artifactLength;
        if (artifactLength == 0) {
          executionArtifactLength = compileValidatedSourcePlan(
            input,
            sourcePlanStart,
            sourcePlanLength,
            compiledRootOrdinal,
            artifactStorage
          );
        } else {
          copied = copyRange(
            input,
            artifactStart,
            artifactLength,
            artifactStorage,
            /* outputStart= */ 0
          );
          assert(copied == artifactLength);
        }

        bytes artifact = allocateBytes(staging, executionArtifactLength);
        copied = copyRange(
          artifactStorage,
          /* inputStart= */ 0,
          executionArtifactLength,
          artifact,
          /* outputStart= */ 0
        );
        assert(copied == executionArtifactLength);
        bytes result = allocateBytes(staging, CASE_RESULT_BYTES);
        long resultLength = writeArtifactCaseResult(
          artifact,
          packageName,
          packageVersion,
          caseName,
          caseIdentity,
          sourceIdentity,
          result
        );
        reportRowsLength = copyRange(
          result,
          /* inputStart= */ 0,
          resultLength,
          reportRows,
          reportRowsLength
        );
        long summaryRowStart = selectedCount * 32;
        copied = copyRange(
          rawCase,
          /* inputStart= */ 0,
          /* length= */ 32,
          summaryRows,
          summaryRowStart
        );
        assert(copied == summaryRowStart + 32);
        setByte(statusRows, selectedCount, resultStatus(result, resultLength));
        selectedCount += 1;
        drop(result);
        drop(artifact);
        drop(artifactStorage);
      }

      drop(shardInput);
      drop(caseIdentity);
      drop(rawCase);
      drop(caseInput);
      drop(caseName);
      descriptor += 1;
    }

    assert(cursor == bufferLength(input));

    long frameLength = 68 + reportRowsLength;
    bytes frame = allocateBytes(staging, frameLength);
    long frameCursor = writeField(runner, frame, /* cursor= */ 0);
    setByte(frame, frameCursor, selectedCount);
    setByte(frame, frameCursor + 1, /* selectedCountHigh= */ 0);
    frameCursor += 2;
    frameCursor = copyRange(
      reportRows,
      /* inputStart= */ 0,
      reportRowsLength,
      frame,
      frameCursor
    );
    assert(frameCursor == frameLength);
    bytes reportIdentity = allocateBytes(staging, /* length= */ 32);
    long reportLength = deriveTestReportIdentity(frame, reportIdentity);
    assert(reportLength == 32);

    bytes summaryInput = allocateBytes(staging, 2 + selectedCount * 33);
    setByte(summaryInput, /* index= */ 0, selectedCount);
    setByte(summaryInput, /* index= */ 1, /* selectedCountHigh= */ 0);
    long selected = 0;
    long summaryCursor = 2;
    while (selected < selectedCount) limit MAX_CASES {
      summaryCursor = copyRange(
        summaryRows,
        selected * 32,
        /* length= */ 32,
        summaryInput,
        summaryCursor
      );
      setByte(summaryInput, summaryCursor, statusRows[selected]);
      summaryCursor += 1;
      selected += 1;
    }

    assert(summaryCursor == bufferLength(summaryInput));
    bytes summary = allocateBytes(staging, /* length= */ 7);
    long summaryLength = reduceTestSummary(summaryInput, summary);
    assert(summaryLength == 7);

    assert(bufferLength(output) == 39);
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
    drop(statusRows);
    drop(summaryRows);
    drop(reportRows);
    drop(sourceIdentity);
    drop(rawSourceIdentity);
    drop(manifestIdentity);
    drop(rawManifestIdentity);
    drop(target);
    drop(packageVersion);
    drop(packageName);
    drop(runner);
    drop(staging);
    return published;
  }
}
