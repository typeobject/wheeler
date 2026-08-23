//! Renders canonical profile-2 rows as the stage-0 JSON adapter format.

module wheeler.runtime.testing.test_report_json;

import wheeler.core.encoding.binary;

classical class TestReportJson {
  private const long MAX_CASES = 64;
  private const long MAX_FIELD_BYTES = 4096;
  private const long MAX_ROW_BYTES = 342080;
  private const long LABEL_SCHEMA = 0;
  private const long LABEL_REPORT = 1;
  private const long LABEL_SUBJECT = 2;
  private const long LABEL_SELECTED = 3;
  private const long LABEL_PASSED = 4;
  private const long LABEL_FAILED = 5;
  private const long LABEL_CASES = 6;
  private const long LABEL_PACKAGE = 7;
  private const long LABEL_VERSION = 8;
  private const long LABEL_TARGET = 9;
  private const long LABEL_CASE = 10;
  private const long LABEL_SOURCE = 11;
  private const long LABEL_ARTIFACT = 12;
  private const long LABEL_STATUS = 13;
  private const long LABEL_DIAGNOSTIC_CODE = 14;
  private const long LABEL_DIAGNOSTIC_MESSAGE = 15;
  private const long LABEL_ASSERTIONS = 16;
  private const long LABEL_WORKFLOW_STEPS = 17;
  private const long LABEL_EXECUTION = 18;
  private const long LABEL_COVERAGE = 19;

  private long readUnsigned16(borrow byteview input, long cursor) {
    return input[cursor] + input[cursor + 1] * 256;
  }

  private long readUnsigned32(borrow byteview input, long cursor) {
    return input[cursor] + input[cursor + 1] * 256 + input[cursor + 2] * 65536
      + input[cursor + 3] * 16777216;
  }

  private long writeLabelName(borrow mut bytes output, long cursor, long label) {
    if (label == LABEL_SCHEMA) {
      writeAscii(output, cursor, "schema");
      return cursor + 6;
    }
    if (label == LABEL_REPORT) {
      writeAscii(output, cursor, "report");
      return cursor + 6;
    }
    if (label == LABEL_SUBJECT) {
      writeAscii(output, cursor, "subject");
      return cursor + 7;
    }
    if (label == LABEL_SELECTED) {
      writeAscii(output, cursor, "selected");
      return cursor + 8;
    }
    if (label == LABEL_PASSED) {
      writeAscii(output, cursor, "passed");
      return cursor + 6;
    }
    if (label == LABEL_FAILED) {
      writeAscii(output, cursor, "failed");
      return cursor + 6;
    }
    if (label == LABEL_CASES) {
      writeAscii(output, cursor, "cases");
      return cursor + 5;
    }
    if (label == LABEL_PACKAGE) {
      writeAscii(output, cursor, "package");
      return cursor + 7;
    }
    if (label == LABEL_VERSION) {
      writeAscii(output, cursor, "version");
      return cursor + 7;
    }
    if (label == LABEL_TARGET) {
      writeAscii(output, cursor, "target");
      return cursor + 6;
    }
    if (label == LABEL_CASE) {
      writeAscii(output, cursor, "case");
      return cursor + 4;
    }
    if (label == LABEL_SOURCE) {
      writeAscii(output, cursor, "source");
      return cursor + 6;
    }
    if (label == LABEL_ARTIFACT) {
      writeAscii(output, cursor, "artifact");
      return cursor + 8;
    }
    if (label == LABEL_STATUS) {
      writeAscii(output, cursor, "status");
      return cursor + 6;
    }
    if (label == LABEL_DIAGNOSTIC_CODE) {
      writeAscii(output, cursor, "diagnostic_code");
      return cursor + 15;
    }
    if (label == LABEL_DIAGNOSTIC_MESSAGE) {
      writeAscii(output, cursor, "diagnostic_message");
      return cursor + 18;
    }
    if (label == LABEL_ASSERTIONS) {
      writeAscii(output, cursor, "assertions");
      return cursor + 10;
    }
    if (label == LABEL_WORKFLOW_STEPS) {
      writeAscii(output, cursor, "workflow_steps");
      return cursor + 14;
    }
    if (label == LABEL_EXECUTION) {
      writeAscii(output, cursor, "execution");
      return cursor + 9;
    }
    assert(label == LABEL_COVERAGE);
    writeAscii(output, cursor, "coverage");
    return cursor + 8;
  }

  private long writeLabel(
    borrow mut bytes output,
    long cursor,
    long label,
    boolean leadingComma
  ) {
    if (leadingComma) {
      setByte(output, cursor, 44);
      cursor += 1;
    }
    setByte(output, cursor, 34);
    cursor = writeLabelName(output, cursor + 1, label);
    setByte(output, cursor, 34);
    setByte(output, cursor + 1, 58);
    return cursor + 2;
  }

  private long writeDecimal(borrow mut bytes output, long cursor, long value) {
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

  private long writeIdentity(
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

  private long writeJsonRange(
    borrow byteview input,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    assert(length < MAX_FIELD_BYTES + 1);
    setByte(output, cursor, 34);
    cursor += 1;
    long offset = 0;
    while (offset < length) limit MAX_FIELD_BYTES {
      long octet = input[start + offset];
      assert(31 < octet);
      assert(octet < 127);
      if (octet == 34) {
        setByte(output, cursor, 92);
        cursor += 1;
      }

      if (octet == 92) {
        setByte(output, cursor, 92);
        cursor += 1;
      }

      setByte(output, cursor, octet);
      cursor += 1;
      offset += 1;
    }

    setByte(output, cursor, 34);
    return cursor + 1;
  }

  private long writeCase(
    borrow byteview input,
    long rowStart,
    long rowEnd,
    borrow mut words starts,
    borrow mut words lengths,
    borrow mut bytes output,
    long cursor,
    borrow mut words summary
  ) {
    long inputCursor = rowStart;
    long field = 0;
    while (field < 10) limit 10 {
      assert(inputCursor + 2 < rowEnd + 1);
      long length = readUnsigned16(input, inputCursor);
      assert(length < MAX_FIELD_BYTES + 1);
      inputCursor += 2;
      assert(inputCursor + length < rowEnd + 1);
      set(starts, field, inputCursor);
      set(lengths, field, length);
      inputCursor += length;
      field += 1;
    }

    assert(inputCursor + 17 < rowEnd + 1);
    long status = input[inputCursor];
    assert(status < 2);
    long assertions = readSigned(input, inputCursor + 1);
    long workflowSteps = readSigned(input, inputCursor + 9);
    assert(-1 < assertions);
    assert(-1 < workflowSteps);
    inputCursor += 17;
    assert(inputCursor < rowEnd + 1);

    set(summary, 0, summary[0] + 1);
    if (status == 0) {
      set(summary, 1, summary[1] + 1);
    } else {
      set(summary, 2, summary[2] + 1);
    }

    setByte(output, cursor, 123);
    cursor = writeLabel(output, cursor + 1, LABEL_PACKAGE, false);
    cursor = writeJsonRange(input, starts[0], lengths[0], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_VERSION, true);
    cursor = writeJsonRange(input, starts[1], lengths[1], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_TARGET, true);
    cursor = writeJsonRange(input, starts[2], lengths[2], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_CASE, true);
    cursor = writeJsonRange(input, starts[3], lengths[3], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_SOURCE, true);
    cursor = writeJsonRange(input, starts[4], lengths[4], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_ARTIFACT, true);
    cursor = writeJsonRange(input, starts[5], lengths[5], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_STATUS, true);
    setByte(output, cursor, 34);
    cursor += 1;
    if (status == 0) {
      writeAscii(output, cursor, "PASS");
      cursor += 4;
    } else {
      writeAscii(output, cursor, "FAIL");
      cursor += 4;
    }

    setByte(output, cursor, 34);
    cursor += 1;
    cursor = writeLabel(output, cursor, LABEL_DIAGNOSTIC_CODE, true);
    cursor = writeJsonRange(input, starts[6], lengths[6], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_DIAGNOSTIC_MESSAGE, true);
    cursor = writeJsonRange(input, starts[7], lengths[7], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_ASSERTIONS, true);
    cursor = writeDecimal(output, cursor, assertions);
    cursor = writeLabel(output, cursor, LABEL_WORKFLOW_STEPS, true);
    cursor = writeDecimal(output, cursor, workflowSteps);
    cursor = writeLabel(output, cursor, LABEL_EXECUTION, true);
    cursor = writeJsonRange(input, starts[8], lengths[8], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_COVERAGE, true);
    cursor = writeJsonRange(input, starts[9], lengths[9], output, cursor);
    setByte(output, cursor, 125);
    return cursor + 1;
  }

  /// Renders one complete canonical row transport and returns its exact byte length.
  public long renderTestReportJson(borrow byteview input, borrow mut bytes output) {
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

    region staging = new region(/* bytes= */ 256, /* allocations= */ 3);
    words starts = allocate(staging, /* length= */ 10);
    words lengths = allocate(staging, /* length= */ 10);
    words summary = allocate(staging, /* length= */ 3);

    long cursor = 0;
    setByte(output, cursor, 123);
    cursor = writeLabel(output, cursor + 1, LABEL_SCHEMA, false);
    setByte(output, cursor, 34);
    writeAscii(output, cursor + 1, "wheeler.test-report-adapter/1");
    cursor += 30;
    setByte(output, cursor, 34);
    cursor = writeLabel(output, cursor + 1, LABEL_REPORT, true);
    setByte(output, cursor, 34);
    cursor = writeIdentity(input, 0, output, cursor + 1);
    setByte(output, cursor, 34);
    cursor = writeLabel(output, cursor + 1, LABEL_SUBJECT, true);
    cursor = writeJsonRange(input, subjectStart, subjectLength, output, cursor);
    cursor = writeLabel(output, cursor, LABEL_SELECTED, true);
    cursor = writeDecimal(output, cursor, selected);
    cursor = writeLabel(output, cursor, LABEL_PASSED, true);
    cursor = writeDecimal(output, cursor, passed);
    cursor = writeLabel(output, cursor, LABEL_FAILED, true);
    cursor = writeDecimal(output, cursor, failed);
    cursor = writeLabel(output, cursor, LABEL_CASES, true);
    setByte(output, cursor, 91);
    cursor += 1;

    long inputCursor = rowStart;
    long row = 0;
    while (row < selected) limit MAX_CASES {
      if (0 < row) {
        setByte(output, cursor, 44);
        cursor += 1;
      }

      long rowEnd = inputCursor;
      long field = 0;
      while (field < 10) limit 10 {
        assert(rowEnd + 2 < bufferLength(input) + 1);
        long length = readUnsigned16(input, rowEnd);
        rowEnd += 2 + length;
        field += 1;
      }

      rowEnd += 17;
      assert(rowEnd < bufferLength(input) + 1);
      cursor = writeCase(
        input,
        inputCursor,
        rowEnd,
        starts,
        lengths,
        output,
        cursor,
        summary
      );
      inputCursor = rowEnd;
      row += 1;
    }

    assert(inputCursor == bufferLength(input));
    assert(summary[0] == selected);
    assert(summary[1] == passed);
    assert(summary[2] == failed);
    setByte(output, cursor, 93);
    setByte(output, cursor + 1, 125);
    setByte(output, cursor + 2, 10);
    cursor += 3;

    drop(summary);
    drop(lengths);
    drop(starts);
    drop(staging);
    assert(cursor < bufferLength(output) + 1);
    return cursor;
  }
}
