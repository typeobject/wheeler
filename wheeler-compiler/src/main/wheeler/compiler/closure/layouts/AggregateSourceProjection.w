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
    assert(aggregateCount < 65);
    long aggregateRowLength = bufferLength(aggregateRows);
    assert(aggregateRowLength == 832);
    long outputLength = bufferLength(output);
    assert(outputLength == 32768);
    assert(-1 < sourceStart);
    assert(-1 < sourceLength);
    long sourceBufferLength = bufferLength(source);
    assert(sourceLength < 32769);
    long checkedIndex = sourceStart;
    long checkedByte = 0;
    while (checkedByte < sourceLength) limit 32768 {
      assert(checkedIndex < sourceBufferLength);
      checkedIndex += 1;
      checkedByte += 1;
    }

    long previousEnd = 0;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit 64 {
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
      long startLimit = start;
      startLimit += 1;
      long end = aggregateRows[768 + aggregate];
      long endProbe = end;
      endProbe -= 1;
      assert(-1 < start);
      assert(start < end);
      assert(endProbe < sourceLength);
      if (kind == 1) {
        assert(previousEnd < startLimit);
        previousEnd = end;
      }

      if (kind == 4) {
        assert(previousEnd < startLimit);
        previousEnd = end;
      }

      aggregate += 1;
    }

    long sourceByte = 0;
    while (sourceByte < sourceLength) limit 32768 {
      setByte(output, sourceByte, source[sourceStart + sourceByte]);
      sourceByte += 1;
    }

    long declarationByte = 0;
    long declarationEnd = 0;
    long projectedAggregate = 0;
    while (projectedAggregate < aggregateCount) limit 64 {
      long selectedKind = aggregateRows[projectedAggregate];
      boolean declaration = selectedKind == 1;
      if (selectedKind == 4) {
        declaration = true;
      }

      long selectedStart = aggregateRows[512 + projectedAggregate];
      long selectedEnd = aggregateRows[768 + projectedAggregate];
      declarationByte = selectedStart;
      declarationEnd = declarationByte;
      if (declaration) {
        declarationEnd = selectedEnd;
      }

      projectedAggregate += 1;
      while (declarationByte < declarationEnd) limit 32768 {
        long declarationScalar = output[declarationByte];
        declarationScalar = 32;
        setByte(output, declarationByte, declarationScalar);
        declarationByte += 1;
      }
    }

    long restoreByte = 0;
    long sourceIndex = sourceStart;
    while (restoreByte < sourceLength) limit 32768 {
      long sourceScalar = source[sourceIndex];
      if (sourceScalar == 10) {
        setByte(output, restoreByte, sourceScalar);
      }

      restoreByte += 1;
      sourceIndex += 1;
    }

    return sourceLength;
  }
}
