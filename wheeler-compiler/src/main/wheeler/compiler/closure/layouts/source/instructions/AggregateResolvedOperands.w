//! Assembles resolved aggregate instruction operands from counted source products.

module wheeler.compiler.closure.aggregate_resolved_operands;

import wheeler.compiler.storage_opcodes;

classical class AggregateResolvedOperands {
  private const long ARGUMENT_ROWS = 4096;
  private const long CONSTRUCTOR_TARGET_ROWS = 768;
  private const long LOCAL_ROWS = 256;
  private const long MAX_ARGUMENTS = 1024;
  private const long MAX_OPERATIONS = 256;
  private const long OPERATION_ROWS = 2048;
  private const long PROJECTION_TARGET_ROWS = 1024;
  private const long RESOLVED_ROWS = 1536;

  /// Publishes exact canonical operands only after every source product joins.
  public boolean assembleAggregateResolvedOperands(
    long operationCount,
    borrow mut words operationRows,
    long argumentCount,
    borrow mut words argumentRows,
    borrow mut words argumentLocals,
    borrow mut words constructorTargets,
    borrow mut words projectionTargets,
    borrow mut words destinationLocals,
    borrow mut words ownerLocals,
    borrow mut words sliceDescriptors,
    borrow mut words resolvedRows
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(-1 < argumentCount);
    assert(argumentCount < MAX_ARGUMENTS + 1);
    assert(bufferLength(argumentRows) == ARGUMENT_ROWS);
    assert(bufferLength(argumentLocals) == MAX_ARGUMENTS);
    assert(bufferLength(constructorTargets) == CONSTRUCTOR_TARGET_ROWS);
    assert(bufferLength(projectionTargets) == PROJECTION_TARGET_ROWS);
    assert(bufferLength(destinationLocals) == LOCAL_ROWS);
    assert(bufferLength(ownerLocals) == LOCAL_ROWS);
    assert(bufferLength(sliceDescriptors) == LOCAL_ROWS);
    assert(bufferLength(resolvedRows) == RESOLVED_ROWS);
    region scratch = new region(/* bytes= */ 12288, /* allocations= */ 1);
    words stagedRows = allocate(scratch, RESOLVED_ROWS);
    boolean valid = true;
    long nextArgument = 0;
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long firstArgument = nextArgument;
      long operationArgumentCount = 0;
      while (nextArgument < argumentCount) limit MAX_ARGUMENTS {
        if (argumentRows[nextArgument] == operation) {
          if (argumentRows[1024 + nextArgument] != operationArgumentCount) {
            valid = false;
          }

          if (argumentLocals[nextArgument] < 0) {
            valid = false;
          }

          operationArgumentCount += 1;
          nextArgument += 1;
        } else {
          if (argumentRows[nextArgument] < operation) {
            valid = false;
          }

          break;
        }
      }

      if (operationRows[1792 + operation] != firstArgument) {
        valid = false;
      }

      long sourceKind = operationRows[operation];
      long destination = destinationLocals[operation];
      if (destination < 0) {
        valid = false;
      }

      if (sourceKind == 1) {
        long constructorOpcode = constructorTargets[operation];
        if (constructorOpcode == OPCODE_RECORD_NEW) {} else {
          if (constructorOpcode == OPCODE_ARRAY_NEW) {} else {
            valid = false;
          }
        }

        if (constructorTargets[256 + operation] < 0) {
          valid = false;
        }

        if (0 < operationArgumentCount) {
          long argument = firstArgument + 1;
          while (argument < firstArgument + operationArgumentCount) limit MAX_ARGUMENTS {
            if (argumentLocals[argument] != argumentLocals[argument - 1] + 1) {
              valid = false;
            }

            argument += 1;
          }
        }

        set(stagedRows, operation, constructorOpcode);
        set(stagedRows, 256 + operation, destination);
        set(stagedRows, 512 + operation, constructorTargets[256 + operation]);
        if (0 < operationArgumentCount) {
          set(stagedRows, 768 + operation, argumentLocals[firstArgument]);
        }

        set(stagedRows, 1024 + operation, operationArgumentCount);
      }

      if (sourceKind == 2) {
        if (constructorTargets[operation] != OPCODE_VARIANT_NEW) {
          valid = false;
        }

        if (constructorTargets[256 + operation] < 0) {
          valid = false;
        }

        if (constructorTargets[512 + operation] < 0) {
          valid = false;
        }

        if (0 < operationArgumentCount) {
          long variantArgument = firstArgument + 1;
          while (variantArgument < firstArgument + operationArgumentCount) limit MAX_ARGUMENTS {
            if (
              argumentLocals[variantArgument] != argumentLocals[variantArgument - 1] + 1
            ) {
              valid = false;
            }

            variantArgument += 1;
          }
        }

        set(stagedRows, operation, OPCODE_VARIANT_NEW);
        set(stagedRows, 256 + operation, destination);
        set(stagedRows, 512 + operation, constructorTargets[256 + operation]);
        set(stagedRows, 768 + operation, constructorTargets[512 + operation]);
        if (0 < operationArgumentCount) {
          set(stagedRows, 1024 + operation, argumentLocals[firstArgument]);
        }

        set(stagedRows, 1280 + operation, operationArgumentCount);
      }

      if (sourceKind == 3) {
        if (operationArgumentCount != 0) {
          valid = false;
        }

        long projectionOpcode = projectionTargets[operation];
        long owner = ownerLocals[operation];
        if (owner < 0) {
          valid = false;
        }

        if (projectionOpcode == OPCODE_RECORD_GET) {
          if (projectionTargets[768 + operation] < 0) {
            valid = false;
          }

          set(stagedRows, operation, projectionOpcode);
          set(stagedRows, 256 + operation, destination);
          set(stagedRows, 512 + operation, owner);
          set(stagedRows, 768 + operation, projectionTargets[768 + operation]);
        } else {
          if (projectionOpcode == OPCODE_VARIANT_GET) {
            if (projectionTargets[512 + operation] < 0) {
              valid = false;
            }

            if (projectionTargets[768 + operation] < 0) {
              valid = false;
            }

            set(stagedRows, operation, projectionOpcode);
            set(stagedRows, 256 + operation, destination);
            set(stagedRows, 512 + operation, owner);
            set(stagedRows, 768 + operation, projectionTargets[512 + operation]);
            set(stagedRows, 1024 + operation, projectionTargets[768 + operation]);
          } else {
            valid = false;
          }
        }
      }

      if (sourceKind == 4) {
        long indexedOpcode = projectionTargets[operation];
        if (indexedOpcode == OPCODE_ARRAY_GET) {} else {
          if (indexedOpcode != OPCODE_SLICE_GET) {
            valid = false;
          }
        }

        if (operationArgumentCount != 1) {
          valid = false;
        }

        long indexedOwner = ownerLocals[operation];
        if (indexedOwner < 0) {
          valid = false;
        }

        set(stagedRows, operation, indexedOpcode);
        set(stagedRows, 256 + operation, destination);
        set(stagedRows, 512 + operation, indexedOwner);
        if (0 < operationArgumentCount) {
          set(stagedRows, 768 + operation, argumentLocals[firstArgument]);
        }
      }

      if (sourceKind == 5) {
        if (operationArgumentCount != 3) {
          valid = false;
        }

        if (sliceDescriptors[operation] < 0) {
          valid = false;
        }

        set(stagedRows, operation, OPCODE_SLICE_NEW);
        set(stagedRows, 256 + operation, destination);
        set(stagedRows, 512 + operation, sliceDescriptors[operation]);
        if (operationArgumentCount == 3) {
          set(stagedRows, 768 + operation, argumentLocals[firstArgument]);
          set(stagedRows, 1024 + operation, argumentLocals[firstArgument + 1]);
          set(stagedRows, 1280 + operation, argumentLocals[firstArgument + 2]);
        }
      }

      if (sourceKind < 1) {
        valid = false;
      }

      if (5 < sourceKind) {
        valid = false;
      }

      operation += 1;
    }

    if (nextArgument != argumentCount) {
      valid = false;
    }

    if (valid) {
      long row = 0;
      while (row < RESOLVED_ROWS) limit RESOLVED_ROWS {
        set(resolvedRows, row, stagedRows[row]);
        row += 1;
      }
    }

    drop(stagedRows);
    drop(scratch);
    return valid;
  }
}
