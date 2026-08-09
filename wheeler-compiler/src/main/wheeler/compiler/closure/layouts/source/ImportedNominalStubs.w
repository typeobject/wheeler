//! Generates deterministic nominal declarations and projection rows.

module wheeler.compiler.closure.imported_nominal_stubs;

classical class ImportedNominalStubs {
  private const long AGGREGATE_ROWS = 36864;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long MAX_STUBS = 64;
  private const long PROJECTION_ROWS = 49152;
  private const long STAGING_BYTES = 458752;

  /// Reports exact temporary source and projection extents.
  public record ImportedNominalStubPlan(long length, long stubCount, long projectionCount) {}

  private boolean reservedPrefixAt(borrow byteview source, long start, long end) {
    if (13 < end - start) {
      long[14] generated = new long[14](
        87,
        104,
        101,
        101,
        108,
        101,
        114,
        78,
        111,
        109,
        105,
        110,
        97,
        108
      );
      long generatedOffset = 0;
      boolean generatedMatch = true;
      while (generatedOffset < 14) limit 14 {
        if (source[start + generatedOffset] != generated[generatedOffset]) {
          generatedMatch = false;
        }

        generatedOffset += 1;
      }

      if (generatedMatch) {
        return true;
      }
    }

    if (17 < end - start) {
      long[18] reserved = new long[18](
        95,
        95,
        119,
        104,
        101,
        101,
        108,
        101,
        114,
        95,
        110,
        111,
        109,
        105,
        110,
        97,
        108,
        95
      );
      long reservedOffset = 0;
      while (reservedOffset < 18) limit 18 {
        if (source[start + reservedOffset] != reserved[reservedOffset]) {
          return false;
        }

        reservedOffset += 1;
      }

      return true;
    }

    return false;
  }

  private long writeRange(
    borrow byteview source,
    long start,
    long length,
    borrow mut bytes output,
    long cursor
  ) {
    assert(-1 < start);
    assert(-1 < length);
    assert(start < bufferLength(source) + 1);
    assert(length < bufferLength(source) - start + 1);
    assert(cursor < bufferLength(output) + 1);
    assert(length < bufferLength(output) - cursor + 1);
    long offset = 0;
    while (offset < length) limit MAX_SOURCE_BYTES {
      setByte(output, cursor + offset, source[start + offset]);
      offset += 1;
    }

    return cursor + length;
  }

  private long writeName(long target, borrow mut bytes output, long cursor) {
    assert(-1 < target);
    assert(target < MAX_AGGREGATES);
    assert(cursor < MAX_SOURCE_BYTES - 18);
    writeAscii(output, cursor, "WheelerNominal");
    cursor += 14;
    long divisor = 1;
    while (divisor < target / 10 + 1) limit 4 {
      divisor = divisor * 10;
    }

    if (target < divisor) {
      divisor = divisor / 10;
    }

    if (divisor == 0) {
      divisor = 1;
    }

    boolean writing = true;
    while (writing) limit 4 {
      setByte(output, cursor, target / divisor % 10 + 48);
      cursor += 1;
      if (divisor == 1) {
        writing = false;
      } else {
        divisor = divisor / 10;
      }
    }

    return cursor;
  }

  /// Appends sorted record and variant scaffolding before one class close.
  public ImportedNominalStubPlan writeImportedNominalStubs(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    long moduleOwner,
    long firstRecordTypeId,
    long firstVariantTypeId,
    long targetCount,
    borrow mut words targetRows,
    borrow mut words aggregateRows,
    borrow mut words projectionRows,
    borrow mut bytes output
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceStart < bufferLength(source));
    assert(sourceLength < bufferLength(source) - sourceStart + 1);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < firstRecordTypeId);
    assert(-1 < firstVariantTypeId);
    assert(-1 < targetCount);
    assert(targetCount < MAX_STUBS + 1);
    assert(bufferLength(targetRows) == MAX_STUBS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);

    long scan = sourceStart;
    while (scan < sourceStart + sourceLength) limit MAX_SOURCE_BYTES {
      assert(reservedPrefixAt(source, scan, sourceStart + sourceLength) == false);
      scan += 1;
    }

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 3);
    bytes stagedSource = allocateBytes(staging, MAX_SOURCE_BYTES);
    words selectedTargets = allocate(staging, MAX_AGGREGATES);
    words stagedProjections = allocate(staging, PROJECTION_ROWS);
    long targetOffset = 0;
    while (targetOffset < targetCount) limit MAX_STUBS {
      long selectedTarget = targetRows[targetOffset];
      assert(-1 < selectedTarget);
      assert(selectedTarget < MAX_AGGREGATES);
      assert(selectedTargets[selectedTarget] == 0);
      long kind = aggregateRows[selectedTarget];
      boolean kindValid = kind == 1;
      if (kind == 4) {
        kindValid = true;
      }

      assert(kindValid);
      set(selectedTargets, selectedTarget, 1);
      targetOffset += 1;
    }

    long cursor = writeRange(source, sourceStart, sourceLength, stagedSource, /* cursor= */ 0);
    long closing = cursor;
    while (0 < closing) limit MAX_SOURCE_BYTES {
      closing -= 1;
      if (stagedSource[closing] == 125) {
        break;
      }
    }

    assert(stagedSource[closing] == 125);
    cursor = closing;

    long recordTypeId = firstRecordTypeId;
    long variantTypeId = firstVariantTypeId;
    long projectionCount = 0;
    long target = 0;
    while (target < MAX_AGGREGATES) limit MAX_AGGREGATES {
      if (selectedTargets[target] == 1) {
        long selectedKind = aggregateRows[target];
        long sourceCode = 0;
        if (selectedKind == 1) {
          writeAscii(stagedSource, cursor, " private record ");
          cursor += 16;
          cursor = writeName(target, stagedSource, cursor);
          writeAscii(stagedSource, cursor, "(long value) {}");
          cursor += 15;
          sourceCode = 268435456 + recordTypeId;
          recordTypeId += 1;
        }

        if (selectedKind == 4) {
          writeAscii(stagedSource, cursor, " private variant ");
          cursor += 17;
          cursor = writeName(target, stagedSource, cursor);
          writeAscii(stagedSource, cursor, " { case Value(long value); }");
          cursor += 28;
          sourceCode = 536870912 + variantTypeId;
          variantTypeId += 1;
        }

        assert(0 < sourceCode);
        set(stagedProjections, projectionCount, moduleOwner);
        set(stagedProjections, 16384 + projectionCount, sourceCode);
        set(stagedProjections, 32768 + projectionCount, target);
        projectionCount += 1;
      }

      target += 1;
    }

    assert(projectionCount == targetCount);
    writeAscii(stagedSource, cursor, " }");
    cursor += 2;

    long outputByte = 0;
    while (outputByte < cursor) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, stagedSource[outputByte]);
      outputByte += 1;
    }

    long projectionRow = 0;
    while (projectionRow < PROJECTION_ROWS) limit PROJECTION_ROWS {
      set(projectionRows, projectionRow, stagedProjections[projectionRow]);
      projectionRow += 1;
    }

    drop(stagedProjections);
    drop(selectedTargets);
    drop(stagedSource);
    drop(staging);
    return new ImportedNominalStubPlan(cursor, targetCount, projectionCount);
  }
}
