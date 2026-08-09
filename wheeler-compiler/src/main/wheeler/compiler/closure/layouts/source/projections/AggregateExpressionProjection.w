//! Replaces aggregate source expressions with primitive frontend placeholders.

module wheeler.compiler.closure.aggregate_expression_projection;

classical class AggregateExpressionProjection {
  private const long MAX_OPERATIONS = 256;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long OPERATION_ROWS = 2048;

  /// Copies source and replaces each outer aggregate expression with one scalar literal.
  public long writeSourceWithoutAggregateExpressions(
    borrow byteview source,
    long sourceStart,
    long sourceLength,
    long operationCount,
    borrow mut words operationRows,
    borrow mut bytes output
  ) {
    assert(-1 < sourceStart);
    assert(-1 < sourceLength);
    assert(sourceStart < bufferLength(source) + 1);
    assert(sourceLength < bufferLength(source) - sourceStart + 1);
    assert(sourceLength < MAX_SOURCE_BYTES + 1);
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);

    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long start = operationRows[1280 + operation];
      long length = operationRows[1536 + operation];
      assert(-1 < start);
      assert(0 < length);
      assert(start < sourceLength);
      assert(length < sourceLength - start + 1);
      long candidate = 0;
      while (candidate < operation) limit MAX_OPERATIONS {
        long candidateStart = operationRows[1280 + candidate];
        long candidateEnd = candidateStart + operationRows[1536 + candidate];
        long end = start + length;
        boolean disjoint = end < candidateStart + 1;
        if (candidateEnd < start + 1) {
          disjoint = true;
        }

        boolean contains = start < candidateStart + 1;
        if (candidateEnd < end + 1) {} else {
          contains = false;
        }

        boolean contained = candidateStart < start + 1;
        if (end < candidateEnd + 1) {} else {
          contained = false;
        }

        boolean nestedShape = disjoint;
        if (contains) {
          nestedShape = true;
        }

        if (contained) {
          nestedShape = true;
        }

        assert(nestedShape);
        boolean duplicate = start == candidateStart;
        if (end != candidateEnd) {
          duplicate = false;
        }

        assert(duplicate == false);
        candidate += 1;
      }

      operation += 1;
    }

    long sourceByte = 0;
    while (sourceByte < sourceLength) limit MAX_SOURCE_BYTES {
      setByte(output, sourceByte, source[sourceStart + sourceByte]);
      sourceByte += 1;
    }

    operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long selectedStart = operationRows[1280 + operation];
      long selectedEnd = selectedStart + operationRows[1536 + operation];
      boolean nested = false;
      long owner = 0;
      while (owner < operationCount) limit MAX_OPERATIONS {
        if (owner != operation) {
          long ownerStart = operationRows[1280 + owner];
          long ownerEnd = ownerStart + operationRows[1536 + owner];
          if (ownerStart < selectedStart + 1) {
            if (selectedEnd < ownerEnd + 1) {
              nested = true;
            }
          }
        }

        owner += 1;
      }

      if (nested == false) {
        setByte(output, selectedStart, 48);
        long blank = selectedStart + 1;
        while (blank < selectedEnd) limit MAX_SOURCE_BYTES {
          if (output[blank] != 10) {
            setByte(output, blank, 32);
          }

          blank += 1;
        }
      }

      operation += 1;
    }

    return sourceLength;
  }
}
