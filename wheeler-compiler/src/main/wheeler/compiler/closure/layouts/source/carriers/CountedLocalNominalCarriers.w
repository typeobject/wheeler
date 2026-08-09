//! Appends source-local nominal carrier projections to closure coordinates.

module wheeler.compiler.closure.counted_local_nominal_carriers;

classical class CountedLocalNominalCarriers {
  private const long CARRIER_PROJECTION_ROWS = 65536;
  private const long CLOSURE_AGGREGATE_ROWS = 36864;
  private const long LOCAL_PROJECTION_ROWS = 4096;
  private const long MAX_AGGREGATES = 4096;
  private const long MAX_CARRIER_PROJECTIONS = 16384;
  private const long MAX_LOCAL_AGGREGATES = 64;
  private const long MAX_LOCAL_PROJECTIONS = 512;
  private const long MAX_MODULES = 512;

  /// Reports the appended projection window and total closure extent.
  public record CountedLocalNominalCarrierPlan(
    long firstProjection,
    long appendedCount,
    long projectionCount,
    boolean valid
  ) {}

  /// Appends exact value-carrier rows only after all local and closure coordinates validate.
  public CountedLocalNominalCarrierPlan appendLocalNominalCarrierProjections(
    long moduleOwner,
    long localProjectionCount,
    borrow mut words localProjectionRows,
    long firstClosureAggregate,
    long moduleAggregateCount,
    long aggregateCount,
    borrow mut words closureAggregateRows,
    long carrierProjectionCount,
    borrow mut words carrierProjectionRows
  ) {
    assert(-1 < moduleOwner);
    assert(moduleOwner < MAX_MODULES);
    assert(-1 < localProjectionCount);
    assert(localProjectionCount < MAX_LOCAL_PROJECTIONS + 1);
    assert(bufferLength(localProjectionRows) == LOCAL_PROJECTION_ROWS);
    assert(-1 < firstClosureAggregate);
    assert(-1 < moduleAggregateCount);
    assert(moduleAggregateCount < MAX_LOCAL_AGGREGATES + 1);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(closureAggregateRows) == CLOSURE_AGGREGATE_ROWS);
    assert(-1 < carrierProjectionCount);
    assert(carrierProjectionCount < MAX_CARRIER_PROJECTIONS + 1);
    assert(bufferLength(carrierProjectionRows) == CARRIER_PROJECTION_ROWS);
    boolean valid = firstClosureAggregate < aggregateCount + 1;
    if (moduleAggregateCount < aggregateCount - firstClosureAggregate + 1) {} else {
      valid = false;
    }

    long appendedCount = 0;
    long localProjection = 0;
    while (localProjection < localProjectionCount) limit MAX_LOCAL_PROJECTIONS {
      long role = localProjectionRows[512 + localProjection];
      if (role < 1) {
        valid = false;
      }

      if (3 < role) {
        valid = false;
      }

      if (role == 1) {
        long localAggregate = localProjectionRows[localProjection];
        long localFunction = localProjectionRows[1024 + localProjection];
        long local = localProjectionRows[1536 + localProjection];
        if (localAggregate < 0) {
          valid = false;
        }

        if (moduleAggregateCount < localAggregate + 1) {
          valid = false;
        }

        if (localFunction < 0) {
          valid = false;
        }

        if (63 < localFunction) {
          valid = false;
        }

        if (local < 0) {
          valid = false;
        }

        if (255 < local) {
          valid = false;
        }

        long closureAggregate = firstClosureAggregate + localAggregate;
        if (aggregateCount < closureAggregate + 1) {
          valid = false;
        } else {
          if (closureAggregateRows[4096 + closureAggregate] != moduleOwner) {
            valid = false;
          }

          long kind = closureAggregateRows[closureAggregate];
          if (kind == 1) {} else {
            if (kind != 4) {
              valid = false;
            }
          }
        }

        long existing = 0;
        while (existing < carrierProjectionCount) limit MAX_CARRIER_PROJECTIONS {
          boolean duplicate = carrierProjectionRows[existing] == moduleOwner;
          if (carrierProjectionRows[16384 + existing] != localFunction) {
            duplicate = false;
          }

          if (carrierProjectionRows[32768 + existing] != local) {
            duplicate = false;
          }

          if (duplicate) {
            valid = false;
          }

          existing += 1;
        }

        long prior = 0;
        while (prior < localProjection) limit MAX_LOCAL_PROJECTIONS {
          boolean duplicateLocal = localProjectionRows[512 + prior] == 1;
          if (localProjectionRows[1024 + prior] != localFunction) {
            duplicateLocal = false;
          }

          if (localProjectionRows[1536 + prior] != local) {
            duplicateLocal = false;
          }

          if (duplicateLocal) {
            valid = false;
          }

          prior += 1;
        }

        appendedCount += 1;
      }

      localProjection += 1;
    }

    if (MAX_CARRIER_PROJECTIONS - carrierProjectionCount < appendedCount) {
      valid = false;
    }

    if (valid == false) {
      return new CountedLocalNominalCarrierPlan(
        carrierProjectionCount,
        0,
        carrierProjectionCount,
        false
      );
    }

    long appended = 0;
    localProjection = 0;
    while (localProjection < localProjectionCount) limit MAX_LOCAL_PROJECTIONS {
      if (localProjectionRows[512 + localProjection] == 1) {
        long output = carrierProjectionCount + appended;
        set(carrierProjectionRows, output, moduleOwner);
        set(carrierProjectionRows, 16384 + output, localProjectionRows[1024 + localProjection]);
        set(carrierProjectionRows, 32768 + output, localProjectionRows[1536 + localProjection]);
        set(
          carrierProjectionRows,
          49152 + output,
          firstClosureAggregate + localProjectionRows[localProjection]
        );
        appended += 1;
      }

      localProjection += 1;
    }

    return new CountedLocalNominalCarrierPlan(
      carrierProjectionCount,
      appended,
      carrierProjectionCount + appended,
      true
    );
  }
}
