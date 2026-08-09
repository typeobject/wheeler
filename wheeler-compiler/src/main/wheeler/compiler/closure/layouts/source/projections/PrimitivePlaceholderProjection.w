//! Removes validated scalar placeholders before aggregate instruction composition.

module wheeler.compiler.closure.primitive_placeholder_projection;

import wheeler.core.encoding.binary;

classical class PrimitivePlaceholderProjection {
  private const long FUNCTION_ROWS = 640;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_FUNCTIONS = 64;
  private const long MAX_INSTRUCTIONS = 4096;
  private const long MAX_OPERATIONS = 256;
  private const long OPERATION_ROWS = 2048;
  private const long PLACEMENT_ROWS = 768;
  private const long OPCODE_LOCAL_CONST = 0x0400;
  private const long STAGING_BYTES = 208640;

  /// Reports the filtered instruction extent.
  public record PrimitivePlaceholderProjectionPlan(long instructionCount, boolean valid) {}

  private boolean samePlacement(borrow mut words placementRows, long left, long right) {
    boolean same = placementRows[left] == placementRows[right];
    if (placementRows[256 + left] != placementRows[256 + right]) {
      same = false;
    }

    if (placementRows[512 + left] != placementRows[512 + right]) {
      same = false;
    }

    return same;
  }

  /// Filters one exact zero placeholder per aggregate source statement atomically.
  public PrimitivePlaceholderProjectionPlan projectPrimitiveAggregatePlaceholders(
    borrow byteview primitiveCode,
    long primitiveCodeLength,
    long functionCount,
    borrow mut words primitiveFunctionRows,
    long primitiveInstructionCount,
    borrow mut words primitiveInstructionRows,
    long operationCount,
    borrow mut words operationRows,
    borrow mut words destinationLocals,
    borrow mut words placementRows,
    borrow mut words projectedFunctionRows,
    borrow mut words projectedInstructionRows,
    borrow mut words projectedPlacementRows
  ) {
    assert(-1 < primitiveCodeLength);
    assert(primitiveCodeLength < bufferLength(primitiveCode) + 1);
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(bufferLength(primitiveFunctionRows) == FUNCTION_ROWS);
    assert(-1 < primitiveInstructionCount);
    assert(primitiveInstructionCount < MAX_INSTRUCTIONS + 1);
    assert(bufferLength(primitiveInstructionRows) == INSTRUCTION_ROWS);
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    assert(bufferLength(destinationLocals) == MAX_OPERATIONS);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);
    assert(bufferLength(projectedFunctionRows) == FUNCTION_ROWS);
    assert(bufferLength(projectedInstructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(projectedPlacementRows) == PLACEMENT_ROWS);

    boolean valid = true;
    long operation = 0;
    long placeholderCount = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long function = placementRows[operation];
      long direction = placementRows[256 + operation];
      long ordinal = placementRows[512 + operation];
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

      if (ordinal < 0) {
        valid = false;
      }

      long priorSame = 0;
      long prior = 0;
      while (prior < operation) limit MAX_OPERATIONS {
        if (samePlacement(placementRows, prior, operation)) {
          priorSame += 1;
        }

        prior += 1;
      }

      if (priorSame == 0) {
        long rootOperation = operation;
        long rootStart = operationRows[1280 + operation];
        long rootEnd = rootStart + operationRows[1536 + operation];
        long peer = operation + 1;
        while (peer < operationCount) limit MAX_OPERATIONS {
          if (samePlacement(placementRows, operation, peer)) {
            long peerStart = operationRows[1280 + peer];
            long peerEnd = peerStart + operationRows[1536 + peer];
            if (peerStart < rootStart + 1) {
              if (rootEnd < peerEnd + 1) {
                rootOperation = peer;
                rootStart = peerStart;
                rootEnd = peerEnd;
              }
            }
          }

          peer += 1;
        }

        long selectedInstruction = -1;
        long selectedMatches = 0;
        long candidateOrdinal = 0;
        long instruction = 0;
        while (instruction < primitiveInstructionCount) limit MAX_INSTRUCTIONS {
          if (primitiveInstructionRows[instruction] == function) {
            if (primitiveInstructionRows[4096 + instruction] == direction) {
              if (candidateOrdinal == ordinal) {
                selectedInstruction = instruction;
                selectedMatches += 1;
              }

              candidateOrdinal += 1;
            }
          }

          instruction += 1;
        }

        if (selectedMatches != 1) {
          valid = false;
        } else {
          long offset = primitiveInstructionRows[8192 + selectedInstruction];
          if (offset < 0) {
            valid = false;
          }

          if (primitiveCodeLength - offset < 24) {
            valid = false;
          } else {
            if (
              primitiveInstructionRows[12288 + selectedInstruction] != OPCODE_LOCAL_CONST
            ) {
              valid = false;
            }

            if (primitiveInstructionRows[16384 + selectedInstruction] != 2) {
              valid = false;
            }

            if (primitiveInstructionRows[20480 + selectedInstruction] != 24) {
              valid = false;
            }

            if (
              readUnsigned(primitiveCode, offset + 8, 8) != destinationLocals[rootOperation]
            ) {
              valid = false;
            }

            if (readUnsigned(primitiveCode, offset + 16, 8) != 0) {
              valid = false;
            }
          }
        }

        placeholderCount += 1;
      }

      operation += 1;
    }

    if (primitiveInstructionCount < placeholderCount) {
      valid = false;
    }

    if (valid == false) {
      return new PrimitivePlaceholderProjectionPlan(0, false);
    }

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 3);
    words stagedFunctions = allocate(staging, FUNCTION_ROWS);
    words stagedInstructions = allocate(staging, INSTRUCTION_ROWS);
    words stagedPlacements = allocate(staging, PLACEMENT_ROWS);
    long row = 0;
    while (row < FUNCTION_ROWS) limit FUNCTION_ROWS {
      set(stagedFunctions, row, primitiveFunctionRows[row]);
      row += 1;
    }

    long projectedCount = 0;
    long projectedInstruction = 0;
    while (projectedInstruction < primitiveInstructionCount) limit MAX_INSTRUCTIONS {
      boolean removed = false;
      long projectedOrdinal = 0;
      long precedingInstruction = 0;
      while (precedingInstruction < projectedInstruction) limit MAX_INSTRUCTIONS {
        if (
          primitiveInstructionRows[precedingInstruction]
            == primitiveInstructionRows[projectedInstruction]
        ) {
          if (
            primitiveInstructionRows[4096 + precedingInstruction] == primitiveInstructionRows[4096
              + projectedInstruction]
          ) {
            projectedOrdinal += 1;
          }
        }

        precedingInstruction += 1;
      }

      operation = 0;
      while (operation < operationCount) limit MAX_OPERATIONS {
        if (placementRows[operation] == primitiveInstructionRows[projectedInstruction]) {
          if (
            placementRows[256 + operation] == primitiveInstructionRows[4096 + projectedInstruction]
          ) {
            if (placementRows[512 + operation] == projectedOrdinal) {
              removed = true;
            }
          }
        }

        operation += 1;
      }

      if (removed == false) {
        long column = 0;
        while (column < 6) limit 6 {
          set(
            stagedInstructions,
            column * MAX_INSTRUCTIONS + projectedCount,
            primitiveInstructionRows[column * MAX_INSTRUCTIONS + projectedInstruction]
          );
          column += 1;
        }

        projectedCount += 1;
      }

      projectedInstruction += 1;
    }

    operation = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      long removedBefore = 0;
      long placementCandidate = 0;
      while (placementCandidate < operationCount) limit MAX_OPERATIONS {
        if (samePlacement(placementRows, placementCandidate, operation) == false) {
          if (placementRows[placementCandidate] == placementRows[operation]) {
            if (
              placementRows[256 + placementCandidate] == placementRows[256 + operation]
            ) {
              if (
                placementRows[512 + placementCandidate] < placementRows[512 + operation]
              ) {
                boolean firstAtPlacement = true;
                long earlierPlacement = 0;
                while (earlierPlacement < placementCandidate) limit MAX_OPERATIONS {
                  if (
                    samePlacement(placementRows, earlierPlacement, placementCandidate)
                  ) {
                    firstAtPlacement = false;
                  }

                  earlierPlacement += 1;
                }

                if (firstAtPlacement) {
                  removedBefore += 1;
                }
              }
            }
          }
        }

        placementCandidate += 1;
      }

      set(stagedPlacements, operation, placementRows[operation]);
      set(stagedPlacements, 256 + operation, placementRows[256 + operation]);
      set(stagedPlacements, 512 + operation, placementRows[512 + operation] - removedBefore);
      operation += 1;
    }

    long placeholder = 0;
    while (placeholder < operationCount) limit MAX_OPERATIONS {
      boolean firstPlaceholderAtPlacement = true;
      long earlierPlaceholder = 0;
      while (earlierPlaceholder < placeholder) limit MAX_OPERATIONS {
        if (samePlacement(placementRows, earlierPlaceholder, placeholder)) {
          firstPlaceholderAtPlacement = false;
        }

        earlierPlaceholder += 1;
      }

      if (firstPlaceholderAtPlacement) {
        long lengthRow = 192 + placementRows[placeholder];
        if (placementRows[256 + placeholder] == 1) {
          lengthRow = 320 + placementRows[placeholder];
        }

        set(stagedFunctions, lengthRow, stagedFunctions[lengthRow] - 24);
      }

      placeholder += 1;
    }

    row = 0;
    while (row < FUNCTION_ROWS) limit FUNCTION_ROWS {
      set(projectedFunctionRows, row, stagedFunctions[row]);
      row += 1;
    }

    row = 0;
    while (row < INSTRUCTION_ROWS) limit INSTRUCTION_ROWS {
      set(projectedInstructionRows, row, stagedInstructions[row]);
      row += 1;
    }

    row = 0;
    while (row < PLACEMENT_ROWS) limit PLACEMENT_ROWS {
      set(projectedPlacementRows, row, stagedPlacements[row]);
      row += 1;
    }

    drop(stagedPlacements);
    drop(stagedInstructions);
    drop(stagedFunctions);
    drop(staging);
    return new PrimitivePlaceholderProjectionPlan(projectedCount, true);
  }
}
