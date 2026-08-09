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
  private const long MAX_VALUES = 1024;
  private const long MEMBER_ROWS = 2048;
  private const long OPERATION_ROWS = 2048;
  private const long OWNER_ROWS = 256;
  private const long PLACEMENT_ROWS = 768;
  private const long VALUE_ROWS = 7168;
  private const long VALUE_STRUCTURAL_ROWS = 1024;

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
    long valueCount,
    borrow mut words valueRows,
    borrow mut words valueStructuralRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    long caseCount,
    borrow mut words caseRows,
    long memberCount,
    borrow mut words memberRows,
    borrow mut words ownerAggregateRows,
    borrow mut words ownerCaseRows,
    borrow mut words sliceDescriptorRows
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(destinationLocals) == OWNER_ROWS);
    assert(bufferLength(ownerLocals) == OWNER_ROWS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(bufferLength(valueStructuralRows) == VALUE_STRUCTURAL_ROWS);
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
    assert(bufferLength(sliceDescriptorRows) == OWNER_ROWS);

    region staging = new region(/* bytes= */ 14336, /* allocations= */ 4);
    words stagedAggregates = allocate(staging, OWNER_ROWS);
    words stagedCases = allocate(staging, OWNER_ROWS);
    words stagedSlices = allocate(staging, OWNER_ROWS);
    words stagedValueStructures = allocate(staging, VALUE_STRUCTURAL_ROWS);
    long row = 0;
    while (row < OWNER_ROWS) limit OWNER_ROWS {
      set(stagedAggregates, row, ownerAggregateRows[row]);
      set(stagedCases, row, ownerCaseRows[row]);
      set(stagedSlices, row, sliceDescriptorRows[row]);
      row += 1;
    }

    AggregateStructuralOwnerPlan structuralOwners = deriveAggregateStructuralOwners(
      source,
      aggregateCount,
      aggregateRows,
      valueCount,
      valueRows,
      operationCount,
      operationRows,
      destinationLocals,
      ownerLocals,
      placementRows,
      stagedAggregates,
      stagedSlices,
      stagedValueStructures
    );
    boolean valid = structuralOwners.valid;
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      boolean unresolvedIndex = operationRows[operation] == 4;
      if (-1 < stagedAggregates[operation]) {
        unresolvedIndex = false;
      }

      if (unresolvedIndex) {
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
        set(sliceDescriptorRows, row, stagedSlices[row]);
        row += 1;
      }

      row = 0;
      while (row < VALUE_STRUCTURAL_ROWS) limit VALUE_STRUCTURAL_ROWS {
        set(valueStructuralRows, row, stagedValueStructures[row]);
        row += 1;
      }
    }

    drop(stagedValueStructures);
    drop(stagedSlices);
    drop(stagedCases);
    drop(stagedAggregates);
    drop(staging);
    return new AggregateIndexedOwnerPlan(valid);
  }

  /// Reports whether every published structural value has one exact descriptor.
  private record AggregateStructuralOwnerPlan(boolean valid) {}

  private long precedingByte(long offset) {
    assert(0 < offset);
    return offset - 1;
  }

  /// Publishes value and indexed-owner rows after exact source-type matching.
  private AggregateStructuralOwnerPlan deriveAggregateStructuralOwners(
    borrow utf8 source,
    long aggregateCount,
    borrow mut words aggregateRows,
    long valueCount,
    borrow mut words valueRows,
    long operationCount,
    borrow mut words operationRows,
    borrow mut words destinationLocals,
    borrow mut words ownerLocals,
    borrow mut words placementRows,
    borrow mut words ownerAggregateRows,
    borrow mut words sliceDescriptorRows,
    borrow mut words valueStructuralRows
  ) {
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES + 1);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(destinationLocals) == OWNER_ROWS);
    assert(bufferLength(ownerLocals) == OWNER_ROWS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);
    assert(bufferLength(ownerAggregateRows) == OWNER_ROWS);
    assert(bufferLength(sliceDescriptorRows) == OWNER_ROWS);
    assert(bufferLength(valueStructuralRows) == VALUE_STRUCTURAL_ROWS);

    region staging = new region(/* bytes= */ 10240, /* allocations= */ 2);
    words stagedOwners = allocate(staging, OWNER_ROWS);
    words stagedStructures = allocate(staging, VALUE_STRUCTURAL_ROWS);
    long row = 0;
    while (row < OWNER_ROWS) limit OWNER_ROWS {
      set(stagedOwners, row, ownerAggregateRows[row]);
      row += 1;
    }

    row = 0;
    while (row < VALUE_STRUCTURAL_ROWS) limit VALUE_STRUCTURAL_ROWS {
      set(stagedStructures, row, -1);
      row += 1;
    }

    boolean valid = true;
    long value = 0;
    while (value < valueCount) limit MAX_VALUES {
      long nameStart = valueRows[1024 + value];
      long typeEnd = precedingByte(nameStart);

      long selected = -1;
      long structuralMatches = 0;
      long aggregate = 0;
      while (aggregate < aggregateCount) limit MAX_AGGREGATES {
        long kind = aggregateRows[aggregate];
        boolean structuralKind = kind == 2;
        if (kind == 3) {
          structuralKind = true;
        }

        if (structuralKind) {
          long typeLength = aggregateRows[128 + aggregate];
          if (typeLength < typeEnd + 1) {
            long typeStart = typeEnd - typeLength;
            if (
              equalRange(
                source,
                typeStart,
                typeLength,
                aggregateRows[64 + aggregate],
                typeLength
              )
            ) {
              selected = aggregate;
              structuralMatches += 1;
            }
          }
        }

        aggregate += 1;
      }

      if (1 < structuralMatches) {
        valid = false;
      }

      if (structuralMatches == 1) {
        set(stagedStructures, value, selected);
      }

      value += 1;
    }

    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      if (operationRows[operation] == 4) {
        long selectedValue = -1;
        long ownerMatches = 0;
        value = 0;
        while (value < valueCount) limit MAX_VALUES {
          if (valueRows[value] == placementRows[operation]) {
            if (valueRows[3072 + value] == ownerLocals[operation]) {
              if (-1 < stagedStructures[value]) {
                selectedValue = value;
                ownerMatches += 1;
              }
            }
          }

          value += 1;
        }

        if (1 < ownerMatches) {
          valid = false;
        }

        if (ownerMatches == 1) {
          long target = stagedStructures[selectedValue];
          long existing = stagedOwners[operation];
          if (-1 < existing) {
            if (existing != target) {
              valid = false;
            }
          } else {
            set(stagedOwners, operation, target);
          }
        }
      }

      if (operationRows[operation] == 5) {
        long sliceValue = -1;
        long sliceMatches = 0;
        value = 0;
        while (value < valueCount) limit MAX_VALUES {
          if (valueRows[value] == placementRows[operation]) {
            if (valueRows[3072 + value] == destinationLocals[operation]) {
              long sliceTarget = stagedStructures[value];
              if (-1 < sliceTarget) {
                if (aggregateRows[sliceTarget] == 3) {
                  sliceValue = value;
                  sliceMatches += 1;
                }
              }
            }
          }

          value += 1;
        }

        if (sliceMatches != 1) {
          valid = false;
        } else {
          set(sliceDescriptorRows, operation, stagedStructures[sliceValue]);
        }
      }

      operation += 1;
    }

    if (valid) {
      row = 0;
      while (row < OWNER_ROWS) limit OWNER_ROWS {
        set(ownerAggregateRows, row, stagedOwners[row]);
        row += 1;
      }

      row = 0;
      while (row < VALUE_STRUCTURAL_ROWS) limit VALUE_STRUCTURAL_ROWS {
        set(valueStructuralRows, row, stagedStructures[row]);
        row += 1;
      }
    }

    drop(stagedStructures);
    drop(stagedOwners);
    drop(staging);
    return new AggregateStructuralOwnerPlan(valid);
  }
}
