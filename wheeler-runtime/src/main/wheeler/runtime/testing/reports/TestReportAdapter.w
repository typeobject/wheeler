//! Validates shared framing for native profile-2 presentation adapters.

module wheeler.runtime.testing.test_report_adapter;

import wheeler.core.encoding.binary;

classical class TestReportAdapter {
  private const long MAX_CASES = 64;
  private const long MAX_FIELD_BYTES = 4096;
  private const long MAX_ROW_BYTES = 342080;

  /// Defines one validated complete adapter transport header.
  public record AdapterHeader(
    long subjectStart,
    long subjectLength,
    long selected,
    long passed,
    long failed,
    long rowStart,
    long rowLength
  ) {}

  /// Defines one validated complete profile-2 row.
  public record AdapterRow(long end, long status, long assertions, long workflowSteps) {}

  private long readUnsigned16(borrow byteview input, long cursor) {
    return input[cursor] + input[cursor + 1] * 256;
  }

  private long readUnsigned32(borrow byteview input, long cursor) {
    return input[cursor] + input[cursor + 1] * 256 + input[cursor + 2] * 65536 + input[cursor + 3]
      * 16777216;
  }

  /// Validates and projects one complete adapter transport header.
  public AdapterHeader validatedTestReportAdapter(borrow byteview input) {
    assert(43 < bufferLength(input));
    long subjectLength = readUnsigned16(input, 32);
    assert(subjectLength < 256);
    long subjectStart = 34;
    long summaryStart = subjectStart + subjectLength;
    assert(summaryStart + 10 < bufferLength(input) + 1);
    long selected = readUnsigned16(input, summaryStart);
    long passed = readUnsigned16(input, summaryStart + 2);
    long failed = readUnsigned16(input, summaryStart + 4);
    long rowLength = readUnsigned32(input, summaryStart + 6);
    long rowStart = summaryStart + 10;
    assert(selected < MAX_CASES + 1);
    assert(rowLength < MAX_ROW_BYTES + 1);
    assert(rowStart + rowLength == bufferLength(input));
    assert(selected == passed + failed);
    return new AdapterHeader(
      subjectStart,
      subjectLength,
      selected,
      passed,
      failed,
      rowStart,
      rowLength
    );
  }

  /// Validates and projects one complete profile-2 row and its ten fields.
  public AdapterRow validatedTestReportRow(
    borrow byteview input,
    long rowStart,
    borrow mut words starts,
    borrow mut words lengths
  ) {
    assert(-1 < rowStart);
    assert(rowStart < bufferLength(input));
    long cursor = rowStart;
    long field = 0;
    while (field < 10) limit 10 {
      assert(cursor + 2 < bufferLength(input) + 1);
      long length = readUnsigned16(input, cursor);
      assert(length < MAX_FIELD_BYTES + 1);
      cursor += 2;
      assert(cursor + length < bufferLength(input) + 1);
      set(starts, field, cursor);
      set(lengths, field, length);
      cursor += length;
      field += 1;
    }

    assert(cursor + 17 < bufferLength(input) + 1);
    long status = input[cursor];
    assert(status < 2);
    long assertions = readSigned(input, cursor + 1);
    long workflowSteps = readSigned(input, cursor + 9);
    assert(-1 < assertions);
    assert(-1 < workflowSteps);
    return new AdapterRow(cursor + 17, status, assertions, workflowSteps);
  }

  /// Writes one nonnegative signed value in canonical decimal form.
  public long writeTestReportDecimal(borrow mut bytes output, long cursor, long value) {
    assert(-1 < value);
    long digits = 1;
    long divisor = 1;
    long remaining = value;
    while (9 < remaining) limit 20 {
      remaining = remaining / 10;
      divisor = divisor * 10;
      digits += 1;
    }

    long offset = 0;
    while (offset < digits) limit 20 {
      setByte(output, cursor, value / divisor % 10 + 48);
      divisor = divisor / 10;
      cursor += 1;
      offset += 1;
    }

    return cursor;
  }

  /// Writes one raw 32-byte identity as lowercase hexadecimal.
  public long writeTestReportIdentity(
    borrow byteview input,
    long start,
    borrow mut bytes output,
    long cursor
  ) {
    long offset = 0;
    while (offset < 32) limit 32 {
      long octet = input[start + offset];
      long high = octet / 16;
      long low = octet % 16;
      setByte(output, cursor, high + 48);
      if (9 < high) {
        setByte(output, cursor, high + 87);
      }

      setByte(output, cursor + 1, low + 48);
      if (9 < low) {
        setByte(output, cursor + 1, low + 87);
      }

      cursor += 2;
      offset += 1;
    }

    return cursor;
  }
}
