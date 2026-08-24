//! Reduces bounded native target reports into one package evidence identity.

module wheeler.runtime.testing.test_package_report_identity;

import wheeler.crypto.sha256;

classical class TestPackageReportIdentity {
  private const long IDENTITY_BYTES = 32;
  private const long MAX_TARGETS = 128;
  private const long ROW_BYTES = 38;

  private long readCount(borrow byteview input, long start) {
    return input[start] + input[start + 1] * 256;
  }

  private void writeCount(borrow mut bytes output, long start, long value) {
    assert(value < 65536);
    setByte(output, start, value % 256);
    setByte(output, start + 1, value / 256);
  }

  private long compareRows(borrow byteview rows, long left, long right) {
    long leftStart = left * ROW_BYTES;
    long rightStart = right * ROW_BYTES;
    long offset = 0;
    while (offset < IDENTITY_BYTES) limit IDENTITY_BYTES {
      if (rows[leftStart + offset] < rows[rightStart + offset]) {
        return -1;
      }

      if (rows[rightStart + offset] < rows[leftStart + offset]) {
        return 1;
      }

      offset += 1;
    }

    return 0;
  }

  private void swapRows(borrow mut bytes rows, long left, long right) {
    long leftStart = left * ROW_BYTES;
    long rightStart = right * ROW_BYTES;
    long offset = 0;
    while (offset < ROW_BYTES) limit ROW_BYTES {
      long value = rows[leftStart + offset];
      setByte(rows, leftStart + offset, rows[rightStart + offset]);
      setByte(rows, rightStart + offset, value);
      offset += 1;
    }
  }

  private void sortRows(borrow mut bytes rows, long count) {
    long pass = 0;
    while (pass < count) limit MAX_TARGETS {
      long row = 1;
      while (row < count - pass) limit MAX_TARGETS {
        if (0 < compareRows(rows, row - 1, row)) {
          swapRows(rows, row - 1, row);
        }

        row += 1;
      }

      pass += 1;
    }

    long checked = 1;
    while (checked < count) limit MAX_TARGETS {
      assert(compareRows(rows, checked - 1, checked) == -1);
      checked += 1;
    }
  }

  /// Writes one raw package identity followed by selected, passed, and failed counts.
  public long deriveTestPackageReportIdentity(borrow byteview input, borrow mut bytes output) {
    assert(bufferLength(output) == 38);
    assert(0 < bufferLength(input));
    long count = input[0];
    assert(0 < count);
    assert(count < MAX_TARGETS + 1);
    assert(bufferLength(input) == 1 + count * ROW_BYTES);
    region staging = new region(/* bytes= */ 16384, /* allocations= */ 8);
    bytes rows = allocateBytes(staging, MAX_TARGETS * ROW_BYTES);
    long inputCursor = 1;
    long row = 0;
    while (row < count) limit MAX_TARGETS {
      long offset = 0;
      while (offset < ROW_BYTES) limit ROW_BYTES {
        setByte(rows, row * ROW_BYTES + offset, input[inputCursor + offset]);
        offset += 1;
      }

      long selected = readCount(rows, row * ROW_BYTES + 32);
      long passed = readCount(rows, row * ROW_BYTES + 34);
      long failed = readCount(rows, row * ROW_BYTES + 36);
      assert(selected == passed + failed);
      inputCursor += ROW_BYTES;
      row += 1;
    }

    sortRows(rows, count);
    long totalSelected = 0;
    long totalPassed = 0;
    long totalFailed = 0;
    row = 0;
    while (row < count) limit MAX_TARGETS {
      totalSelected += readCount(rows, row * ROW_BYTES + 32);
      totalPassed += readCount(rows, row * ROW_BYTES + 34);
      totalFailed += readCount(rows, row * ROW_BYTES + 36);
      assert(totalSelected < 65536);
      assert(totalPassed < 65536);
      assert(totalFailed < 65536);
      row += 1;
    }

    long frameLength = 36 + count * ROW_BYTES;
    bytes frame = allocateBytes(staging, frameLength);
    writeAscii(frame, /* offset= */ 0, "wheeler.test-package-report/1");
    setByte(frame, /* index= */ 29, count);
    long cursor = 30;
    row = 0;
    while (row < count) limit MAX_TARGETS {
      long frameOffset = 0;
      while (frameOffset < ROW_BYTES) limit ROW_BYTES {
        setByte(frame, cursor, rows[row * ROW_BYTES + frameOffset]);
        cursor += 1;
        frameOffset += 1;
      }

      row += 1;
    }

    writeCount(frame, cursor, totalSelected);
    writeCount(frame, cursor + 2, totalPassed);
    writeCount(frame, cursor + 4, totalFailed);
    cursor += 6;
    assert(cursor == frameLength);
    bytes identity = allocateBytes(staging, IDENTITY_BYTES);
    hashSha256(frame, identity, staging);
    row = 0;
    while (row < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(output, row, identity[row]);
      row += 1;
    }

    writeCount(output, 32, totalSelected);
    writeCount(output, 34, totalPassed);
    writeCount(output, 36, totalFailed);
    drop(identity);
    drop(frame);
    drop(rows);
    drop(staging);
    return 38;
  }
}
