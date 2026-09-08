//! Emits checked nominal declaration fragments and standalone source scaffolding.

module wheeler.compiler.closure.imported_nominal_stubs;

classical class ImportedNominalStubs {
  private const long AGGREGATE_ROWS = 36864;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long MAX_STUBS = 64;
  private const long PROJECTION_COLUMN_ROWS = 16384;
  private const long PROJECTION_ROWS = 49152;
  private const long STAGING_BYTES = 458752;
  private const long TYPE_ID_LIMIT = 268435456;

  /// Reports exact temporary source and projection extents.
  public record ImportedNominalStubPlan(long length, long stubCount, long projectionCount) {}

  /// Reports appended declaration bytes and counted projection rows, excluding any byte prefix.
  public record ImportedNominalDeclarationFragment(long length, long projectionCount) {}

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
      long offset = 0;
      boolean matches = true;
      while (offset < 14) limit 14 {
        if (source[start + offset] != generated[offset]) {
          matches = false;
        }

        offset += 1;
      }

      if (matches) {
        return true;
      }
    }

    if (17 < end - start) {
      long[18] internal = new long[18](
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
      long internalOffset = 0;
      while (internalOffset < 18) limit 18 {
        if (source[start + internalOffset] != internal[internalOffset]) {
          return false;
        }

        internalOffset += 1;
      }

      return true;
    }

    return false;
  }

  /// Rejects reserved generated markers in one complete bounded authored source window.
  public void requireImportedNominalNamespace(borrow byteview source, long start, long length) {
    assert(-1 < start);
    assert(0 < length);
    assert(length < MAX_SOURCE_BYTES + 1);
    assert(start < bufferLength(source));
    assert(length < bufferLength(source) - start + 1);
    long offset = 0;
    while (offset < length) limit MAX_SOURCE_BYTES {
      long scalar = source[start + offset];
      boolean candidate = scalar == 87;
      if (scalar == 95) {
        candidate = true;
      }

      if (candidate) {
        assert(reservedPrefixAt(source, start + offset, start + length) == false);
      }

      offset += 1;
    }
  }

  private long nameLength(long target) {
    assert(-1 < target);
    assert(target < MAX_AGGREGATES);
    if (target < 10) {
      return 15;
    }

    if (target < 100) {
      return 16;
    }

    if (target < 1000) {
      return 17;
    }

    return 18;
  }

  private void requireByteWindow(borrow mut bytes output, long start, long length) {
    assert(bufferLength(output) < MAX_SOURCE_BYTES + 1);
    assert(-1 < start);
    assert(start < bufferLength(output) + 1);
    assert(-1 < length);
    assert(length < bufferLength(output) - start + 1);
  }

  /// Writes one complete deterministic generated name after checking its exact byte window.
  public long writeImportedNominalName(long target, borrow mut bytes output, long cursor) {
    requireByteWindow(output, cursor, nameLength(target));
    writeAscii(output, cursor, "WheelerNominal");
    cursor += 14;
    long divisor = 1;
    while (divisor < target / 10 + 1) limit 3 {
      divisor = divisor * 10;
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

  private void requireTypeWindow(long first, long count) {
    assert(-1 < first);
    assert(first < TYPE_ID_LIMIT + 1);
    assert(count < TYPE_ID_LIMIT - first + 1);
  }

  /// Publishes sorted declarations and projections only after the entire selection validates.
  /// Selection bits, record and variant ID windows, and output extents are independent.
  public ImportedNominalDeclarationFragment writeImportedNominalDeclarations(
    long moduleOwner,
    long firstRecordTypeId,
    long firstVariantTypeId,
    borrow mut words selectedTargets,
    borrow mut words aggregateRows,
    borrow mut words projectionRows,
    borrow mut bytes output,
    long outputStart
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(bufferLength(selectedTargets) == MAX_AGGREGATES);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    long recordCount = 0;
    long variantCount = 0;
    long byteCount = 0;
    long target = 0;
    while (target < MAX_AGGREGATES) limit MAX_AGGREGATES {
      long selected = selectedTargets[target];
      if (selected == 1) {
        long kind = aggregateRows[target];
        if (kind == 1) {
          recordCount += 1;
          byteCount += 31 + nameLength(target);
        } else {
          assert(kind == 4);
          variantCount += 1;
          byteCount += 45 + nameLength(target);
        }

        assert(recordCount + variantCount < MAX_STUBS + 1);
      } else {
        assert(selected == 0);
      }

      target += 1;
    }

    requireTypeWindow(firstRecordTypeId, recordCount);
    requireTypeWindow(firstVariantTypeId, variantCount);
    requireByteWindow(output, outputStart, byteCount);

    long cursor = outputStart;
    long recordId = firstRecordTypeId;
    long variantId = firstVariantTypeId;
    long projection = 0;
    target = 0;
    while (target < MAX_AGGREGATES) limit MAX_AGGREGATES {
      if (selectedTargets[target] == 1) {
        long emittedKind = aggregateRows[target];
        long sourceCode = 0;
        if (emittedKind == 1) {
          writeAscii(output, cursor, " private record ");
          cursor += 16;
          cursor = writeImportedNominalName(target, output, cursor);
          writeAscii(output, cursor, "(long value) {}");
          cursor += 15;
          sourceCode = 268435456 + recordId;
          recordId += 1;
        } else {
          writeAscii(output, cursor, " private variant ");
          cursor += 17;
          cursor = writeImportedNominalName(target, output, cursor);
          writeAscii(output, cursor, " { case Value(long value); }");
          cursor += 28;
          sourceCode = 536870912 + variantId;
          variantId += 1;
        }

        set(projectionRows, projection, moduleOwner);
        set(projectionRows, PROJECTION_COLUMN_ROWS + projection, sourceCode);
        set(projectionRows, 2 * PROJECTION_COLUMN_ROWS + projection, target);
        projection += 1;
      }

      target += 1;
    }

    assert(cursor - outputStart == byteCount);
    return new ImportedNominalDeclarationFragment(byteCount, projection);
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
    requireByteWindow(output, cursor, length);
    long offset = 0;
    while (offset < length) limit MAX_SOURCE_BYTES {
      setByte(output, cursor + offset, source[start + offset]);
      offset += 1;
    }

    return cursor + length;
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
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < targetCount);
    assert(targetCount < MAX_STUBS + 1);
    assert(bufferLength(targetRows) == MAX_STUBS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);
    requireImportedNominalNamespace(source, sourceStart, sourceLength);

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
      set(selectedTargets, selectedTarget, 1);
      targetOffset += 1;
    }

    long cursor = writeRange(source, sourceStart, sourceLength, stagedSource, 0);
    long closing = cursor;
    while (0 < closing) limit MAX_SOURCE_BYTES {
      closing -= 1;
      if (stagedSource[closing] == 125) {
        break;
      }
    }

    assert(stagedSource[closing] == 125);
    ImportedNominalDeclarationFragment fragment = writeImportedNominalDeclarations(
      moduleOwner,
      firstRecordTypeId,
      firstVariantTypeId,
      selectedTargets,
      aggregateRows,
      stagedProjections,
      stagedSource,
      closing
    );
    cursor = closing + fragment.length;
    requireByteWindow(stagedSource, cursor, 2);
    writeAscii(stagedSource, cursor, " }");
    cursor += 2;
    assert(fragment.projectionCount == targetCount);
    long outputByte = 0;
    while (outputByte < cursor) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, stagedSource[outputByte]);
      outputByte += 1;
    }

    long column = 0;
    while (column < 3) limit 3 {
      long row = 0;
      while (row < fragment.projectionCount) limit MAX_STUBS {
        set(
          projectionRows,
          column * PROJECTION_COLUMN_ROWS + row,
          stagedProjections[column * PROJECTION_COLUMN_ROWS + row]
        );
        row += 1;
      }

      column += 1;
    }

    drop(stagedProjections);
    drop(selectedTargets);
    drop(stagedSource);
    drop(staging);
    return new ImportedNominalStubPlan(cursor, targetCount, fragment.projectionCount);
  }
}
