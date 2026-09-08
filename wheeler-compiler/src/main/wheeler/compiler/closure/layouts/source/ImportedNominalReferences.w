//! Rewrites resolved imported nominal ranges and inserts declarations before first use.

module wheeler.compiler.closure.imported_nominal_references;

import wheeler.compiler.closure.imported_nominal_stubs;

classical class ImportedNominalReferences {
  private const long AGGREGATE_ROWS = 36864;
  private const long CALL_ROWS = 1024;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_CALLS = 256;
  private const long MAX_REFERENCES = 64;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long PROJECTION_COLUMN_ROWS = 16384;
  private const long PROJECTION_ROWS = 49152;
  private const long REFERENCE_ROWS = 256;
  private const long STAGING_BYTES = 492032;

  /// Reports exact rewritten source, generated declaration, and projection extents.
  public record ImportedNominalReferencePlan(long length, long stubCount, long projectionCount) {}

  /// Reports the exact primitive-carrier source extent.
  public record ImportedNominalCarrierPlan(long length, long referenceCount) {}

  private long decimalDigits(long value) {
    assert(-1 < value);
    if (value < 10) {
      return 1;
    }

    if (value < 100) {
      return 2;
    }

    if (value < 1000) {
      return 3;
    }

    return 4;
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

  private long adjustedReferenceStart(
    long referenceStart,
    long referenceLength,
    long callCount,
    borrow mut words callRows
  ) {
    long adjustment = 0;
    long call = 0;
    while (call < callCount) limit MAX_CALLS {
      long callStart = callRows[call];
      long callLength = callRows[256 + call];
      long callTarget = callRows[768 + call];
      assert(-1 < callStart);
      assert(0 < callLength);
      assert(-1 < callTarget);
      assert(callTarget < MAX_AGGREGATES);
      if (callStart + callLength < referenceStart + 1) {
        adjustment += 17 + decimalDigits(callTarget) - callLength;
      } else {
        assert(referenceStart + referenceLength < callStart + 1);
      }

      call += 1;
    }

    return referenceStart + adjustment;
  }

  /// Rewrites resolved ranges to temporary signed carriers for the bounded compiler core.
  public ImportedNominalCarrierPlan writeImportedNominalCarriers(
    borrow byteview authoredSource,
    long sourceStart,
    long sourceLength,
    borrow byteview callableSource,
    long callableSourceStart,
    long callableSourceLength,
    long referenceCount,
    borrow mut words referenceRows,
    long callCount,
    borrow mut words callRows,
    borrow mut words aggregateRows,
    borrow mut bytes output
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceStart < bufferLength(authoredSource));
    assert(sourceLength < bufferLength(authoredSource) - sourceStart + 1);
    assert(-1 < callableSourceStart);
    assert(0 < callableSourceLength);
    assert(callableSourceStart < bufferLength(callableSource));
    assert(callableSourceLength < bufferLength(callableSource) - callableSourceStart + 1);
    assert(-1 < referenceCount);
    assert(referenceCount < MAX_REFERENCES + 1);
    assert(bufferLength(referenceRows) == REFERENCE_ROWS);
    assert(-1 < callCount);
    assert(callCount < MAX_CALLS + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);

    requireImportedNominalNamespace(authoredSource, sourceStart, sourceLength);

    region staging = new region(/* bytes= */ 33280, /* allocations= */ 2);
    bytes stagedSource = allocateBytes(staging, MAX_SOURCE_BYTES);
    words adjustedStarts = allocate(staging, MAX_REFERENCES);
    long previousEnd = 0;
    long reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long referenceStart = referenceRows[reference];
      long referenceLength = referenceRows[64 + reference];
      long target = referenceRows[128 + reference];
      long expectedKind = referenceRows[192 + reference];
      assert(previousEnd < referenceStart + 1);
      assert(-1 < referenceStart);
      assert(0 < referenceLength);
      assert(referenceStart < sourceLength);
      assert(referenceLength < sourceLength - referenceStart + 1);
      assert(-1 < target);
      assert(target < MAX_AGGREGATES);
      assert(aggregateRows[target] == expectedKind);
      boolean kindValid = expectedKind == 1;
      if (expectedKind == 4) {
        kindValid = true;
      }

      assert(kindValid);

      long adjusted = adjustedReferenceStart(
        referenceStart,
        referenceLength,
        callCount,
        callRows
      );
      assert(adjusted < callableSourceLength);
      assert(referenceLength < callableSourceLength - adjusted + 1);
      long nameByte = 0;
      while (nameByte < referenceLength) limit MAX_SOURCE_BYTES {
        assert(
          callableSource[callableSourceStart + adjusted + nameByte] == authoredSource[sourceStart
            + referenceStart + nameByte]
        );
        nameByte += 1;
      }

      set(adjustedStarts, reference, adjusted);
      previousEnd = referenceStart + referenceLength;
      reference += 1;
    }

    long cursor = 0;
    long callableCursor = 0;
    reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long adjustedWriteStart = adjustedStarts[reference];
      cursor = writeRange(
        callableSource,
        callableSourceStart + callableCursor,
        adjustedWriteStart - callableCursor,
        stagedSource,
        cursor
      );
      writeAscii(stagedSource, cursor, "long");
      cursor += 4;
      callableCursor = adjustedWriteStart + referenceRows[64 + reference];
      reference += 1;
    }

    cursor = writeRange(
      callableSource,
      callableSourceStart + callableCursor,
      callableSourceLength - callableCursor,
      stagedSource,
      cursor
    );

    long outputByte = 0;
    while (outputByte < cursor) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, stagedSource[outputByte]);
      outputByte += 1;
    }

    drop(adjustedStarts);
    drop(stagedSource);
    drop(staging);
    return new ImportedNominalCarrierPlan(cursor, referenceCount);
  }

  /// Rewrites sorted resolved ranges after callable rewriting and inserts sorted stubs.
  public ImportedNominalReferencePlan writeImportedNominalReferences(
    borrow byteview authoredSource,
    long sourceStart,
    long sourceLength,
    borrow byteview callableSource,
    long callableSourceStart,
    long callableSourceLength,
    long moduleOwner,
    long firstRecordTypeId,
    long firstVariantTypeId,
    long referenceCount,
    borrow mut words referenceRows,
    long callCount,
    borrow mut words callRows,
    borrow mut words aggregateRows,
    borrow mut words projectionRows,
    borrow mut bytes output
  ) {
    assert(-1 < sourceStart);
    assert(0 < sourceLength);
    assert(sourceStart < bufferLength(authoredSource));
    assert(sourceLength < bufferLength(authoredSource) - sourceStart + 1);
    assert(-1 < callableSourceStart);
    assert(0 < callableSourceLength);
    assert(callableSourceStart < bufferLength(callableSource));
    assert(callableSourceLength < bufferLength(callableSource) - callableSourceStart + 1);
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < firstRecordTypeId);
    assert(-1 < firstVariantTypeId);
    assert(-1 < referenceCount);
    assert(referenceCount < MAX_REFERENCES + 1);
    assert(bufferLength(referenceRows) == REFERENCE_ROWS);
    assert(-1 < callCount);
    assert(callCount < MAX_CALLS + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);

    requireImportedNominalNamespace(authoredSource, sourceStart, sourceLength);

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 5);
    bytes stagedSource = allocateBytes(staging, MAX_SOURCE_BYTES);
    bytes declarations = allocateBytes(staging, MAX_SOURCE_BYTES);
    words adjustedStarts = allocate(staging, MAX_REFERENCES);
    words selectedTargets = allocate(staging, MAX_AGGREGATES);
    words stagedProjections = allocate(staging, PROJECTION_ROWS);
    long previousEnd = 0;
    long reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long referenceStart = referenceRows[reference];
      long referenceLength = referenceRows[64 + reference];
      long validationTarget = referenceRows[128 + reference];
      long expectedKind = referenceRows[192 + reference];
      assert(previousEnd < referenceStart + 1);
      assert(-1 < referenceStart);
      assert(0 < referenceLength);
      assert(referenceStart < sourceLength);
      assert(referenceLength < sourceLength - referenceStart + 1);
      assert(-1 < validationTarget);
      assert(validationTarget < MAX_AGGREGATES);
      assert(aggregateRows[validationTarget] == expectedKind);
      boolean kindValid = expectedKind == 1;
      if (expectedKind == 4) {
        kindValid = true;
      }

      assert(kindValid);

      long adjusted = adjustedReferenceStart(
        referenceStart,
        referenceLength,
        callCount,
        callRows
      );
      assert(adjusted < callableSourceLength);
      assert(referenceLength < callableSourceLength - adjusted + 1);
      long nameByte = 0;
      while (nameByte < referenceLength) limit MAX_SOURCE_BYTES {
        assert(
          callableSource[callableSourceStart + adjusted + nameByte] == authoredSource[sourceStart
            + referenceStart + nameByte]
        );
        nameByte += 1;
      }

      set(adjustedStarts, reference, adjusted);
      set(selectedTargets, validationTarget, 1);
      previousEnd = referenceStart + referenceLength;
      reference += 1;
    }

    long cursor = 0;
    long callableCursor = 0;
    reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long adjustedWriteStart = adjustedStarts[reference];
      cursor = writeRange(
        callableSource,
        callableSourceStart + callableCursor,
        adjustedWriteStart - callableCursor,
        stagedSource,
        cursor
      );
      cursor = writeImportedNominalName(referenceRows[128 + reference], stagedSource, cursor);
      callableCursor = adjustedWriteStart + referenceRows[64 + reference];
      reference += 1;
    }

    cursor = writeRange(
      callableSource,
      callableSourceStart + callableCursor,
      callableSourceLength - callableCursor,
      stagedSource,
      cursor
    );

    long opening = 0;
    while (opening < cursor) limit MAX_SOURCE_BYTES {
      if (stagedSource[opening] == 123) {
        break;
      }

      opening += 1;
    }

    assert(opening < cursor);

    ImportedNominalDeclarationFragment fragment = writeImportedNominalDeclarations(
      moduleOwner,
      firstRecordTypeId,
      firstVariantTypeId,
      selectedTargets,
      aggregateRows,
      stagedProjections,
      declarations,
      0
    );
    long declarationCursor = fragment.length;
    long projectionCount = fragment.projectionCount;

    long finalLength = cursor + declarationCursor;
    assert(finalLength < MAX_SOURCE_BYTES + 1);
    long outputByte = 0;
    while (outputByte < opening + 1) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, stagedSource[outputByte]);
      outputByte += 1;
    }

    long declarationByte = 0;
    while (declarationByte < declarationCursor) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, declarations[declarationByte]);
      outputByte += 1;
      declarationByte += 1;
    }

    long tailByte = opening + 1;
    while (tailByte < cursor) limit MAX_SOURCE_BYTES {
      setByte(output, outputByte, stagedSource[tailByte]);
      outputByte += 1;
      tailByte += 1;
    }

    long projectionColumn = 0;
    while (projectionColumn < 3) limit 3 {
      long projectionRow = 0;
      while (projectionRow < projectionCount) limit MAX_AGGREGATES {
        set(
          projectionRows,
          projectionColumn * PROJECTION_COLUMN_ROWS + projectionRow,
          stagedProjections[projectionColumn * PROJECTION_COLUMN_ROWS + projectionRow]
        );
        projectionRow += 1;
      }

      projectionColumn += 1;
    }

    drop(stagedProjections);
    drop(selectedTargets);
    drop(adjustedStarts);
    drop(declarations);
    drop(stagedSource);
    drop(staging);
    return new ImportedNominalReferencePlan(finalLength, projectionCount, projectionCount);
  }
}
