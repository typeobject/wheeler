//! Renders canonical profile-2 rows as the JUnit XML adapter.

module wheeler.runtime.testing.test_report_junit;

import wheeler.runtime.testing.test_limits;
import wheeler.runtime.testing.test_report_adapter;

classical class TestReportJunit {
  private const long MAX_CASES = MAX_TEST_CASES;
  private const long MAX_FIELD_BYTES = 4096;

  private long writeXmlRange(
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
      if (octet == 38) {
        writeAscii(output, cursor, "&amp;");
        cursor += 5;
      } else {
        if (octet == 60) {
          writeAscii(output, cursor, "&lt;");
          cursor += 4;
        } else {
          if (octet == 62) {
            writeAscii(output, cursor, "&gt;");
            cursor += 4;
          } else {
            if (octet == 34) {
              writeAscii(output, cursor, "&quot;");
              cursor += 6;
            } else {
              if (octet == 39) {
                writeAscii(output, cursor, "&apos;");
                cursor += 6;
              } else {
                setByte(output, cursor, octet);
                cursor += 1;
              }
            }
          }
        }
      }

      offset += 1;
    }

    return cursor;
  }

  private long writeQuotedRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    setByte(output, cursor, 34);
    cursor = writeXmlRange(input, start, length, output, cursor + 1);
    setByte(output, cursor, 34);
    return cursor + 1;
  }

  private long writeQuotedDecimal(borrow mut bytes output, long cursor, long value) {
    setByte(output, cursor, 34);
    cursor = writeTestReportDecimal(output, cursor + 1, value);
    setByte(output, cursor, 34);
    return cursor + 1;
  }

  private long writeQuotedIdentity(
    borrow byteview input,
    long start,
    borrow mut bytes output,
    long cursor
  ) {
    setByte(output, cursor, 34);
    cursor = writeTestReportIdentity(input, start, output, cursor + 1);
    setByte(output, cursor, 34);
    return cursor + 1;
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
    } else {
      set(summary, 2, summary[2] + 1);
    }

    writeAscii(output, cursor, "  <testcase classname=");
    cursor = writeQuotedRange(input, starts[0], lengths[0], output, cursor + 22);
    writeAscii(output, cursor, " name=");
    cursor = writeQuotedRange(input, starts[2], lengths[2], output, cursor + 6);
    writeAscii(output, cursor, " assertions=");
    cursor = writeQuotedDecimal(output, cursor + 12, row.assertions);
    writeAscii(output, cursor, " wheeler-case=");
    cursor = writeQuotedRange(input, starts[3], lengths[3], output, cursor + 14);
    writeAscii(output, cursor, " wheeler-source=");
    cursor = writeQuotedRange(input, starts[4], lengths[4], output, cursor + 16);
    writeAscii(output, cursor, " wheeler-artifact=");
    cursor = writeQuotedRange(input, starts[5], lengths[5], output, cursor + 18);
    writeAscii(output, cursor, " wheeler-execution=");
    cursor = writeQuotedRange(input, starts[8], lengths[8], output, cursor + 19);
    writeAscii(output, cursor, " wheeler-coverage=");
    cursor = writeQuotedRange(input, starts[9], lengths[9], output, cursor + 18);
    writeAscii(output, cursor, " workflow-steps=");
    cursor = writeQuotedDecimal(output, cursor + 16, row.workflowSteps);
    if (row.status == 0) {
      writeAscii(output, cursor, "/>");
      setByte(output, cursor + 2, 10);
      return cursor + 3;
    }

    setByte(output, cursor, 62);
    setByte(output, cursor + 1, 10);
    cursor += 2;
    writeAscii(output, cursor, "    <failure type=");
    cursor = writeQuotedRange(input, starts[6], lengths[6], output, cursor + 18);
    writeAscii(output, cursor, " message=");
    cursor = writeQuotedRange(input, starts[7], lengths[7], output, cursor + 9);
    writeAscii(output, cursor, "/>");
    setByte(output, cursor + 2, 10);
    writeAscii(output, cursor + 3, "  </testcase>");
    setByte(output, cursor + 16, 10);
    return cursor + 17;
  }

  private long writeHeader(borrow byteview input, AdapterHeader header, borrow mut bytes output) {
    long cursor = 0;
    writeAscii(output, cursor, "<?xml version=");
    setByte(output, cursor + 14, 34);
    writeAscii(output, cursor + 15, "1.0");
    setByte(output, cursor + 18, 34);
    writeAscii(output, cursor + 19, " encoding=");
    setByte(output, cursor + 29, 34);
    writeAscii(output, cursor + 30, "UTF-8");
    setByte(output, cursor + 35, 34);
    writeAscii(output, cursor + 36, "?>");
    setByte(output, cursor + 38, 10);
    cursor += 39;
    writeAscii(output, cursor, "<testsuite name=");
    cursor = writeQuotedRange(
      input,
      header.subjectStart,
      header.subjectLength,
      output,
      cursor + 16
    );
    writeAscii(output, cursor, " tests=");
    cursor = writeQuotedDecimal(output, cursor + 7, header.selected);
    writeAscii(output, cursor, " failures=");
    cursor = writeQuotedDecimal(output, cursor + 10, header.failed);
    writeAscii(output, cursor, " skipped=");
    cursor = writeQuotedDecimal(output, cursor + 9, /* skipped= */ 0);
    writeAscii(output, cursor, " wheeler-report=");
    cursor = writeQuotedIdentity(input, 0, output, cursor + 16);
    setByte(output, cursor, 62);
    setByte(output, cursor + 1, 10);
    return cursor + 2;
  }

  /// Renders one complete canonical row transport and returns its exact byte length.
  public long renderTestReportJunit(borrow byteview input, borrow mut bytes output) {
    AdapterHeader header = validatedTestReportAdapter(input);
    region staging = new region(/* bytes= */ 256, /* allocations= */ 3);
    words starts = allocate(staging, /* length= */ 10);
    words lengths = allocate(staging, /* length= */ 10);
    words summary = allocate(staging, /* length= */ 3);

    long cursor = writeHeader(input, header, output);
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
    writeAscii(output, cursor, "</testsuite>");
    setByte(output, cursor + 12, 10);
    cursor += 13;

    drop(summary);
    drop(lengths);
    drop(starts);
    drop(staging);
    assert(cursor < bufferLength(output) + 1);
    return cursor;
  }
}
