//! Renders canonical profile-2 rows as the terminal test adapter.

module wheeler.runtime.testing.test_report_terminal;

import wheeler.runtime.testing.test_report_adapter;

classical class TestReportTerminal {
  private const long MAX_CASES = 64;
  private const long MAX_FIELD_BYTES = 4096;

  private long writeRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    assert(length < MAX_FIELD_BYTES + 1);
    long offset = 0;
    while (offset < length) limit MAX_FIELD_BYTES {
      long octet = input[start + offset];
      assert(31 < octet);
      assert(octet < 127);
      setByte(output, cursor, octet);
      cursor += 1;
      offset += 1;
    }

    return cursor;
  }

  private long writeCase(
    borrow byteview input,
    AdapterRow row,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut bytes output,
    long cursor,
    borrow mut words summary
  ) {
    set(summary, 0, summary[0] + 1);
    if (row.status == 0) {
      set(summary, 1, summary[1] + 1);
      writeAscii(output, cursor, "PASS");
    } else {
      set(summary, 2, summary[2] + 1);
      writeAscii(output, cursor, "FAIL");
    }

    cursor += 4;
    setByte(output, cursor, 32);
    cursor = writeRange(input, starts[0], lengths[0], output, cursor + 1);
    setByte(output, cursor, 58);
    setByte(output, cursor + 1, 58);
    cursor = writeRange(input, starts[2], lengths[2], output, cursor + 2);
    setByte(output, cursor, 32);
    cursor = writeRange(input, starts[3], lengths[3], output, cursor + 1);
    writeAscii(output, cursor, " assertions ");
    cursor += 12;
    cursor = writeTestReportDecimal(output, cursor, row.assertions);
    if (0 < lengths[9]) {
      writeAscii(output, cursor, " coverage ");
      cursor += 10;
      cursor = writeRange(input, starts[9], lengths[9], output, cursor);
    }

    if (0 < lengths[6]) {
      setByte(output, cursor, 32);
      cursor = writeRange(input, starts[6], lengths[6], output, cursor + 1);
      setByte(output, cursor, 32);
      cursor = writeRange(input, starts[7], lengths[7], output, cursor + 1);
    }

    setByte(output, cursor, 10);
    return cursor + 1;
  }

  /// Renders one complete canonical row transport and returns its exact byte length.
  public long renderTestReportTerminal(borrow byteview input, borrow mut bytes output) {
    AdapterHeader header = validatedTestReportAdapter(input);
    region staging = new region(/* bytes= */ 256, /* allocations= */ 3);
    words starts = allocate(staging, /* length= */ 10);
    words lengths = allocate(staging, /* length= */ 10);
    words summary = allocate(staging, /* length= */ 3);

    long cursor = 0;
    long inputCursor = header.rowStart;
    long rowIndex = 0;
    while (rowIndex < header.selected) limit MAX_CASES {
      AdapterRow row = validatedTestReportRow(input, inputCursor, starts, lengths);
      cursor = writeCase(input, row, starts, lengths, output, cursor, summary);
      inputCursor = row.end;
      rowIndex += 1;
    }

    assert(inputCursor == bufferLength(input));
    assert(summary[0] == header.selected);
    assert(summary[1] == header.passed);
    assert(summary[2] == header.failed);
    writeAscii(output, cursor, "tested ");
    cursor += 7;
    cursor = writeRange(input, header.subjectStart, header.subjectLength, output, cursor);
    setByte(output, cursor, 32);
    setByte(output, cursor + 1, 40);
    cursor = writeTestReportDecimal(output, cursor + 2, header.selected);
    writeAscii(output, cursor, " cases, ");
    cursor += 8;
    cursor = writeTestReportDecimal(output, cursor, header.passed);
    writeAscii(output, cursor, " passed, ");
    cursor += 9;
    cursor = writeTestReportDecimal(output, cursor, header.failed);
    writeAscii(output, cursor, " failed, report ");
    cursor += 16;
    cursor = writeTestReportIdentity(input, 0, output, cursor);
    setByte(output, cursor, 41);
    setByte(output, cursor + 1, 10);
    cursor += 2;

    drop(summary);
    drop(lengths);
    drop(starts);
    drop(staging);
    assert(cursor < bufferLength(output) + 1);
    return cursor;
  }
}
