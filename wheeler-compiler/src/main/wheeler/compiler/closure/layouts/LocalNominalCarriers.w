//! Rewrites validated source-local nominal references to temporary signed carriers.

module wheeler.compiler.closure.local_nominal_carriers;

classical class LocalNominalCarriers {
  private const long CARRIER_ROWS = 2048;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_REFERENCES = 512;
  private const long MAX_SOURCE_BYTES = 32768;
  private const long PROJECTION_ROWS = 4096;
  private const long REFERENCE_ROWS = 1536;

  /// Reports compact carrier source and exact old-to-new reference coordinates.
  public record LocalNominalCarrierPlan(long length, long referenceCount, boolean valid) {}

  private boolean identifierByte(long value, boolean first) {
    if (64 < value) {
      if (value < 91) {
        return true;
      }
    }

    if (96 < value) {
      if (value < 123) {
        return true;
      }
    }

    if (value == 95) {
      return true;
    }

    if (first == false) {
      if (47 < value) {
        return value < 58;
      }
    }

    return false;
  }

  /// Publishes carrier source only after every sorted identifier range and extent validates.
  public LocalNominalCarrierPlan writeLocalNominalCarriers(
    borrow byteview source,
    long sourceLength,
    long referenceCount,
    borrow mut words referenceRows,
    borrow mut words projectionRows,
    borrow mut words carrierRows,
    borrow mut bytes output
  ) {
    assert(-1 < sourceLength);
    assert(sourceLength < MAX_SOURCE_BYTES + 1);
    assert(sourceLength < bufferLength(source) + 1);
    assert(-1 < referenceCount);
    assert(referenceCount < MAX_REFERENCES + 1);
    assert(bufferLength(referenceRows) == REFERENCE_ROWS);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(carrierRows) == CARRIER_ROWS);
    assert(bufferLength(output) == MAX_SOURCE_BYTES);
    boolean valid = true;
    long finalLength = sourceLength;
    long previousEnd = 0;
    long reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long target = referenceRows[reference];
      long start = referenceRows[512 + reference];
      long length = referenceRows[1024 + reference];
      long role = projectionRows[512 + reference];
      if (projectionRows[reference] != target) {
        valid = false;
      }

      if (projectionRows[2048 + reference] != start) {
        valid = false;
      }

      if (projectionRows[2560 + reference] != length) {
        valid = false;
      }

      if (role < 1) {
        valid = false;
      }

      if (3 < role) {
        valid = false;
      }

      if (target < 0) {
        valid = false;
      }

      if (MAX_AGGREGATES < target + 1) {
        valid = false;
      }

      if (start < previousEnd) {
        valid = false;
      }

      if (start < 0) {
        valid = false;
      }

      if (length < 1) {
        valid = false;
      }

      if (sourceLength < start) {
        valid = false;
      } else {
        if (sourceLength - start < length) {
          valid = false;
        }
      }

      if (valid) {
        if (role != 2) {
          long nameByte = 0;
          while (nameByte < length) limit 256 {
            if (identifierByte(source[start + nameByte], nameByte == 0) == false) {
              valid = false;
            }

            nameByte += 1;
          }
        }
      }

      if (role != 2) {
        finalLength += 4 - length;
      }

      previousEnd = start + length;
      reference += 1;
    }

    if (finalLength < 0) {
      valid = false;
    }

    if (MAX_SOURCE_BYTES < finalLength) {
      valid = false;
    }

    if (valid == false) {
      return new LocalNominalCarrierPlan(0, referenceCount, false);
    }

    region staging = new region(/* bytes= */ 81920, /* allocations= */ 3);
    bytes stagedSource = allocateBytes(staging, MAX_SOURCE_BYTES);
    words stagedRows = allocate(staging, CARRIER_ROWS);
    words stagedProjections = allocate(staging, PROJECTION_ROWS);
    long copiedProjectionColumn = 0;
    while (copiedProjectionColumn < 8) limit 8 {
      long copiedProjection = 0;
      while (copiedProjection < referenceCount) limit MAX_REFERENCES {
        set(
          stagedProjections,
          copiedProjectionColumn * MAX_REFERENCES + copiedProjection,
          projectionRows[copiedProjectionColumn * MAX_REFERENCES + copiedProjection]
        );
        copiedProjection += 1;
      }

      copiedProjectionColumn += 1;
    }

    long sourceCursor = 0;
    long outputCursor = 0;
    reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long sourceStart = referenceRows[512 + reference];
      while (sourceCursor < sourceStart) limit MAX_SOURCE_BYTES {
        setByte(stagedSource, outputCursor, source[sourceCursor]);
        sourceCursor += 1;
        outputCursor += 1;
      }

      set(stagedRows, reference, referenceRows[reference]);
      set(stagedRows, 512 + reference, sourceStart);
      set(stagedRows, 1024 + reference, referenceRows[1024 + reference]);
      set(stagedRows, 1536 + reference, outputCursor);
      set(stagedProjections, 3072 + reference, outputCursor);
      long sourceLengthAtReference = referenceRows[1024 + reference];
      if (projectionRows[512 + reference] == 2) {
        long preserved = 0;
        while (preserved < sourceLengthAtReference) limit 256 {
          setByte(stagedSource, outputCursor, source[sourceCursor]);
          outputCursor += 1;
          sourceCursor += 1;
          preserved += 1;
        }
      } else {
        setByte(stagedSource, outputCursor, 108);
        setByte(stagedSource, outputCursor + 1, 111);
        setByte(stagedSource, outputCursor + 2, 110);
        setByte(stagedSource, outputCursor + 3, 103);
        outputCursor += 4;
        sourceCursor += sourceLengthAtReference;
      }

      reference += 1;
    }

    while (sourceCursor < sourceLength) limit MAX_SOURCE_BYTES {
      setByte(stagedSource, outputCursor, source[sourceCursor]);
      sourceCursor += 1;
      outputCursor += 1;
    }

    if (outputCursor != finalLength) {
      valid = false;
    }

    if (valid) {
      long outputByte = 0;
      while (outputByte < finalLength) limit MAX_SOURCE_BYTES {
        setByte(output, outputByte, stagedSource[outputByte]);
        outputByte += 1;
      }

      long column = 0;
      while (column < 4) limit 4 {
        long carrier = 0;
        while (carrier < referenceCount) limit MAX_REFERENCES {
          set(
            carrierRows,
            column * MAX_REFERENCES + carrier,
            stagedRows[column * MAX_REFERENCES + carrier]
          );
          carrier += 1;
        }

        column += 1;
      }

      column = 0;
      while (column < 8) limit 8 {
        long projection = 0;
        while (projection < referenceCount) limit MAX_REFERENCES {
          set(
            projectionRows,
            column * MAX_REFERENCES + projection,
            stagedProjections[column * MAX_REFERENCES + projection]
          );
          projection += 1;
        }

        column += 1;
      }
    }

    drop(stagedProjections);
    drop(stagedRows);
    drop(stagedSource);
    drop(staging);
    return new LocalNominalCarrierPlan(finalLength, referenceCount, valid);
  }
}
