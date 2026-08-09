//! Joins aggregate source ranges to bounded primitive-frontend value products.

module wheeler.compiler.closure.aggregate_frontend_bindings;

import wheeler.lexer.scanner;

classical class AggregateFrontendBindings {
  private const long ARGUMENT_ROWS = 4096;
  private const long LOCAL_ROWS = 256;
  private const long MAX_ARGUMENTS = 1024;
  private const long MAX_FUNCTIONS = 64;
  private const long MAX_LOCALS = 256;
  private const long MAX_OPERATIONS = 256;
  private const long MAX_STATEMENTS = 4096;
  private const long MAX_VALUES = 1024;
  private const long OPERATION_ROWS = 2048;
  private const long PLACEMENT_ROWS = 768;
  private const long STATEMENT_ROWS = 24576;
  private const long VALUE_ROWS = 7168;

  /// Reports whether every operation and argument joined one frontend value.
  public record AggregateFrontendBindingPlan(boolean valid) {}

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

  private boolean rangeValid(borrow utf8 source, long start, long length) {
    if (start < 0) {
      return false;
    }

    if (length < 1) {
      return false;
    }

    if (bufferLength(source) < start) {
      return false;
    }

    return length < bufferLength(source) - start + 1;
  }

  /// Publishes destination, owner, argument, and splice rows after complete validation.
  public AggregateFrontendBindingPlan projectAggregateFrontendBindings(
    borrow utf8 source,
    long operationCount,
    borrow mut words operationRows,
    long argumentCount,
    borrow mut words argumentRows,
    long valueCount,
    borrow mut words valueRows,
    long statementCount,
    borrow mut words statementRows,
    borrow mut words destinationLocals,
    borrow mut words ownerLocals,
    borrow mut words argumentLocals,
    borrow mut words placementRows
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(-1 < argumentCount);
    assert(argumentCount < MAX_ARGUMENTS + 1);
    assert(bufferLength(argumentRows) == ARGUMENT_ROWS);
    assert(-1 < valueCount);
    assert(valueCount < MAX_VALUES + 1);
    assert(bufferLength(valueRows) == VALUE_ROWS);
    assert(-1 < statementCount);
    assert(statementCount < MAX_STATEMENTS + 1);
    assert(bufferLength(statementRows) == STATEMENT_ROWS);
    assert(bufferLength(destinationLocals) == LOCAL_ROWS);
    assert(bufferLength(ownerLocals) == LOCAL_ROWS);
    assert(bufferLength(argumentLocals) == MAX_ARGUMENTS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);

    boolean valid = true;
    long value = 0;
    while (value < valueCount) limit MAX_VALUES {
      long valueFunction = valueRows[value];
      long valueLocal = valueRows[3072 + value];
      long definitionOrdinal = valueRows[4096 + value];
      if (valueFunction < 0) {
        valid = false;
      }

      if (MAX_FUNCTIONS < valueFunction + 1) {
        valid = false;
      }

      if (valueLocal < 0) {
        valid = false;
      }

      if (MAX_LOCALS < valueLocal + 1) {
        valid = false;
      }

      if (definitionOrdinal < 0) {
        valid = false;
      }

      if (
        rangeValid(source, valueRows[1024 + value], valueRows[2048 + value]) == false
      ) {
        valid = false;
      }

      if (
        rangeValid(source, valueRows[5120 + value], valueRows[6144 + value]) == false
      ) {
        valid = false;
      }

      value += 1;
    }

    long argument = 0;
    while (argument < argumentCount) limit MAX_ARGUMENTS {
      long validatedOwnerOperation = argumentRows[argument];
      if (validatedOwnerOperation < 0) {
        valid = false;
      } else {
        if (operationCount < validatedOwnerOperation + 1) {
          valid = false;
        }
      }

      if (
        rangeValid(source, argumentRows[2048 + argument], argumentRows[3072 + argument]) == false
      ) {
        valid = false;
      }

      argument += 1;
    }

    long statement = 0;
    while (statement < statementCount) limit MAX_STATEMENTS {
      long statementFunction = statementRows[statement];
      long direction = statementRows[4096 + statement];
      long ordinal = statementRows[8192 + statement];
      long spliceOrdinal = statementRows[12288 + statement];
      if (statementFunction < 0) {
        valid = false;
      }

      if (MAX_FUNCTIONS < statementFunction + 1) {
        valid = false;
      }

      if (direction < 0) {
        valid = false;
      }

      if (1 < direction) {
        valid = false;
      }

      if (ordinal < 0) {
        valid = false;
      }

      if (spliceOrdinal < 0) {
        valid = false;
      }

      if (
        rangeValid(source, statementRows[16384 + statement], statementRows[20480 + statement])
          == false
      ) {
        valid = false;
      }

      statement += 1;
    }

    if (valid == false) {
      return new AggregateFrontendBindingPlan(false);
    }

    region staging = new region(/* bytes= */ 18432, /* allocations= */ 4);
    words stagedDestinations = allocate(staging, LOCAL_ROWS);
    words stagedOwners = allocate(staging, LOCAL_ROWS);
    words stagedArguments = allocate(staging, MAX_ARGUMENTS);
    words stagedPlacements = allocate(staging, PLACEMENT_ROWS);
    long operation = 0;
    while (operation < MAX_OPERATIONS) limit MAX_OPERATIONS {
      set(stagedDestinations, operation, -1);
      set(stagedOwners, operation, -1);
      operation += 1;
    }

    operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long expressionStart = operationRows[1280 + operation];
      long expressionLength = operationRows[1536 + operation];
      if (rangeValid(source, expressionStart, expressionLength) == false) {
        valid = false;
      }

      long destinationMatches = 0;
      long destination = -1;
      long selectedFunction = -1;
      value = 0;
      while (value < valueCount) limit MAX_VALUES {
        if (valueRows[5120 + value] == expressionStart) {
          if (valueRows[6144 + value] == expressionLength) {
            destinationMatches += 1;
            destination = valueRows[3072 + value];
            selectedFunction = valueRows[value];
          }
        }

        value += 1;
      }

      if (destinationMatches != 1) {
        valid = false;
      } else {
        set(stagedDestinations, operation, destination);
      }

      long selectedStatement = -1;
      long statementMatches = 0;
      statement = 0;
      while (statement < statementCount) limit MAX_STATEMENTS {
        long statementStart = statementRows[16384 + statement];
        long statementLength = statementRows[20480 + statement];
        if (statementStart < expressionStart + 1) {
          if (expressionStart + expressionLength < statementStart + statementLength + 1) {
            statementMatches += 1;
            selectedStatement = statement;
          }
        }

        statement += 1;
      }

      if (statementMatches != 1) {
        valid = false;
      }

      long selectedOrdinal = 0;
      if (-1 < selectedStatement) {
        selectedOrdinal = statementRows[8192 + selectedStatement];
        set(stagedPlacements, operation, selectedFunction);
        set(stagedPlacements, 256 + operation, statementRows[4096 + selectedStatement]);
        set(stagedPlacements, 512 + operation, statementRows[12288 + selectedStatement]);
      }

      long operationKind = operationRows[operation];
      if (operationKind == 3) {
        long ownerStart = operationRows[256 + operation];
        long ownerLength = operationRows[512 + operation];
        long owner = -1;
        long ownerOrdinal = -1;
        long ownerMatches = 0;
        value = 0;
        while (value < valueCount) limit MAX_VALUES {
          if (valueRows[value] == selectedFunction) {
            long candidateOrdinal = valueRows[4096 + value];
            if (candidateOrdinal < selectedOrdinal + 1) {
              if (
                equalRange(
                  source,
                  ownerStart,
                  ownerLength,
                  valueRows[1024 + value],
                  valueRows[2048 + value]
                )
              ) {
                if (ownerOrdinal < candidateOrdinal) {
                  owner = valueRows[3072 + value];
                  ownerOrdinal = candidateOrdinal;
                  ownerMatches = 1;
                } else {
                  if (ownerOrdinal == candidateOrdinal) {
                    ownerMatches += 1;
                  }
                }
              }
            }
          }

          value += 1;
        }

        if (ownerMatches != 1) {
          valid = false;
        } else {
          set(stagedOwners, operation, owner);
        }
      }

      if (operationKind == 4) {
        long indexedOwnerStart = operationRows[256 + operation];
        long indexedOwnerLength = operationRows[512 + operation];
        long indexedOwner = -1;
        long indexedOrdinal = -1;
        long indexedMatches = 0;
        value = 0;
        while (value < valueCount) limit MAX_VALUES {
          if (valueRows[value] == selectedFunction) {
            long indexedCandidateOrdinal = valueRows[4096 + value];
            if (indexedCandidateOrdinal < selectedOrdinal + 1) {
              if (
                equalRange(
                  source,
                  indexedOwnerStart,
                  indexedOwnerLength,
                  valueRows[1024 + value],
                  valueRows[2048 + value]
                )
              ) {
                if (indexedOrdinal < indexedCandidateOrdinal) {
                  indexedOwner = valueRows[3072 + value];
                  indexedOrdinal = indexedCandidateOrdinal;
                  indexedMatches = 1;
                } else {
                  if (indexedOrdinal == indexedCandidateOrdinal) {
                    indexedMatches += 1;
                  }
                }
              }
            }
          }

          value += 1;
        }

        if (indexedMatches != 1) {
          valid = false;
        } else {
          set(stagedOwners, operation, indexedOwner);
        }
      }

      operation += 1;
    }

    argument = 0;
    while (argument < argumentCount) limit MAX_ARGUMENTS {
      long ownerOperation = argumentRows[argument];
      long argumentStart = argumentRows[2048 + argument];
      long argumentLength = argumentRows[3072 + argument];
      if (rangeValid(source, argumentStart, argumentLength) == false) {
        valid = false;
      }

      long argumentFunction = stagedPlacements[ownerOperation];
      long argumentOrdinal = stagedPlacements[512 + ownerOperation];
      long exactMatches = 0;
      long exactLocal = -1;
      value = 0;
      while (value < valueCount) limit MAX_VALUES {
        if (valueRows[value] == argumentFunction) {
          if (valueRows[5120 + value] == argumentStart) {
            if (valueRows[6144 + value] == argumentLength) {
              exactMatches += 1;
              exactLocal = valueRows[3072 + value];
            }
          }
        }

        value += 1;
      }

      if (exactMatches == 1) {
        set(stagedArguments, argument, exactLocal);
      } else {
        long namedMatches = 0;
        long namedLocal = -1;
        long namedOrdinal = -1;
        value = 0;
        while (value < valueCount) limit MAX_VALUES {
          if (valueRows[value] == argumentFunction) {
            long namedCandidateOrdinal = valueRows[4096 + value];
            if (namedCandidateOrdinal < argumentOrdinal + 1) {
              if (
                equalRange(
                  source,
                  argumentStart,
                  argumentLength,
                  valueRows[1024 + value],
                  valueRows[2048 + value]
                )
              ) {
                if (namedOrdinal < namedCandidateOrdinal) {
                  namedLocal = valueRows[3072 + value];
                  namedOrdinal = namedCandidateOrdinal;
                  namedMatches = 1;
                } else {
                  if (namedOrdinal == namedCandidateOrdinal) {
                    namedMatches += 1;
                  }
                }
              }
            }
          }

          value += 1;
        }

        if (namedMatches != 1) {
          valid = false;
        } else {
          set(stagedArguments, argument, namedLocal);
        }
      }

      argument += 1;
    }

    if (valid) {
      long row = 0;
      while (row < LOCAL_ROWS) limit LOCAL_ROWS {
        set(destinationLocals, row, stagedDestinations[row]);
        set(ownerLocals, row, stagedOwners[row]);
        row += 1;
      }

      row = 0;
      while (row < MAX_ARGUMENTS) limit MAX_ARGUMENTS {
        set(argumentLocals, row, stagedArguments[row]);
        row += 1;
      }

      row = 0;
      while (row < PLACEMENT_ROWS) limit PLACEMENT_ROWS {
        set(placementRows, row, stagedPlacements[row]);
        row += 1;
      }
    }

    drop(stagedPlacements);
    drop(stagedArguments);
    drop(stagedOwners);
    drop(stagedDestinations);
    drop(staging);
    return new AggregateFrontendBindingPlan(valid);
  }
}
