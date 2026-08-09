//! Derives fixed-array owners produced by aggregate field projections.

module wheeler.compiler.closure.aggregate_indexed_owners;

import wheeler.lexer.scanner;

classical class AggregateIndexedOwners {
  private const long AGGREGATE_ROWS = 832;
  private const long CASE_ROWS = 640;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CASES = 128;
  private const long MAX_MEMBERS = 256;
  private const long MAX_OPERATIONS = 256;
  private const long MEMBER_ROWS = 2048;
  private const long OPERATION_ROWS = 2048;
  private const long OWNER_ROWS = 256;
  private const long PLACEMENT_ROWS = 768;

  /// Reports whether every indexed owner acquired one structural array descriptor.
  public record AggregateIndexedOwnerPlan(boolean valid) {}

  private boolean equalRange(
    borrow utf8 source,
    long leftStart,
    long leftLength,
    long rightStart,
    long rightLength
  ) {
    if (leftLength != rightLength) {
      return false;
    }

    long offset = 0;
    while (offset < leftLength) limit 256 {
      long left = utf8Scalar(source, leftStart + offset);
      if (left != utf8Scalar(source, rightStart + offset)) {
        return false;
      }

      offset += utf8Width(source, leftStart + offset);
    }

    return true;
  }

  /// Publishes indexed structural owners after exact producer and member joins.
  public AggregateIndexedOwnerPlan deriveAggregateIndexedOwners(
    borrow utf8 source,
    long operationCount,
    borrow mut words operationRows,
    borrow mut words destinationLocals,
    borrow mut words ownerLocals,
    borrow mut words placementRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    long caseCount,
    borrow mut words caseRows,
    long memberCount,
    borrow mut words memberRows,
    borrow mut words ownerAggregateRows,
    borrow mut words ownerCaseRows
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(destinationLocals) == OWNER_ROWS);
    assert(bufferLength(ownerLocals) == OWNER_ROWS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(-1 < caseCount);
    assert(caseCount < MAX_CASES + 1);
    assert(bufferLength(caseRows) == CASE_ROWS);
    assert(-1 < memberCount);
    assert(memberCount < MAX_MEMBERS + 1);
    assert(bufferLength(memberRows) == MEMBER_ROWS);
    assert(bufferLength(ownerAggregateRows) == OWNER_ROWS);
    assert(bufferLength(ownerCaseRows) == OWNER_ROWS);

    region staging = new region(/* bytes= */ 4096, /* allocations= */ 2);
    words stagedAggregates = allocate(staging, OWNER_ROWS);
    words stagedCases = allocate(staging, OWNER_ROWS);
    long row = 0;
    while (row < OWNER_ROWS) limit OWNER_ROWS {
      set(stagedAggregates, row, ownerAggregateRows[row]);
      set(stagedCases, row, ownerCaseRows[row]);
      row += 1;
    }

    boolean valid = true;
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      if (operationRows[operation] == 4) {
        long selectedProducer = -1;
        long producerMatches = 0;
        long producer = 0;
        while (producer < operation) limit MAX_OPERATIONS {
          if (operationRows[producer] == 3) {
            if (placementRows[producer] == placementRows[operation]) {
              if (destinationLocals[producer] == ownerLocals[operation]) {
                selectedProducer = producer;
                producerMatches += 1;
              }
            }
          }

          producer += 1;
        }

        if (producerMatches != 1) {
          valid = false;
        }

        long sourceAggregate = -1;
        long firstMember = 0;
        long sourceMemberCount = 0;
        if (-1 < selectedProducer) {
          sourceAggregate = stagedAggregates[selectedProducer];
          if (sourceAggregate < 0) {
            valid = false;
          } else {
            long sourceKind = aggregateRows[sourceAggregate];
            if (sourceKind == 1) {
              firstMember = aggregateRows[320 + sourceAggregate];
              sourceMemberCount = aggregateRows[384 + sourceAggregate];
            } else {
              if (sourceKind == 4) {
                long relativeCase = stagedCases[selectedProducer];
                long selectedCase = aggregateRows[192 + sourceAggregate] + relativeCase;
                if (relativeCase < 0) {
                  valid = false;
                } else {
                  if (caseCount < selectedCase + 1) {
                    valid = false;
                  } else {
                    firstMember = caseRows[384 + selectedCase];
                    sourceMemberCount = caseRows[512 + selectedCase];
                  }
                }
              } else {
                valid = false;
              }
            }
          }
        }

        if (firstMember + sourceMemberCount < memberCount + 1) {} else {
          valid = false;
        }

        long selectedMember = -1;
        long memberMatches = 0;
        long member = firstMember;
        while (member < firstMember + sourceMemberCount) limit MAX_MEMBERS {
          if (
            equalRange(
              source,
              operationRows[768 + selectedProducer],
              operationRows[1024 + selectedProducer],
              memberRows[512 + member],
              memberRows[768 + member]
            )
          ) {
            selectedMember = member;
            memberMatches += 1;
          }

          member += 1;
        }

        if (memberMatches != 1) {
          valid = false;
        } else {
          if (memberRows[1536 + selectedMember] != 1) {
            valid = false;
          }

          long indexedAggregate = memberRows[1792 + selectedMember];
          if (indexedAggregate < 0) {
            valid = false;
          } else {
            if (aggregateCount < indexedAggregate + 1) {
              valid = false;
            } else {
              if (aggregateRows[indexedAggregate] != 2) {
                valid = false;
              }
            }
          }

          if (valid) {
            set(stagedAggregates, operation, indexedAggregate);
            set(stagedCases, operation, -1);
          }
        }
      }

      operation += 1;
    }

    if (valid) {
      row = 0;
      while (row < OWNER_ROWS) limit OWNER_ROWS {
        set(ownerAggregateRows, row, stagedAggregates[row]);
        set(ownerCaseRows, row, stagedCases[row]);
        row += 1;
      }
    }

    drop(stagedCases);
    drop(stagedAggregates);
    drop(staging);
    return new AggregateIndexedOwnerPlan(valid);
  }
}
