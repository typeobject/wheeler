//! Publishes exact function-local projections for nonretained nominal carriers.

module wheeler.compiler.closure.imported_nominal_carrier_projections;

classical class ImportedNominalCarrierProjections {
  private const long AGGREGATE_ROWS = 36864;
  private const long CARRIER_PROJECTION_ROWS = 65536;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_REFERENCES = 64;
  private const long REFERENCE_ROWS = 256;

  /// Reports the exact carrier-local projection count.
  public record ImportedNominalCarrierProjectionPlan(long projectionCount) {}

  /// Publishes owner, local-function, local-type, and target aggregate rows atomically.
  public ImportedNominalCarrierProjectionPlan publishImportedNominalCarrierProjections(
    long moduleOwner,
    long referenceCount,
    borrow mut words referenceRows,
    borrow mut words functionRows,
    borrow mut words localRows,
    borrow mut words aggregateRows,
    borrow mut words outputRows
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < referenceCount);
    assert(referenceCount < MAX_REFERENCES + 1);
    assert(bufferLength(referenceRows) == REFERENCE_ROWS);
    assert(bufferLength(functionRows) == MAX_REFERENCES);
    assert(bufferLength(localRows) == MAX_REFERENCES);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(outputRows) == CARRIER_PROJECTION_ROWS);

    long reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      long function = functionRows[reference];
      long local = localRows[reference];
      long target = referenceRows[128 + reference];
      assert(-1 < function);
      assert(function < 64);
      assert(-1 < local);
      assert(local < 256);
      assert(-1 < target);
      assert(target < MAX_AGGREGATES);
      long kind = aggregateRows[target];
      boolean kindValid = kind == 1;
      if (kind == 4) {
        kindValid = true;
      }

      assert(kindValid);

      long prior = 0;
      while (prior < reference) limit MAX_REFERENCES {
        boolean duplicate = functionRows[prior] == function;
        if (localRows[prior] != local) {
          duplicate = false;
        }

        assert(duplicate == false);
        prior += 1;
      }

      reference += 1;
    }

    reference = 0;
    while (reference < referenceCount) limit MAX_REFERENCES {
      set(outputRows, reference, moduleOwner);
      set(outputRows, 16384 + reference, functionRows[reference]);
      set(outputRows, 32768 + reference, localRows[reference]);
      set(outputRows, 49152 + reference, referenceRows[128 + reference]);
      reference += 1;
    }

    return new ImportedNominalCarrierProjectionPlan(referenceCount);
  }
}
