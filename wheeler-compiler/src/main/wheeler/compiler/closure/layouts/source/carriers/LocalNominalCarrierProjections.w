//! Binds local nominal carrier ranges to primitive frontend coordinates.

module wheeler.compiler.closure.local_nominal_carrier_projections;

classical class LocalNominalCarrierProjections {
  private const long MAX_OPERATIONS = 256;
  private const long MAX_REFERENCES = 512;
  private const long MAX_VALUES = 1024;
  private const long OPERATION_ROWS = 2048;
  private const long REFERENCE_ROWS = 1536;
  private const long PROJECTION_ROWS = 4096;
  private const long VALUE_ROWS = 7168;

  /// Reports value, constructor, and signature carrier extents.
  public record LocalNominalCarrierProjectionPlan(
    long projectionCount,
    long valueCount,
    long constructorCount,
    long signatureCount,
    boolean valid
  ) {}

  private boolean whitespaceOnly(borrow utf8 source, long start, long end) {
    long cursor = start;
    while (cursor < end) limit 32768 {
      long scalar = utf8Scalar(source, cursor);
      boolean whitespace = scalar == 32;
      if (scalar == 9) {
        whitespace = true;
      }

      if (scalar == 10) {
        whitespace = true;
      }

      if (scalar == 13) {
        whitespace = true;
      }

      if (whitespace == false) {
        return false;
      }

      cursor += 1;
    }

    return true;
  }

  /// Publishes projections only after every carrier has one unambiguous role.
  public LocalNominalCarrierProjectionPlan publishLocalNominalCarrierProjections(
    borrow utf8 source,
    long referenceCount,
    borrow mut words referenceRows,
    long valueCount,
    borrow mut words valueRows,
    long operationCount,
    borrow mut words operationRows,
    borrow mut words projectionRows
  ) {
    assert(-1 < referenceCount);
    assert(referenceCount < MAX_REFERENCES + 1);
    assert(bufferLength(referenceRows) == REFERENCE_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);

    region staging = new region(/* bytes= */ 32768, /* allocations= */ 1);
    words stagedRows = allocate(staging, PROJECTION_ROWS);
    boolean valid = true;
    long boundValues = 0;
    long boundConstructors = 0;
    long boundSignatures = 0;
    long reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long originalStart = referenceRows[512 + reference];
      long originalLength = referenceRows[1024 + reference];
      long originalEnd = originalStart + originalLength;
      long role = 3;
      long function = -1;
      long local = -1;
      long owner = -1;
      long constructorMatches = 0;
      long operation = 0;
      while (operation < operationCount) limit MAX_OPERATIONS {
        long operationKind = operationRows[operation];
        if (operationKind == 1) {
          if (operationRows[256 + operation] == originalStart) {
            if (operationRows[512 + operation] == originalLength) {
              owner = operation;
              constructorMatches += 1;
            }
          }
        }

        if (operationKind == 2) {
          if (operationRows[256 + operation] == originalStart) {
            if (operationRows[512 + operation] == originalLength) {
              owner = operation;
              constructorMatches += 1;
            }
          }
        }

        operation += 1;
      }

      if (1 < constructorMatches) {
        valid = false;
      }

      long valueMatches = 0;
      long value = 0;
      while (value < valueCount) limit MAX_VALUES {
        long nameStart = valueRows[1024 + value];
        if (originalEnd < nameStart + 1) {
          if (whitespaceOnly(source, originalEnd, nameStart)) {
            function = valueRows[value];
            local = valueRows[3072 + value];
            valueMatches += 1;
          }
        }

        value += 1;
      }

      if (1 < valueMatches) {
        valid = false;
      }

      if (0 < constructorMatches) {
        if (0 < valueMatches) {
          valid = false;
        }

        role = 2;
        function = -1;
        local = -1;
        boundConstructors += 1;
      } else {
        if (valueMatches == 1) {
          role = 1;
          owner = -1;
          boundValues += 1;
        } else {
          role = 3;
          function = -1;
          local = -1;
          owner = -1;
          boundSignatures += 1;
        }
      }

      if (role == 1) {
        if (function < 0) {
          valid = false;
        }

        if (63 < function) {
          valid = false;
        }

        if (local < 0) {
          valid = false;
        }

        if (255 < local) {
          valid = false;
        }
      }

      set(stagedRows, reference, referenceRows[reference]);
      set(stagedRows, 512 + reference, role);
      set(stagedRows, 1024 + reference, function);
      set(stagedRows, 1536 + reference, local);
      set(stagedRows, 2048 + reference, originalStart);
      set(stagedRows, 2560 + reference, originalLength);
      set(stagedRows, 3072 + reference, -1);
      set(stagedRows, 3584 + reference, owner);
      reference += 1;
    }

    if (valid) {
      long row = 0;
      while (row < PROJECTION_ROWS) limit PROJECTION_ROWS {
        set(projectionRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(stagedRows);
    drop(staging);
    return new LocalNominalCarrierProjectionPlan(
      referenceCount,
      boundValues,
      boundConstructors,
      boundSignatures,
      valid
    );
  }
}
