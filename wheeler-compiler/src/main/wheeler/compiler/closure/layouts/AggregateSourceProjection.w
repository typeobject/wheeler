//! Removes validated aggregate declarations from temporary compiler source.

module wheeler.compiler.closure.aggregate_source_projection;

classical class AggregateSourceProjection {
  private const long AGGREGATE_ROWS = 832;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_SOURCE_BYTES = 32768;

  /// Copies source while blanking record and variant declarations at stable offsets.
  public long writeSourceWithoutAggregateDeclarations(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    long aggregateCount,
    borrow mut words aggregateRows,
    borrow mut bytes output
  ) {
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);
    assert(-1 < sourceStart);
    assert(-1 < sourceLength);
    assert(sourceStart < bufferLength(source) + 1);
    assert(sourceLength < bufferLength(source) - sourceStart + 1);
    assert(sourceLength < MAX_SOURCE_BYTES + 1);

    long previousEnd = 0;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long kind = aggregateRows[aggregate];
      boolean kindValid = kind == 1;
      if (kind == 2) {
        kindValid = true;
      }

      if (kind == 4) {
        kindValid = true;
      }

      assert(kindValid);
      long start = aggregateRows[512 + aggregate];
      long end = aggregateRows[768 + aggregate];
      assert(-1 < start);
      assert(start < end);
      assert(end < sourceLength + 1);
      if (kind == 1) {
        assert(previousEnd < start + 1);
        previousEnd = end;
      }

      if (kind == 4) {
        assert(previousEnd < start + 1);
        previousEnd = end;
      }

      aggregate += 1;
    }

    long sourceByte = 0;
    while (sourceByte < sourceLength) limit MAX_SOURCE_BYTES {
      setByte(output, sourceByte, source[sourceStart + sourceByte]);
      sourceByte += 1;
    }

    aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES {
      long selectedKind = aggregateRows[aggregate];
      boolean declaration = selectedKind == 1;
      if (selectedKind == 4) {
        declaration = true;
      }

      if (declaration) {
        long declarationByte = aggregateRows[512 + aggregate];
        long declarationEnd = aggregateRows[768 + aggregate];
        while (declarationByte < declarationEnd) limit MAX_SOURCE_BYTES {
          if (output[declarationByte] != 10) {
            setByte(output, declarationByte, 32);
          }

          declarationByte += 1;
        }
      }

      aggregate += 1;
    }

    return sourceLength;
  }
}
