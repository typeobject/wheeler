//! Derives one-case profile-2 semantic test report identities.

module wheeler.runtime.testing.test_report_identity;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;

classical class TestReportIdentity {
  private const long EMPTY_MESSAGE_BYTES = 109;
  private const long EMPTY_STAGING_BYTES = 1197;
  private const long FIELD_COUNT = 11;
  private const long HASH_ARENA_BYTES = 1088;
  private const long IDENTITY_BYTES = 64;
  private const long MAX_DIAGNOSTIC_BYTES = 4096;
  private const long MAX_FIELD_BYTES = 255;
  private const long MESSAGE_BYTES = 5653;
  private const long OUTPUT_BYTES = 32;
  private const long STAGING_BYTES = 6917;

  private long hexNibble(long value) {
    if (47 < value) {
      if (value < 58) {
        return value - 48;
      }
    }

    if (96 < value) {
      if (value < 103) {
        return value - 87;
      }
    }

    return -1;
  }

  private void validateIdentity(
    borrow byteview input,
    long start,
    long length,
    boolean optional
  ) {
    if (optional) {
      boolean validLength = length == 0;
      if (length == IDENTITY_BYTES) {
        validLength = true;
      }

      assert(validLength);
    } else {
      assert(length == IDENTITY_BYTES);
    }

    long offset = 0;
    while (offset < length) limit IDENTITY_BYTES {
      assert(-1 < hexNibble(input[start + offset]));
      offset += 1;
    }
  }

  private long writeLong(long value, borrow mut bytes output, long cursor) {
    long offset = 8;
    while (0 < offset) limit 8 {
      offset -= 1;
      setByte(output, cursor + offset, value % 256);
      value = value / 256;
    }

    return cursor + 8;
  }

  private long writeRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    long offset = 0;
    while (offset < length) limit MAX_DIAGNOSTIC_BYTES {
      setByte(output, cursor + offset, input[start + offset]);
      offset += 1;
    }

    return cursor + length;
  }

  private long writeField(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    cursor = writeLong(length, output, cursor);
    return writeRange(input, start, length, output, cursor);
  }

  /// Writes the raw SHA-256 identity for an empty or one-case profile-2 report.
  public long deriveTestReportIdentity(borrow byteview input, borrow mut bytes output) {
    if (bufferLength(input) == 66) {
      assert(bufferLength(output) == OUTPUT_BYTES);
      long runnerLength = readUnsigned(input, /* offset= */ 0, /* width= */ 2);
      validateIdentity(input, /* start= */ 2, runnerLength, /* optional= */ false);
      region emptyStaging = new region(/* bytes= */ EMPTY_STAGING_BYTES, /* allocations= */ 4);
      bytes emptyMessage = allocateBytes(emptyStaging, EMPTY_MESSAGE_BYTES);
      long emptyCursor = writeLong(/* length= */ 21, emptyMessage, /* cursor= */ 0);
      writeAscii(emptyMessage, emptyCursor, "wheeler.test-report/2");
      emptyCursor += 21;
      emptyCursor = writeField(input, /* start= */ 2, runnerLength, emptyMessage, emptyCursor);
      emptyCursor = writeLong(/* caseCount= */ 0, emptyMessage, emptyCursor);
      assert(emptyCursor == EMPTY_MESSAGE_BYTES);
      hashSha256(emptyMessage, output, emptyStaging);
      drop(emptyMessage);
      drop(emptyStaging);
      return OUTPUT_BYTES;
    }

    return deriveOneCaseReportIdentity(input, output);
  }

  /// Writes the raw SHA-256 identity for one complete profile-2 case report.
  private long deriveOneCaseReportIdentity(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(output) == OUTPUT_BYTES);
    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 6);
    words starts = allocate(staging, FIELD_COUNT);
    words lengths = allocate(staging, FIELD_COUNT);
    bytes message = allocateBytes(staging, MESSAGE_BYTES);
    long cursor = 0;
    long field = 0;
    while (field < FIELD_COUNT) limit FIELD_COUNT {
      assert(cursor < bufferLength(input) - 1);
      long length = readUnsigned(input, cursor, /* width= */ 2);
      cursor += 2;
      assert(length < bufferLength(input) - cursor + 1);
      set(starts, field, cursor);
      set(lengths, field, length);
      cursor += length;
      field += 1;
    }

    assert(cursor < bufferLength(input) - 16);
    long status = input[cursor];
    long assertions = readSigned(input, cursor + 1);
    long workflowSteps = readSigned(input, cursor + 9);
    assert(bufferLength(input) == cursor + 17);
    assert(status < 2);
    assert(-1 < assertions);
    assert(-1 < workflowSteps);

    assert(lengths[1] < MAX_FIELD_BYTES + 1);
    assert(0 < lengths[1]);
    assert(lengths[2] < MAX_FIELD_BYTES + 1);
    assert(0 < lengths[2]);
    assert(lengths[3] < MAX_FIELD_BYTES + 1);
    assert(0 < lengths[3]);
    assert(lengths[7] < MAX_FIELD_BYTES + 1);
    assert(lengths[8] < MAX_DIAGNOSTIC_BYTES + 1);
    validateIdentity(input, starts[0], lengths[0], /* optional= */ false);
    validateIdentity(input, starts[4], lengths[4], /* optional= */ false);
    validateIdentity(input, starts[5], lengths[5], /* optional= */ false);
    validateIdentity(input, starts[6], lengths[6], /* optional= */ true);
    validateIdentity(input, starts[9], lengths[9], /* optional= */ true);
    validateIdentity(input, starts[10], lengths[10], /* optional= */ true);
    if (status == 0) {
      assert(lengths[6] == IDENTITY_BYTES);
      assert(lengths[7] == 0);
      assert(lengths[8] == 0);
      assert(lengths[9] == IDENTITY_BYTES);
    } else {
      assert(0 < lengths[7]);
    }

    cursor = writeLong(/* length= */ 21, message, /* cursor= */ 0);
    writeAscii(message, cursor, "wheeler.test-report/2");
    cursor += 21;
    cursor = writeField(input, starts[0], lengths[0], message, cursor);
    cursor = writeLong(/* caseCount= */ 1, message, cursor);
    field = 1;
    while (field < 7) limit FIELD_COUNT {
      cursor = writeField(input, starts[field], lengths[field], message, cursor);
      field += 1;
    }

    cursor = writeLong(/* length= */ 4, message, cursor);
    if (status == 0) {
      writeAscii(message, cursor, "PASS");
    } else {
      writeAscii(message, cursor, "FAIL");
    }

    cursor += 4;

    field = 7;
    while (field < 9) limit FIELD_COUNT {
      cursor = writeField(input, starts[field], lengths[field], message, cursor);
      field += 1;
    }

    cursor = writeLong(assertions, message, cursor);
    cursor = writeLong(workflowSteps, message, cursor);
    field = 9;
    while (field < FIELD_COUNT) limit FIELD_COUNT {
      cursor = writeField(input, starts[field], lengths[field], message, cursor);
      field += 1;
    }

    hashSha256Range(message, /* inputStart= */ 0, cursor, output, staging);
    drop(message);
    drop(lengths);
    drop(starts);
    drop(staging);
    return OUTPUT_BYTES;
  }
}
