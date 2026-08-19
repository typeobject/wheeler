//! Merges canonical aggregate code with source-local primitive instruction products.

module wheeler.compiler.closure.aggregate_instruction_composition;

import wheeler.compiler.instruction_forms;
import wheeler.core.encoding.binary;

classical class AggregateInstructionComposition {
  private const long FUNCTION_ROWS = 640;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_FUNCTIONS = 64;
  private const long MAX_INSTRUCTIONS = 4096;
  private const long MAX_OPERATIONS = 256;
  private const long PLACEMENT_ROWS = 768;
  private const long SELECTOR_ROWS = 4096;
  private const long STAGING_BYTES = 234496;

  /// Reports the exact merged source-local instruction extent.
  public record AggregateCompositionPlan(long instructionCount, boolean valid) {}

  /// Publishes a two-artifact instruction view after validating every splice point.
  public AggregateCompositionPlan composeAggregateInstructionProducts(
    long functionCount,
    borrow mut words primitiveFunctionRows,
    long primitiveInstructionCount,
    borrow mut words primitiveInstructionRows,
    long operationCount,
    borrow byteview aggregateCode,
    long aggregateCodeLength,
    borrow mut words placementRows,
    borrow mut words composedFunctionRows,
    borrow mut words composedInstructionRows,
    borrow mut words artifactSelectors
  ) {
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS + 1);
    assert(bufferLength(primitiveFunctionRows) == FUNCTION_ROWS);
    assert(-1 < primitiveInstructionCount);
    assert(primitiveInstructionCount < MAX_INSTRUCTIONS + 1);
    assert(bufferLength(primitiveInstructionRows) == INSTRUCTION_ROWS);
    assert(-1 < operationCount);
    assert(operationCount < MAX_OPERATIONS + 1);
    assert(-1 < aggregateCodeLength);
    assert(aggregateCodeLength < bufferLength(aggregateCode) + 1);
    assert(bufferLength(placementRows) == PLACEMENT_ROWS);
    assert(bufferLength(composedFunctionRows) == FUNCTION_ROWS);
    assert(bufferLength(composedInstructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(artifactSelectors) == SELECTOR_ROWS);
    assert(operationCount < MAX_INSTRUCTIONS - primitiveInstructionCount + 1);

    boolean valid = true;
    long function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      if (primitiveFunctionRows[function] != function) {
        valid = false;
      }

      function += 1;
    }

    long instruction = 0;
    long previousFunction = 0;
    long previousDirection = 0;
    while (instruction < primitiveInstructionCount) limit MAX_INSTRUCTIONS {
      long instructionFunction = primitiveInstructionRows[instruction];
      long primitiveDirection = primitiveInstructionRows[4096 + instruction];
      if (instructionFunction < 0) {
        valid = false;
      } else {
        if (functionCount < instructionFunction + 1) {
          valid = false;
        }
      }

      if (primitiveDirection < 0) {
        valid = false;
      }

      if (1 < primitiveDirection) {
        valid = false;
      }

      if (0 < instruction) {
        if (instructionFunction < previousFunction) {
          valid = false;
        }

        if (instructionFunction == previousFunction) {
          if (primitiveDirection < previousDirection) {
            valid = false;
          }
        }
      }

      if (primitiveInstructionRows[8192 + instruction] < 0) {
        valid = false;
      }

      long primitiveOpcode = primitiveInstructionRows[12288 + instruction];
      long primitiveOperands = primitiveInstructionRows[16384 + instruction];
      long primitiveLength = primitiveInstructionRows[20480 + instruction];
      if (expectedOperandCount(primitiveOpcode) != primitiveOperands) {
        valid = false;
      }

      if (primitiveLength != 8 + primitiveOperands * 8) {
        valid = false;
      }

      previousFunction = instructionFunction;
      previousDirection = primitiveDirection;
      instruction += 1;
    }

    long aggregateCursor = 0;
    long operation = 0;
    long previousPlacementFunction = 0;
    long previousPlacementDirection = 0;
    long previousOrdinal = 0;
    while (operation < operationCount) limit MAX_OPERATIONS {
      if (aggregateCodeLength - aggregateCursor < 8) {
        valid = false;
      }

      long aggregateOpcode = 0;
      long aggregateOperands = 0;
      long aggregateLength = 0;
      if (valid) {
        aggregateOpcode = readUnsigned(aggregateCode, aggregateCursor, 2);
        aggregateOperands = readUnsigned(aggregateCode, aggregateCursor + 2, 2);
        aggregateLength = readUnsigned(aggregateCode, aggregateCursor + 4, 4);
        if (expectedOperandCount(aggregateOpcode) != aggregateOperands) {
          valid = false;
        }

        if (aggregateLength != 8 + aggregateOperands * 8) {
          valid = false;
        }

        if (aggregateLength < aggregateCodeLength - aggregateCursor + 1) {} else {
          valid = false;
        }
      }

      long placementFunction = placementRows[operation];
      long placementDirection = placementRows[256 + operation];
      long placementOrdinal = placementRows[512 + operation];
      if (placementFunction < 0) {
        valid = false;
      } else {
        if (functionCount < placementFunction + 1) {
          valid = false;
        }
      }

      if (placementDirection < 0) {
        valid = false;
      }

      if (1 < placementDirection) {
        valid = false;
      }

      if (placementOrdinal < 0) {
        valid = false;
      }

      if (0 < operation) {
        if (placementFunction < previousPlacementFunction) {
          valid = false;
        }

        if (placementFunction == previousPlacementFunction) {
          if (placementDirection < previousPlacementDirection) {
            valid = false;
          }

          if (placementDirection == previousPlacementDirection) {
            if (placementOrdinal < previousOrdinal) {
              valid = false;
            }
          }
        }
      }

      aggregateCursor += aggregateLength;
      previousPlacementFunction = placementFunction;
      previousPlacementDirection = placementDirection;
      previousOrdinal = placementOrdinal;
      operation += 1;
    }

    if (aggregateCursor != aggregateCodeLength) {
      valid = false;
    }

    if (valid == false) {
      return new AggregateCompositionPlan(0, false);
    }

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 3);
    words stagedFunctions = allocate(staging, FUNCTION_ROWS);
    words stagedInstructions = allocate(staging, INSTRUCTION_ROWS);
    words stagedSelectors = allocate(staging, SELECTOR_ROWS);
    long copiedColumn = 0;
    while (copiedColumn < 10) limit 10 {
      long functionRow = 0;
      while (functionRow < functionCount) limit MAX_FUNCTIONS {
        set(
          stagedFunctions,
          copiedColumn * MAX_FUNCTIONS + functionRow,
          primitiveFunctionRows[copiedColumn * MAX_FUNCTIONS + functionRow]
        );
        functionRow += 1;
      }

      copiedColumn += 1;
    }

    long composedCount = 0;
    long placement = 0;
    aggregateCursor = 0;
    function = 0;
    while (function < functionCount) limit MAX_FUNCTIONS {
      long direction = 0;
      while (direction < 2) limit 2 {
        long primitiveOrdinal = 0;
        long primitive = 0;
        long directionLength = 0;
        while (primitive < primitiveInstructionCount) limit MAX_INSTRUCTIONS {
          if (primitiveInstructionRows[primitive] == function) {
            if (primitiveInstructionRows[4096 + primitive] == direction) {
              while (placement < operationCount) limit MAX_OPERATIONS {
                if (placementRows[placement] != function) {
                  break;
                }

                if (placementRows[256 + placement] != direction) {
                  break;
                }

                if (placementRows[512 + placement] != primitiveOrdinal) {
                  break;
                }

                long insertedOperands = readUnsigned(aggregateCode, aggregateCursor + 2, 2);
                long insertedLength = readUnsigned(aggregateCode, aggregateCursor + 4, 4);
                set(stagedInstructions, composedCount, function);
                set(stagedInstructions, 4096 + composedCount, direction);
                set(stagedInstructions, 8192 + composedCount, aggregateCursor);
                set(
                  stagedInstructions,
                  12288 + composedCount,
                  readUnsigned(aggregateCode, aggregateCursor, 2)
                );
                set(stagedInstructions, 16384 + composedCount, insertedOperands);
                set(stagedInstructions, 20480 + composedCount, insertedLength);
                set(stagedSelectors, composedCount, 1);
                directionLength += insertedLength;
                aggregateCursor += insertedLength;
                composedCount += 1;
                placement += 1;
              }

              set(stagedInstructions, composedCount, function);
              set(stagedInstructions, 4096 + composedCount, direction);
              set(
                stagedInstructions,
                8192 + composedCount,
                primitiveInstructionRows[8192 + primitive]
              );
              set(
                stagedInstructions,
                12288 + composedCount,
                primitiveInstructionRows[12288 + primitive]
              );
              set(
                stagedInstructions,
                16384 + composedCount,
                primitiveInstructionRows[16384 + primitive]
              );
              set(
                stagedInstructions,
                20480 + composedCount,
                primitiveInstructionRows[20480 + primitive]
              );
              directionLength += primitiveInstructionRows[20480 + primitive];
              composedCount += 1;
              primitiveOrdinal += 1;
            }
          }

          primitive += 1;
        }

        while (placement < operationCount) limit MAX_OPERATIONS {
          if (placementRows[placement] != function) {
            break;
          }

          if (placementRows[256 + placement] != direction) {
            break;
          }

          if (placementRows[512 + placement] != primitiveOrdinal) {
            valid = false;
            break;
          }

          long trailingOperands = readUnsigned(aggregateCode, aggregateCursor + 2, 2);
          long trailingLength = readUnsigned(aggregateCode, aggregateCursor + 4, 4);
          set(stagedInstructions, composedCount, function);
          set(stagedInstructions, 4096 + composedCount, direction);
          set(stagedInstructions, 8192 + composedCount, aggregateCursor);
          set(
            stagedInstructions,
            12288 + composedCount,
            readUnsigned(aggregateCode, aggregateCursor, 2)
          );
          set(stagedInstructions, 16384 + composedCount, trailingOperands);
          set(stagedInstructions, 20480 + composedCount, trailingLength);
          set(stagedSelectors, composedCount, 1);
          directionLength += trailingLength;
          aggregateCursor += trailingLength;
          composedCount += 1;
          placement += 1;
        }

        if (direction == 0) {
          set(stagedFunctions, 192 + function, directionLength);
        } else {
          set(stagedFunctions, 320 + function, directionLength);
        }

        direction += 1;
      }

      function += 1;
    }

    if (placement != operationCount) {
      valid = false;
    }

    if (aggregateCursor != aggregateCodeLength) {
      valid = false;
    }

    if (composedCount != primitiveInstructionCount + operationCount) {
      valid = false;
    }

    if (valid) {
      long publishedColumn = 0;
      while (publishedColumn < 10) limit 10 {
        long publishedFunctionRow = 0;
        while (publishedFunctionRow < functionCount) limit MAX_FUNCTIONS {
          set(
            composedFunctionRows,
            publishedColumn * MAX_FUNCTIONS + publishedFunctionRow,
            stagedFunctions[publishedColumn * MAX_FUNCTIONS + publishedFunctionRow]
          );
          publishedFunctionRow += 1;
        }

        publishedColumn += 1;
      }

      publishedColumn = 0;
      while (publishedColumn < 6) limit 6 {
        long instructionRow = 0;
        while (instructionRow < composedCount) limit MAX_INSTRUCTIONS {
          set(
            composedInstructionRows,
            publishedColumn * MAX_INSTRUCTIONS + instructionRow,
            stagedInstructions[publishedColumn * MAX_INSTRUCTIONS + instructionRow]
          );
          instructionRow += 1;
        }

        publishedColumn += 1;
      }

      long selector = 0;
      while (selector < composedCount) limit MAX_INSTRUCTIONS {
        set(artifactSelectors, selector, stagedSelectors[selector]);
        selector += 1;
      }
    }

    drop(stagedSelectors);
    drop(stagedInstructions);
    drop(stagedFunctions);
    drop(staging);
    return new AggregateCompositionPlan(composedCount, valid);
  }
}
