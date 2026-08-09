//! Lowers counted aggregate operations into canonical instruction bytes.

module wheeler.compiler.closure.aggregate_instruction_products;

import wheeler.compiler.aggregate_codegen;
import wheeler.compiler.closure.source_aggregate_operations;
import wheeler.compiler.instruction_forms;
import wheeler.compiler.storage_opcodes;

classical class AggregateInstructionProducts {
  private const long MAX_INSTRUCTIONS = 4096;
  private const long OPERATION_ROWS = 24576;

  /// Reports the exact canonical instruction count and byte extent.
  public record AggregateInstructionProductPlan(long instructionCount, long length) {}

  private boolean aggregateOpcode(long opcode) {
    if (opcode == OPCODE_RECORD_NEW) {
      return true;
    }

    if (opcode == OPCODE_RECORD_GET) {
      return true;
    }

    if (opcode == OPCODE_VARIANT_NEW) {
      return true;
    }

    if (opcode == OPCODE_VARIANT_TAG_EQ) {
      return true;
    }

    if (opcode == OPCODE_VARIANT_GET) {
      return true;
    }

    if (opcode == OPCODE_ARRAY_NEW) {
      return true;
    }

    if (opcode == OPCODE_ARRAY_GET) {
      return true;
    }

    if (opcode == OPCODE_SLICE_NEW) {
      return true;
    }

    return opcode == OPCODE_SLICE_GET;
  }

  /// Validates a complete operation window before emitting one instruction header.
  public AggregateInstructionProductPlan writeAggregateInstructionProduct(
    long operationCount,
    borrow mut words operationRows,
    borrow mut bytes output
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_INSTRUCTIONS + 1);
    assert(bufferLength(operationRows) == OPERATION_ROWS);
    long requiredBytes = 0;
    long operation = 0;
    while (operation < operationCount) limit MAX_INSTRUCTIONS {
      long validatedOpcode = operationRows[operation];
      assert(aggregateOpcode(validatedOpcode));
      long operandCount = expectedOperandCount(validatedOpcode);
      assert(2 < operandCount);
      assert(operandCount < 6);
      assert(-1 < operationRows[4096 + operation]);
      assert(-1 < operationRows[8192 + operation]);
      assert(-1 < operationRows[12288 + operation]);
      if (3 < operandCount) {
        assert(-1 < operationRows[16384 + operation]);
      } else {
        assert(operationRows[16384 + operation] == 0);
      }

      if (4 < operandCount) {
        assert(-1 < operationRows[20480 + operation]);
      } else {
        assert(operationRows[20480 + operation] == 0);
      }

      requiredBytes += 8 + operandCount * 8;
      assert(requiredBytes < bufferLength(output) + 1);
      operation += 1;
    }

    long cursor = 0;
    operation = 0;
    while (operation < operationCount) limit MAX_INSTRUCTIONS {
      long emittedOpcode = operationRows[operation];
      long first = operationRows[4096 + operation];
      long second = operationRows[8192 + operation];
      long third = operationRows[12288 + operation];
      long fourth = operationRows[16384 + operation];
      long fifth = operationRows[20480 + operation];
      if (emittedOpcode == OPCODE_RECORD_NEW) {
        cursor = writeRecordConstruction(output, cursor, first, second, third, fourth);
      }

      if (emittedOpcode == OPCODE_RECORD_GET) {
        cursor = writeRecordProjection(output, cursor, first, second, third);
      }

      if (emittedOpcode == OPCODE_VARIANT_NEW) {
        cursor = writeVariantConstruction(
          output,
          cursor,
          first,
          second,
          third,
          fourth,
          fifth
        );
      }

      if (emittedOpcode == OPCODE_VARIANT_TAG_EQ) {
        cursor = writeVariantCaseTest(output, cursor, first, second, third);
      }

      if (emittedOpcode == OPCODE_VARIANT_GET) {
        cursor = writeVariantProjection(output, cursor, first, second, third, fourth);
      }

      if (emittedOpcode == OPCODE_ARRAY_NEW) {
        cursor = writeArrayConstruction(output, cursor, first, second, third, fourth);
      }

      if (emittedOpcode == OPCODE_ARRAY_GET) {
        cursor = writeArrayProjection(output, cursor, first, second, third);
      }

      if (emittedOpcode == OPCODE_SLICE_NEW) {
        cursor = writeSliceConstruction(output, cursor, first, second, third, fourth, fifth);
      }

      if (emittedOpcode == OPCODE_SLICE_GET) {
        cursor = writeSliceProjection(output, cursor, first, second, third);
      }

      operation += 1;
    }

    assert(cursor == requiredBytes);
    return new AggregateInstructionProductPlan(operationCount, cursor);
  }
}
