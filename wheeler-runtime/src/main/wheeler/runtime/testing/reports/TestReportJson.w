//! Renders canonical profile-2 rows as the stage-0 JSON adapter format.

module wheeler.runtime.testing.test_report_json;

import wheeler.runtime.testing.test_report_adapter;

classical class TestReportJson {
  private const long MAX_CASES = 64;
  private const long MAX_FIELD_BYTES = 4096;
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
    if (row.status == 0) {
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
    cursor = writeTestReportDecimal(output, cursor, row.assertions);
    cursor = writeLabel(output, cursor, LABEL_WORKFLOW_STEPS, true);
    cursor = writeTestReportDecimal(output, cursor, row.workflowSteps);
    cursor = writeLabel(output, cursor, LABEL_EXECUTION, true);
    cursor = writeJsonRange(input, starts[8], lengths[8], output, cursor);
    cursor = writeLabel(output, cursor, LABEL_COVERAGE, true);
    cursor = writeJsonRange(input, starts[9], lengths[9], output, cursor);
    setByte(output, cursor, 125);
    return cursor + 1;
  }

  /// Renders one complete canonical row transport and returns its exact byte length.
  public long renderTestReportJson(borrow byteview input, borrow mut bytes output) {
    AdapterHeader header = validatedTestReportAdapter(input);

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
    cursor = writeTestReportIdentity(input, 0, output, cursor + 1);
    setByte(output, cursor, 34);
    cursor = writeLabel(output, cursor + 1, LABEL_SUBJECT, true);
    cursor = writeJsonRange(
      input,
      header.subjectStart,
      header.subjectLength,
      output,
      cursor
    );
    cursor = writeLabel(output, cursor, LABEL_SELECTED, true);
    cursor = writeTestReportDecimal(output, cursor, header.selected);
    cursor = writeLabel(output, cursor, LABEL_PASSED, true);
    cursor = writeTestReportDecimal(output, cursor, header.passed);
    cursor = writeLabel(output, cursor, LABEL_FAILED, true);
    cursor = writeTestReportDecimal(output, cursor, header.failed);
    cursor = writeLabel(output, cursor, LABEL_CASES, true);
    setByte(output, cursor, 91);
    cursor += 1;

    long inputCursor = header.rowStart;
    long row = 0;
    while (row < header.selected) limit MAX_CASES {
      if (0 < row) {
        setByte(output, cursor, 44);
        cursor += 1;
      }

      AdapterRow adapterRow = validatedTestReportRow(
        input,
        inputCursor,
        starts,
        lengths
      );
      cursor = writeCase(
        input,
        adapterRow,
        starts,
        lengths,
        output,
        cursor,
        summary
      );
      inputCursor = adapterRow.end;
      row += 1;
    }

    assert(inputCursor == bufferLength(input));
    assert(summary[0] == header.selected);
    assert(summary[1] == header.passed);
    assert(summary[2] == header.failed);
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
