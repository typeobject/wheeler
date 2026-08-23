//! Validates and orders bounded profile-2 test-report rows.

module wheeler.runtime.testing.test_report_rows;

import wheeler.runtime.testing.test_limits;
import wheeler.runtime.testing.test_report_identity;

classical class TestReportRows {
  private const long MAX_CASES = MAX_TEST_CASES;
  private const long MAX_ROW_BYTES = MAX_TEST_REPORT_ROWS_BYTES;

  private long copyRange(
    borrow byteview input,
    long inputStart,
    long length,
    borrow mut bytes output,
    long outputStart
  ) {
    long offset = 0;
    while (offset < length) limit MAX_ROW_BYTES {
      setByte(output, outputStart + offset, input[inputStart + offset]);
      offset += 1;
    }

    return outputStart + length;
  }

  private long publishedRowEnd(borrow byteview rows, long start, long publishedLength) {
    long cursor = start;
    long field = 0;
    while (field < 10) limit 10 {
      assert(cursor + 2 < publishedLength + 1);
      long length = rows[cursor] + rows[cursor + 1] * 256;
      cursor += 2;
      assert(cursor + length < publishedLength + 1);
      cursor += length;
      field += 1;
    }

    assert(cursor + 17 < publishedLength + 1);
    return cursor + 17;
  }

  private long publishedIdentityStart(borrow byteview rows, long rowStart) {
    long cursor = rowStart;
    long field = 0;
    while (field < 3) limit 3 {
      long length = rows[cursor] + rows[cursor + 1] * 256;
      cursor += 2 + length;
      field += 1;
    }

    assert(rows[cursor] == 64);
    assert(rows[cursor + 1] == 0);
    return cursor + 2;
  }

  private long comparePublishedIdentities(
    borrow byteview rows,
    long leftRowStart,
    long rightRowStart
  ) {
    long left = publishedIdentityStart(rows, leftRowStart);
    long right = publishedIdentityStart(rows, rightRowStart);
    long offset = 0;
    while (offset < 64) limit 64 {
      if (rows[left + offset] < rows[right + offset]) {
        return -1;
      }

      if (rows[right + offset] < rows[left + offset]) {
        return 1;
      }

      offset += 1;
    }

    return 0;
  }

  /// Fills row spans and a strict case-identity order for complete rows.
  public void prepareCanonicalReportRows(
    borrow byteview rows,
    long publishedLength,
    long count,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut words order
  ) {
    assert(count < MAX_CASES + 1);
    long cursor = 0;
    long row = 0;
    while (row < count) limit MAX_CASES {
      set(starts, row, cursor);
      long end = publishedRowEnd(rows, cursor, publishedLength);
      set(lengths, row, end - cursor);
      set(order, row, row);
      cursor = end;
      row += 1;
    }

    assert(cursor == publishedLength);
    row = 1;
    while (row < count) limit MAX_CASES {
      long selected = order[row];
      long position = row;
      boolean shifting = 0 < position;
      while (shifting) limit MAX_CASES {
        long prior = order[position - 1];
        if (comparePublishedIdentities(rows, starts[selected], starts[prior]) < 0) {
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
    while (row < count) limit MAX_CASES {
      assert(
        comparePublishedIdentities(rows, starts[order[row - 1]], starts[order[row]]) == -1
      );
      row += 1;
    }
  }

  /// Reduces one package-wide bounded row set into native order and identity.
  public long reduceCanonicalReportRows(borrow byteview input, borrow mut bytes output) {
    assert(5 < bufferLength(input));
    long count = input[0] + input[1] * 256;
    assert(count < MAX_CASES + 1);
    long rowLength = input[2] + input[3] * 256 + input[4] * 65536 + input[5] * 16777216;
    assert(rowLength < MAX_ROW_BYTES + 1);
    assert(bufferLength(input) == 6 + rowLength);
    assert(35 + rowLength < bufferLength(output) + 1);

    region staging = new region(/* bytes= */ 2726150, /* allocations= */ 6);
    words starts = allocate(staging, MAX_CASES);
    words lengths = allocate(staging, MAX_CASES);
    words order = allocate(staging, MAX_CASES);
    bytes rows = allocateBytes(staging, rowLength);
    bytes frame = allocateBytes(staging, 68 + rowLength);
    bytes identity = allocateBytes(staging, /* length= */ 32);
    setByte(frame, /* index= */ 0, /* runnerLengthLow= */ 64);
    setByte(frame, /* index= */ 1, /* runnerLengthHigh= */ 0);
    writeAscii(
      frame,
      /* offset= */ 2,
      "0000000000000000000000000000000000000000000000000000000000000001"
    );
    setByte(frame, /* index= */ 66, count % 256);
    setByte(frame, /* index= */ 67, count / 256);
    long copied = copyRange(input, /* inputStart= */ 6, rowLength, rows, 0);
    assert(copied == rowLength);
    copied = copyRange(rows, 0, rowLength, frame, 68);
    assert(copied == 68 + rowLength);
    long identityLength = deriveTestReportIdentity(frame, identity);
    assert(identityLength == 32);
    prepareCanonicalReportRows(rows, rowLength, count, starts, lengths, order);

    long published = copyRange(identity, 0, 32, output, 0);
    setByte(output, published, rowLength % 256);
    setByte(output, published + 1, rowLength / 256 % 256);
    setByte(output, published + 2, rowLength / 65536 % 256);
    setByte(output, published + 3, rowLength / 16777216);
    published += 4;
    long row = 0;
    while (row < count) limit MAX_CASES {
      long selected = order[row];
      published = copyRange(rows, starts[selected], lengths[selected], output, published);
      row += 1;
    }

    drop(identity);
    drop(frame);
    drop(rows);
    drop(order);
    drop(lengths);
    drop(starts);
    drop(staging);
    return published;
  }
}
