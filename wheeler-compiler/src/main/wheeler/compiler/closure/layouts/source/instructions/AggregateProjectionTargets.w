//! Resolves source-local aggregate projections to descriptor member rows.

module wheeler.compiler.closure.aggregate_projection_targets;

import wheeler.compiler.storage_opcodes;
import wheeler.lexer.scanner;

classical class AggregateProjectionTargets {
  private const long AGGREGATE_ROWS = 832;
  private const long CASE_ROWS = 640;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CASES = 128;
  private const long MAX_MEMBERS = 256;
  private const long MAX_OPERATIONS = 256;
  private const long MEMBER_ROWS = 2048;
  private const long OPERATION_ROWS = 2048;
  private const long OWNER_ROWS = 256;
  private const long SOURCE_KIND_RECORD = 1;
  private const long SOURCE_KIND_ARRAY = 2;
  private const long SOURCE_KIND_SLICE = 3;
  private const long SOURCE_KIND_VARIANT = 4;
  private const long TARGET_ROWS = 1024;

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

  /// Publishes field and indexed projection targets after exact owner validation.
  public boolean resolveLocalAggregateProjectionTargets(
    borrow utf8 source,
    long operationCount,
    borrow mut words operationRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    long caseCount,
    borrow mut words caseRows,
    long memberCount,
    borrow mut words memberRows,
    borrow mut words ownerAggregateRows,
    borrow mut words ownerCaseRows,
    borrow mut words targetRows
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
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
    assert(bufferLength(targetRows) == TARGET_ROWS);
    region scratch = new region(/* bytes= */ 8192, /* allocations= */ 1);
    words stagedTargets = allocate(scratch, TARGET_ROWS);
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      set(stagedTargets, 256 + operation, -1);
      set(stagedTargets, 512 + operation, -1);
      set(stagedTargets, 768 + operation, -1);
      operation += 1;
    }

    boolean valid = true;
    operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long operationKind = operationRows[operation];
      if (operationKind == 3) {
        long owner = ownerAggregateRows[operation];
        if (owner < 0) {
          valid = false;
        } else {
          if (aggregateCount < owner + 1) {
            valid = false;
          }
        }

        long firstMember = 0;
        long ownerMemberCount = 0;
        long ownerKind = 0;
        if (valid) {
          ownerKind = aggregateRows[owner];
          if (ownerKind == SOURCE_KIND_RECORD) {
            firstMember = aggregateRows[320 + owner];
            ownerMemberCount = aggregateRows[384 + owner];
            set(stagedTargets, operation, OPCODE_RECORD_GET);
          } else {
            if (ownerKind == SOURCE_KIND_VARIANT) {
              long relativeCase = ownerCaseRows[operation];
              long firstCase = aggregateRows[192 + owner];
              long ownerCaseCount = aggregateRows[256 + owner];
              if (relativeCase < 0) {
                valid = false;
              } else {
                if (ownerCaseCount < relativeCase + 1) {
                  valid = false;
                }
              }

              if (valid) {
                long selectedCase = firstCase + relativeCase;
                if (caseCount < selectedCase + 1) {
                  valid = false;
                } else {
                  if (caseRows[selectedCase] != owner) {
                    valid = false;
                  }
                }

                if (valid) {
                  firstMember = caseRows[384 + selectedCase];
                  ownerMemberCount = caseRows[512 + selectedCase];
                  set(stagedTargets, operation, OPCODE_VARIANT_GET);
                  set(stagedTargets, 512 + operation, relativeCase);
                }
              }
            } else {
              valid = false;
            }
          }
        }

        if (valid) {
          if (firstMember + ownerMemberCount < memberCount + 1) {} else {
            valid = false;
          }
        }

        if (valid) {
          long matchCount = 0;
          long targetMember = -1;
          long member = firstMember;
          long memberEnd = firstMember + ownerMemberCount;
          while (member < memberEnd) limit MAX_MEMBERS {
            if (
              equalRange(
                source,
                operationRows[768 + operation],
                operationRows[1024 + operation],
                memberRows[512 + member],
                memberRows[768 + member]
              )
            ) {
              matchCount += 1;
              targetMember = member;
            }

            member += 1;
          }

          if (matchCount != 1) {
            valid = false;
          } else {
            set(stagedTargets, 256 + operation, owner);
            set(stagedTargets, 768 + operation, targetMember - firstMember);
          }
        }
      }

      if (operationKind == 4) {
        long indexedOwner = ownerAggregateRows[operation];
        if (indexedOwner < 0) {
          valid = false;
        } else {
          if (aggregateCount < indexedOwner + 1) {
            valid = false;
          }
        }

        if (valid) {
          long indexedKind = aggregateRows[indexedOwner];
          if (indexedKind == SOURCE_KIND_ARRAY) {
            set(stagedTargets, operation, OPCODE_ARRAY_GET);
          } else {
            if (indexedKind == SOURCE_KIND_SLICE) {
              set(stagedTargets, operation, OPCODE_SLICE_GET);
            } else {
              valid = false;
            }
          }

          if (valid) {
            set(stagedTargets, 256 + operation, indexedOwner);
          }
        }
      }

      operation += 1;
    }

    if (valid) {
      long column = 0;
      while (column < 4) limit 4 {
        long row = 0;
        while (row < operationCount) limit MAX_OPERATIONS {
          set(
            targetRows,
            column * MAX_OPERATIONS + row,
            stagedTargets[column * MAX_OPERATIONS + row]
          );
          row += 1;
        }

        column += 1;
      }
    }

    drop(stagedTargets);
    drop(scratch);
    return valid;
  }
}
