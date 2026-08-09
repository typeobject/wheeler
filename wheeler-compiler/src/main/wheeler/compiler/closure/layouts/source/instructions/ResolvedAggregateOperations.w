//! Joins source aggregate ranges to resolved operands before canonical lowering.

module wheeler.compiler.closure.resolved_aggregate_operations;

import wheeler.compiler.closure.aggregate_instruction_products;
import wheeler.compiler.storage_opcodes;

classical class ResolvedAggregateOperations {
  private const long MAX_SOURCE_OPERATIONS = 256;
  private const long SOURCE_OPERATION_ROWS = 2048;
  private const long RESOLVED_OPERATION_ROWS = 1536;
  private const long CANONICAL_OPERATION_ROWS = 24576;

  private boolean compatibleOperation(long sourceKind, long opcode) {
    if (sourceKind == 1) {
      if (opcode == OPCODE_RECORD_NEW) {
        return true;
      }

      return opcode == OPCODE_ARRAY_NEW;
    }

    if (sourceKind == 2) {
      return opcode == OPCODE_VARIANT_NEW;
    }

    if (sourceKind == 3) {
      if (opcode == OPCODE_RECORD_GET) {
        return true;
      }

      return opcode == OPCODE_VARIANT_GET;
    }

    if (sourceKind == 4) {
      if (opcode == OPCODE_ARRAY_GET) {
        return true;
      }

      return opcode == OPCODE_SLICE_GET;
    }

    if (sourceKind == 5) {
      return opcode == OPCODE_SLICE_NEW;
    }

    return false;
  }

  /// Emits source-ordered operations after exact kind and operand resolution.
  public AggregateInstructionProductPlan writeResolvedSourceAggregateInstructions(
    long operationCount,
    borrow mut words sourceOperationRows,
    borrow mut words resolvedOperationRows,
    borrow mut bytes output
  ) {
    assert(-1 < operationCount);
    assert(operationCount < MAX_SOURCE_OPERATIONS + 1);
    assert(bufferLength(sourceOperationRows) == SOURCE_OPERATION_ROWS);
    assert(bufferLength(resolvedOperationRows) == RESOLVED_OPERATION_ROWS);
    long operation = 0;
    while (operation < operationCount) limit MAX_SOURCE_OPERATIONS {
      long sourceKind = sourceOperationRows[operation];
      long opcode = resolvedOperationRows[operation];
      assert(compatibleOperation(sourceKind, opcode));
      operation += 1;
    }

    region canonical = new region(/* bytes= */ 196608, /* allocations= */ 1);
    words canonicalRows = allocate(canonical, CANONICAL_OPERATION_ROWS);
    operation = 0;
    while (operation < operationCount) limit MAX_SOURCE_OPERATIONS {
      set(canonicalRows, operation, resolvedOperationRows[operation]);
      set(canonicalRows, 4096 + operation, resolvedOperationRows[256 + operation]);
      set(canonicalRows, 8192 + operation, resolvedOperationRows[512 + operation]);
      set(canonicalRows, 12288 + operation, resolvedOperationRows[768 + operation]);
      set(canonicalRows, 16384 + operation, resolvedOperationRows[1024 + operation]);
      set(canonicalRows, 20480 + operation, resolvedOperationRows[1280 + operation]);
      operation += 1;
    }

    AggregateInstructionProductPlan product = writeAggregateInstructionProduct(
      operationCount,
      canonicalRows,
      output
    );
    drop(canonicalRows);
    drop(canonical);
    return product;
  }
}
