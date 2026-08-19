//! Derives aggregate splice points from compiled scalar placeholders.

module wheeler.compiler.closure.aggregate_placeholder_placements;

import wheeler.core.encoding.binary;

classical class AggregatePlaceholderPlacements {
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_FUNCTIONS = 64;
  private const long MAX_INSTRUCTIONS = 4096;
  private const long MAX_OPERATIONS = 256;
  private const long OPERATION_ROWS = 2048;
  private const long PLACEMENT_ROWS = 768;
  private const long OPCODE_LOCAL_CONST = 0x0400;
  private const long OPCODE_LOCAL_MOVE = 0x0403;

  /// Reports whether every operation acquired one exact primitive splice point.
  public record AggregatePlaceholderPlacementPlan(boolean valid) {}

  private boolean containsOperation(borrow mut words operationRows, long owner, long nested) {
    long ownerStart = operationRows[1280 + owner];
    long ownerEnd = ownerStart + operationRows[1536 + owner];
    long nestedStart = operationRows[1280 + nested];
    long nestedEnd = nestedStart + operationRows[1536 + nested];
    if (ownerStart < nestedStart + 1) {
      return nestedEnd < ownerEnd + 1;
    }

    return false;
  }

  private boolean bridgesPlaceholderDestination(
    borrow byteview primitiveCode,
    long primitiveCodeLength,
    borrow mut words primitiveInstructionRows,
    long primitiveInstructionCount,
    long instruction,
    long function,
    long direction,
    long placeholderLocal,
    long destinationLocal
  ) {
    long bridge = instruction + 1;
    if (primitiveInstructionCount < bridge + 1) {
      return false;
    }

    if (primitiveInstructionRows[bridge] != function) {
      return false;
    }

    if (primitiveInstructionRows[4096 + bridge] != direction) {
      return false;
    }

    if (primitiveInstructionRows[12288 + bridge] != OPCODE_LOCAL_MOVE) {
      return false;
    }

    if (primitiveInstructionRows[16384 + bridge] != 2) {
      return false;
    }

    if (primitiveInstructionRows[20480 + bridge] != 24) {
      return false;
    }

    long bridgeOffset = primitiveInstructionRows[8192 + bridge];
    if (bridgeOffset < 0) {
      return false;
    }

    if (primitiveCodeLength - bridgeOffset < 24) {
      return false;
    }

    if (readUnsigned(primitiveCode, bridgeOffset + 8, 8) != destinationLocal) {
      return false;
    }

    return readUnsigned(primitiveCode, bridgeOffset + 16, 8) == placeholderLocal;
  }

  /// Publishes function, direction, and ordinal rows after exact zero-local matching.
  public AggregatePlaceholderPlacementPlan deriveAggregatePlaceholderPlacements(
    borrow byteview primitiveCode,
    long primitiveCodeLength,
    long functionCount,
    long primitiveInstructionCount,
    borrow mut words primitiveInstructionRows,
    long operationCount,
    borrow mut words operationRows,
    borrow mut words destinationLocals,
    borrow mut words operationFunctions,
    borrow mut words operationDirections,
    borrow mut words placementRows
  ) {
    assert(-1 < primitiveCodeLength);
    assert(primitiveCodeLength < bufferLength(primitiveCode) + 1);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(-1 < primitiveInstructionCount);
    assert(primitiveInstructionCount < MAX_INSTRUCTIONS + 1);
    assert(bufferLength(primitiveInstructionRows) == INSTRUCTION_ROWS);
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(destinationLocals) == MAX_OPERATIONS);
    assert(bufferLength(operationFunctions) == MAX_OPERATIONS);
    assert(bufferLength(operationDirections) == MAX_OPERATIONS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);

    region staging = new region(/* bytes= */ 6144, /* allocations= */ 1);
    words stagedPlacements = allocate(staging, PLACEMENT_ROWS);
    boolean valid = true;
    long operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long function = operationFunctions[operation];
      long direction = operationDirections[operation];
      if (function < 0) {
        valid = false;
      }

      if (functionCount < function + 1) {
        valid = false;
      }

      if (direction < 0) {
        valid = false;
      }

      if (1 < direction) {
        valid = false;
      }

      if (destinationLocals[operation] < 0) {
        valid = false;
      }

      if (255 < destinationLocals[operation]) {
        valid = false;
      }

      long root = operation;
      long candidate = 0;
      while (candidate < operationCount) limit MAX_OPERATIONS {
        if (operationFunctions[candidate] == function) {
          if (operationDirections[candidate] == direction) {
            if (containsOperation(operationRows, candidate, root)) {
              root = candidate;
            }
          }
        }

        candidate += 1;
      }

      long selectedOrdinal = -1;
      long matches = 0;
      long ordinal = 0;
      long instruction = 0;
      while (instruction < primitiveInstructionCount) limit MAX_INSTRUCTIONS {
        if (primitiveInstructionRows[instruction] == function) {
          if (primitiveInstructionRows[4096 + instruction] == direction) {
            long offset = primitiveInstructionRows[8192 + instruction];
            long opcode = primitiveInstructionRows[12288 + instruction];
            long operands = primitiveInstructionRows[16384 + instruction];
            long length = primitiveInstructionRows[20480 + instruction];
            if (opcode == OPCODE_LOCAL_CONST) {
              if (operands == 2) {
                if (length == 24) {
                  if (-1 < offset) {
                    if (24 < primitiveCodeLength - offset + 1) {
                      long placeholderLocal = readUnsigned(primitiveCode, offset + 8, 8);
                      boolean destinationMatches = placeholderLocal == destinationLocals[root];
                      if (destinationMatches == false) {
                        destinationMatches = bridgesPlaceholderDestination(
                          primitiveCode,
                          primitiveCodeLength,
                          primitiveInstructionRows,
                          primitiveInstructionCount,
                          instruction,
                          function,
                          direction,
                          placeholderLocal,
                          destinationLocals[root]
                        );
                      }

                      if (destinationMatches) {
                        if (readUnsigned(primitiveCode, offset + 16, 8) == 0) {
                          selectedOrdinal = ordinal;
                          matches += 1;
                        }
                      }
                    }
                  }
                }
              }
            }

            ordinal += 1;
          }
        }

        instruction += 1;
      }

      if (matches != 1) {
        valid = false;
      }

      set(stagedPlacements, operation, function);
      set(stagedPlacements, 256 + operation, direction);
      set(stagedPlacements, 512 + operation, selectedOrdinal);
      operation += 1;
    }

    if (valid) {
      long column = 0;
      while (column < 3) limit 3 {
        long row = 0;
        while (row < operationCount) limit MAX_OPERATIONS {
          set(
            placementRows,
            column * MAX_OPERATIONS + row,
            stagedPlacements[column * MAX_OPERATIONS + row]
          );
          row += 1;
        }

        column += 1;
      }
    }

    drop(stagedPlacements);
    drop(staging);
    return new AggregatePlaceholderPlacementPlan(valid);
  }
}
