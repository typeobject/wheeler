//! Derives aggregate owners for source projections.

module wheeler.compiler.closure.aggregate_source_owners;

classical class AggregateSourceOwners {
  private const long CONSTRUCTOR_TARGET_ROWS = 768;
  private const long LOCAL_PROJECTION_ROWS = 4096;
  private const long MAX_OPERATIONS = 256;
  private const long MAX_PROJECTIONS = 512;
  private const long OPERATION_ROWS = 2048;
  private const long OWNER_ROWS = 256;
  private const long PLACEMENT_ROWS = 768;

  /// Reports whether every record or variant projection acquired one exact owner.
  public record AggregateSourceOwnerPlan(boolean valid) {}

  /// Publishes descriptor and constructor-case owners after complete local validation.
  public AggregateSourceOwnerPlan deriveAggregateSourceOwners(
    long operationCount,
    borrow mut words operationRows,
    borrow mut words destinationLocals,
    borrow mut words ownerLocals,
    borrow mut words placementRows,
    long localProjectionCount,
    borrow mut words localProjectionRows,
    borrow mut words constructorTargetRows,
    borrow mut words ownerAggregateRows,
    borrow mut words ownerCaseRows
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(destinationLocals) == OWNER_ROWS);
    assert(bufferLength(ownerLocals) == OWNER_ROWS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);
    assert(-1 < localProjectionCount);
    assert(localProjectionCount < MAX_PROJECTIONS + 1);
    assert(bufferLength(localProjectionRows) == LOCAL_PROJECTION_ROWS);
    assert(bufferLength(constructorTargetRows) == CONSTRUCTOR_TARGET_ROWS);
    assert(bufferLength(ownerAggregateRows) == OWNER_ROWS);
    assert(bufferLength(ownerCaseRows) == OWNER_ROWS);

    region staging = new region(/* bytes= */ 4096, /* allocations= */ 2);
    words stagedAggregates = allocate(staging, OWNER_ROWS);
    words stagedCases = allocate(staging, OWNER_ROWS);
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      set(stagedAggregates, operation, -1);
      set(stagedCases, operation, -1);
      operation += 1;
    }

    boolean valid = true;
    operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long kind = operationRows[operation];
      if (kind == 3) {
        long function = placementRows[operation];
        long ownerLocal = ownerLocals[operation];
        long selectedAggregate = -1;
        long projectionMatches = 0;
        long projection = 0;
        while (projection < localProjectionCount) limit MAX_PROJECTIONS {
          if (localProjectionRows[512 + projection] == 1) {
            if (localProjectionRows[1024 + projection] == function) {
              if (localProjectionRows[1536 + projection] == ownerLocal) {
                selectedAggregate = localProjectionRows[projection];
                projectionMatches += 1;
              }
            }
          }

          projection += 1;
        }

        if (projectionMatches != 1) {
          valid = false;
        } else {
          set(stagedAggregates, operation, selectedAggregate);
        }

        long selectedCase = -1;
        long constructorMatches = 0;
        long candidate = 0;
        while (candidate < operationCount) limit MAX_OPERATIONS {
          if (placementRows[candidate] == function) {
            if (destinationLocals[candidate] == ownerLocal) {
              if (constructorTargetRows[256 + candidate] == selectedAggregate) {
                long candidateCase = constructorTargetRows[512 + candidate];
                if (-1 < candidateCase) {
                  selectedCase = candidateCase;
                  constructorMatches += 1;
                }
              }
            }
          }

          candidate += 1;
        }

        if (1 < constructorMatches) {
          valid = false;
        }

        if (constructorMatches == 1) {
          set(stagedCases, operation, selectedCase);
        }
      }

      operation += 1;
    }

    if (valid) {
      long row = 0;
      while (row < operationCount) limit MAX_OPERATIONS {
        set(ownerAggregateRows, row, stagedAggregates[row]);
        set(ownerCaseRows, row, stagedCases[row]);
        row += 1;
      }
    }

    drop(stagedCases);
    drop(stagedAggregates);
    drop(staging);
    return new AggregateSourceOwnerPlan(valid);
  }
}
