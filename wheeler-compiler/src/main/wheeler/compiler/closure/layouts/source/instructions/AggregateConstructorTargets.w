//! Resolves source-local aggregate constructors to counted descriptor rows.

module wheeler.compiler.closure.aggregate_constructor_targets;

import wheeler.compiler.storage_opcodes;
import wheeler.lexer.scanner;

classical class AggregateConstructorTargets {
  private const long AGGREGATE_ROWS = 832;
  private const long CASE_ROWS = 640;
  private const long MAX_AGGREGATES = 64;
  private const long MAX_CASES = 128;
  private const long MAX_OPERATIONS = 256;
  private const long OPERATION_ROWS = 2048;
  private const long SOURCE_KIND_RECORD = 1;
  private const long SOURCE_KIND_ARRAY = 2;
  private const long SOURCE_KIND_VARIANT = 4;
  private const long TARGET_ROWS = 768;

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

  /// Publishes local constructor opcodes and descriptor coordinates atomically.
  public boolean resolveLocalAggregateConstructorTargets(
    borrow utf8 source,
    long operationCount,
    borrow mut words operationRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    long caseCount,
    borrow mut words caseRows,
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
    assert(bufferLength(targetRows) == TARGET_ROWS);
    region scratch = new region(/* bytes= */ 6144, /* allocations= */ 1);
    words stagedTargets = allocate(scratch, TARGET_ROWS);
    long operation = 0;
    while (operation < MAX_OPERATIONS) limit MAX_OPERATIONS {
      set(stagedTargets, 256 + operation, -1);
      set(stagedTargets, 512 + operation, -1);
      operation += 1;
    }

    boolean valid = true;
    operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long operationKind = operationRows[operation];
      if (operationKind == 1) {
        long matchCount = 0;
        long target = -1;
        long aggregate = 0;
        while (aggregate < aggregateCount) limit MAX_AGGREGATES {
          if (
            equalRange(
              source,
              operationRows[256 + operation],
              operationRows[512 + operation],
              aggregateRows[64 + aggregate],
              aggregateRows[128 + aggregate]
            )
          ) {
            matchCount += 1;
            target = aggregate;
          }

          aggregate += 1;
        }

        if (matchCount != 1) {
          valid = false;
        } else {
          long targetKind = aggregateRows[target];
          if (targetKind == SOURCE_KIND_RECORD) {
            set(stagedTargets, operation, OPCODE_RECORD_NEW);
          } else {
            if (targetKind == SOURCE_KIND_ARRAY) {
              set(stagedTargets, operation, OPCODE_ARRAY_NEW);
            } else {
              valid = false;
            }
          }

          if (valid) {
            set(stagedTargets, 256 + operation, target);
          }
        }
      }

      if (operationKind == 2) {
        long variantMatchCount = 0;
        long variantTarget = -1;
        long candidateAggregate = 0;
        while (candidateAggregate < aggregateCount) limit MAX_AGGREGATES {
          if (
            equalRange(
              source,
              operationRows[256 + operation],
              operationRows[512 + operation],
              aggregateRows[64 + candidateAggregate],
              aggregateRows[128 + candidateAggregate]
            )
          ) {
            variantMatchCount += 1;
            variantTarget = candidateAggregate;
          }

          candidateAggregate += 1;
        }

        if (variantMatchCount != 1) {
          valid = false;
        } else {
          if (aggregateRows[variantTarget] != SOURCE_KIND_VARIANT) {
            valid = false;
          }
        }

        if (valid) {
          long firstCase = aggregateRows[192 + variantTarget];
          long variantCaseCount = aggregateRows[256 + variantTarget];
          if (firstCase + variantCaseCount < caseCount + 1) {} else {
            valid = false;
          }

          long matchedCaseCount = 0;
          long matchedCase = -1;
          long candidateCase = firstCase;
          long caseEnd = firstCase + variantCaseCount;
          while (candidateCase < caseEnd) limit MAX_CASES {
            if (caseRows[candidateCase] == variantTarget) {
              if (
                equalRange(
                  source,
                  operationRows[768 + operation],
                  operationRows[1024 + operation],
                  caseRows[128 + candidateCase],
                  caseRows[256 + candidateCase]
                )
              ) {
                matchedCaseCount += 1;
                matchedCase = candidateCase;
              }
            }

            candidateCase += 1;
          }

          if (matchedCaseCount != 1) {
            valid = false;
          } else {
            set(stagedTargets, operation, OPCODE_VARIANT_NEW);
            set(stagedTargets, 256 + operation, variantTarget);
            set(stagedTargets, 512 + operation, matchedCase - firstCase);
          }
        }
      }

      operation += 1;
    }

    if (valid) {
      long row = 0;
      while (row < TARGET_ROWS) limit TARGET_ROWS {
        set(targetRows, row, stagedTargets[row]);
        row += 1;
      }
    }

    drop(stagedTargets);
    drop(scratch);
    return valid;
  }
}
