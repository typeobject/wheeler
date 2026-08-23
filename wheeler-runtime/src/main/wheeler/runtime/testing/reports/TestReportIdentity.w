//! Derives bounded profile-2 semantic test report identities.

module wheeler.runtime.testing.test_report_identity;

import wheeler.core.encoding.binary;
import wheeler.crypto.sha256;
import wheeler.runtime.testing.test_limits;

classical class TestReportIdentity {
  private const long CASE_FIELD_COUNT = 10;
  private const long HASH_ARENA_BYTES = 1088;
  private const long IDENTITY_BYTES = 64;
  private const long MAX_CASES = MAX_TEST_CASES;
  private const long MAX_DIAGNOSTIC_BYTES = 4096;
  private const long MAX_FIELD_BYTES = 255;
  private const long MESSAGE_BYTES = 709741;
  private const long OUTPUT_BYTES = 32;
  private const long STAGING_BYTES = 733357;

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
    boolean validLength = length == IDENTITY_BYTES;
    if (optional) {
      if (length == 0) {
        validLength = true;
      }
    }

    assert(validLength);
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

  private long compareIdentities(borrow byteview input, long leftStart, long rightStart) {
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      long left = input[leftStart + offset];
      long right = input[rightStart + offset];
      if (left < right) {
        return -1;
      }

      if (right < left) {
        return 1;
      }

      offset += 1;
    }

    return 0;
  }

  /// Writes the raw SHA-256 identity for one complete bounded profile-2 report.
  public long deriveTestReportIdentity(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(output) == OUTPUT_BYTES);
    assert(3 < bufferLength(input));
    long runnerLength = readUnsigned(input, /* offset= */ 0, /* width= */ 2);
    assert(runnerLength == IDENTITY_BYTES);
    assert(67 < bufferLength(input));
    long runnerStart = 2;
    validateIdentity(input, runnerStart, runnerLength, /* optional= */ false);
    long cursor = runnerStart + runnerLength;
    long caseCount = readUnsigned(input, cursor, /* width= */ 2);
    cursor += 2;
    assert(caseCount < MAX_CASES + 1);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 8);
    words starts = allocate(staging, MAX_CASES * CASE_FIELD_COUNT);
    words lengths = allocate(staging, MAX_CASES * CASE_FIELD_COUNT);
    words statusOffsets = allocate(staging, MAX_CASES);
    words order = allocate(staging, MAX_CASES);
    bytes message = allocateBytes(staging, MESSAGE_BYTES);
    long row = 0;
    while (row < caseCount) limit MAX_CASES {
      long field = 0;
      while (field < CASE_FIELD_COUNT) limit CASE_FIELD_COUNT {
        assert(cursor < bufferLength(input) - 1);
        long length = readUnsigned(input, cursor, /* width= */ 2);
        cursor += 2;
        assert(length < bufferLength(input) - cursor + 1);
        long slot = row * CASE_FIELD_COUNT + field;
        set(starts, slot, cursor);
        set(lengths, slot, length);
        cursor += length;
        field += 1;
      }

      assert(cursor < bufferLength(input) - 16);
      set(statusOffsets, row, cursor);
      long status = input[cursor];
      long assertions = readSigned(input, cursor + 1);
      long workflowSteps = readSigned(input, cursor + 9);
      cursor += 17;
      assert(status < 2);
      assert(-1 < assertions);
      assert(-1 < workflowSteps);
      long base = row * CASE_FIELD_COUNT;
      assert(0 < lengths[base]);
      assert(lengths[base] < MAX_FIELD_BYTES + 1);
      assert(0 < lengths[base + 1]);
      assert(lengths[base + 1] < MAX_FIELD_BYTES + 1);
      assert(0 < lengths[base + 2]);
      assert(lengths[base + 2] < MAX_FIELD_BYTES + 1);
      assert(lengths[base + 6] < MAX_FIELD_BYTES + 1);
      assert(lengths[base + 7] < MAX_DIAGNOSTIC_BYTES + 1);
      validateIdentity(input, starts[base + 3], lengths[base + 3], /* optional= */ false);
      validateIdentity(input, starts[base + 4], lengths[base + 4], /* optional= */ false);
      validateIdentity(input, starts[base + 5], lengths[base + 5], /* optional= */ true);
      validateIdentity(input, starts[base + 8], lengths[base + 8], /* optional= */ true);
      validateIdentity(input, starts[base + 9], lengths[base + 9], /* optional= */ true);
      if (status == 0) {
        assert(lengths[base + 5] == IDENTITY_BYTES);
        assert(lengths[base + 6] == 0);
        assert(lengths[base + 7] == 0);
        assert(lengths[base + 8] == IDENTITY_BYTES);
      } else {
        assert(0 < lengths[base + 6]);
      }

      set(order, row, row);
      row += 1;
    }

    assert(cursor == bufferLength(input));
    row = 1;
    while (row < caseCount) limit MAX_CASES {
      long selected = order[row];
      long selectedIdentity = starts[selected * CASE_FIELD_COUNT + 3];
      long position = row;
      boolean shifting = 0 < position;
      while (shifting) limit MAX_CASES {
        long prior = order[position - 1];
        long priorIdentity = starts[prior * CASE_FIELD_COUNT + 3];
        if (compareIdentities(input, selectedIdentity, priorIdentity) < 0) {
          set(order, position, prior);
          position -= 1;
          shifting = 0 < position;
        } else {
          shifting = false;
        }
      }

      set(order, position, selected);
      row += 1;
    }

    row = 1;
    while (row < caseCount) limit MAX_CASES {
      long left = order[row - 1];
      long right = order[row];
      assert(
        compareIdentities(
          input,
          starts[left * CASE_FIELD_COUNT + 3],
          starts[right * CASE_FIELD_COUNT + 3]
        ) != 0
      );
      row += 1;
    }

    cursor = writeLong(/* length= */ 21, message, /* cursor= */ 0);
    writeAscii(message, cursor, "wheeler.test-report/2");
    cursor += 21;
    cursor = writeField(input, runnerStart, runnerLength, message, cursor);
    cursor = writeLong(caseCount, message, cursor);
    row = 0;
    while (row < caseCount) limit MAX_CASES {
      long emittedRow = order[row];
      long emittedBase = emittedRow * CASE_FIELD_COUNT;
      long emittedField = 0;
      while (emittedField < 6) limit CASE_FIELD_COUNT {
        cursor = writeField(
          input,
          starts[emittedBase + emittedField],
          lengths[emittedBase + emittedField],
          message,
          cursor
        );
        emittedField += 1;
      }

      cursor = writeLong(/* length= */ 4, message, cursor);
      long statusOffset = statusOffsets[emittedRow];
      if (input[statusOffset] == 0) {
        writeAscii(message, cursor, "PASS");
      } else {
        writeAscii(message, cursor, "FAIL");
      }

      cursor += 4;
      emittedField = 6;
      while (emittedField < 8) limit CASE_FIELD_COUNT {
        cursor = writeField(
          input,
          starts[emittedBase + emittedField],
          lengths[emittedBase + emittedField],
          message,
          cursor
        );
        emittedField += 1;
      }

      cursor = writeLong(readSigned(input, statusOffset + 1), message, cursor);
      cursor = writeLong(readSigned(input, statusOffset + 9), message, cursor);
      emittedField = 8;
      while (emittedField < CASE_FIELD_COUNT) limit CASE_FIELD_COUNT {
        cursor = writeField(
          input,
          starts[emittedBase + emittedField],
          lengths[emittedBase + emittedField],
          message,
          cursor
        );
        emittedField += 1;
      }

      row += 1;
    }

    hashSha256Range(message, /* inputStart= */ 0, cursor, output, staging);
    drop(message);
    drop(order);
    drop(statusOffsets);
    drop(lengths);
    drop(starts);
    drop(staging);
    return OUTPUT_BYTES;
  }
}
