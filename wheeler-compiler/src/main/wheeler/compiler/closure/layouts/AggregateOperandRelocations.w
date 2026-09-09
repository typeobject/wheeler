//! Resolves local and projected aggregate operands through one atomic publisher.

module wheeler.compiler.closure.aggregate_operand_relocations;

import wheeler.compiler.storage_opcodes;
import wheeler.core.encoding.binary;

classical class AggregateOperandRelocations {
  private const long IDENTITY_BYTES = 32;
  private const long LOCAL_AGGREGATE_ROWS = 576;
  private const long MAX_LOCAL_AGGREGATES = 64;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_INSTRUCTIONS = 4096;
  private const long MAX_PROJECTIONS = 16384;
  private const long PROJECTION_ROWS = 65536;
  private const long PROJECTION_IDENTITIES = 524288;
  private const long RELOCATION_ROWS = 12288;
  private const long RELOCATION_IDENTITIES = 131072;

  /// Reports the counted relocation window without publishing invalid products.
  public record AggregateOperandProjectionPlan(long relocationCount, boolean valid) {}

  private record OperandSelection(long row, boolean unique) {}

  private long aggregateKind(long opcode) {
    if (opcode == OPCODE_RECORD_NEW) {
      return 1;
    }

    if (opcode == OPCODE_ARRAY_NEW) {
      return 2;
    }

    if (opcode == OPCODE_SLICE_NEW) {
      return 3;
    }

    if (opcode == OPCODE_VARIANT_NEW) {
      return 4;
    }

    return 0;
  }

  private void requireInstructionColumns(
    long instructionCount,
    borrow mut words instructionRows,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities
  ) {
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITIES);
  }

  private boolean projectionRowsValid(long count, borrow mut words rows) {
    boolean valid = true;
    long row = 0;
    while (row < count) limit MAX_PROJECTIONS {
      long owner = rows[row];
      long kind = rows[16384 + row];
      long typeId = rows[32768 + row];
      long target = rows[49152 + row];
      if (owner < 0) {
        valid = false;
      }

      if (511 < owner) {
        valid = false;
      }

      if (kind < 1) {
        valid = false;
      }

      if (4 < kind) {
        valid = false;
      }

      if (typeId < 0) {
        valid = false;
      }

      if (target < 0) {
        valid = false;
      }

      if (4095 < target) {
        valid = false;
      }

      row += 1;
    }

    return valid;
  }

  private OperandSelection selectOperand(
    long moduleOwner,
    long kind,
    long typeId,
    long count,
    borrow mut words rows,
    boolean projected
  ) {
    long selected = -1;
    boolean unique = true;
    long row = 0;
    while (row < count) limit MAX_PROJECTIONS {
      boolean ownerMatches = true;
      long candidateKind = 0;
      long candidateType = 0;
      if (projected) {
        ownerMatches = rows[row] == moduleOwner;
        candidateKind = rows[16384 + row];
        candidateType = rows[32768 + row];
      } else {
        candidateKind = rows[row];
        candidateType = rows[128 + row];
      }

      if (ownerMatches) {
        if (candidateKind == kind) {
          if (candidateType == typeId) {
            if (-1 < selected) {
              unique = false;
            }

            selected = row;
          }
        }
      }

      row += 1;
    }

    return new OperandSelection(selected, unique);
  }

  private AggregateOperandProjectionPlan relocateOperands(
    borrow byteview artifact,
    long moduleOwner,
    long instructionCount,
    borrow mut words instructionRows,
    long bindingCount,
    borrow mut words bindingRows,
    borrow byteview bindingIdentities,
    boolean projected,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities
  ) {
    boolean valid = true;
    if (projected) {
      valid = projectionRowsValid(bindingCount, bindingRows);
    }

    region staging = new region(/* bytes= */ 229376, /* allocations= */ 2);
    words stagedRows = allocate(staging, RELOCATION_ROWS);
    bytes stagedIdentities = allocateBytes(staging, RELOCATION_IDENTITIES);
    long relocationCount = 0;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS {
      long kind = aggregateKind(instructionRows[12288 + instruction]);
      if (0 < kind) {
        long start = instructionRows[8192 + instruction];
        if (start < 0) {
          valid = false;
        }

        if (valid) {
          if (bufferLength(artifact) < start) {
            valid = false;
          }
        }

        if (valid) {
          if (bufferLength(artifact) - start < 24) {
            valid = false;
          }
        }

        long typeId = -1;
        if (valid) {
          typeId = readUnsigned(artifact, start + 16, 8);
        }

        OperandSelection selection = selectOperand(
          moduleOwner,
          kind,
          typeId,
          bindingCount,
          bindingRows,
          projected
        );
        if (selection.unique == false) {
          valid = false;
        }

        if (-1 < selection.row) {
          long target = selection.row;
          long identityStart = 0;
          if (projected) {
            target = bindingRows[49152 + selection.row];
            identityStart = selection.row * IDENTITY_BYTES;
          }

          set(stagedRows, relocationCount, instruction);
          set(stagedRows, 4096 + relocationCount, target);
          set(stagedRows, 8192 + relocationCount, kind);
          long byte = 0;
          while (byte < IDENTITY_BYTES) limit IDENTITY_BYTES {
            setByte(
              stagedIdentities,
              relocationCount * IDENTITY_BYTES + byte,
              bindingIdentities[identityStart + byte]
            );
            byte += 1;
          }

          relocationCount += 1;
        } else {
          if (projected == false) {
            valid = false;
          }
        }
      }

      instruction += 1;
    }

    if (valid) {
      long column = 0;
      while (column < 3) limit 3 {
        long row = 0;
        while (row < relocationCount) limit MAX_INSTRUCTIONS {
          set(
            relocationRows,
            column * MAX_INSTRUCTIONS + row,
            stagedRows[column * MAX_INSTRUCTIONS + row]
          );
          row += 1;
        }

        column += 1;
      }

      long publishedByte = 0;
      while (publishedByte < relocationCount * IDENTITY_BYTES) limit RELOCATION_IDENTITIES {
        setByte(relocationIdentities, publishedByte, stagedIdentities[publishedByte]);
        publishedByte += 1;
      }
    }

    drop(stagedIdentities);
    drop(stagedRows);
    drop(staging);
    return new AggregateOperandProjectionPlan(relocationCount, valid);
  }

  /// Resolves every constructor against one checked source-local aggregate product.
  /// A missing or duplicate target traps without changing any caller relocation cell.
  public long resolveAggregateOperandRelocations(
    borrow byteview artifact,
    long instructionCount,
    borrow mut words instructionRows,
    long aggregateCount,
    borrow mut words aggregateRows,
    borrow byteview aggregateIdentity,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities
  ) {
    requireInstructionColumns(
      instructionCount,
      instructionRows,
      relocationRows,
      relocationIdentities
    );
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_LOCAL_AGGREGATES + 1);
    assert(bufferLength(aggregateRows) == LOCAL_AGGREGATE_ROWS);
    assert(bufferLength(aggregateIdentity) == IDENTITY_BYTES);
    AggregateOperandProjectionPlan result = relocateOperands(
      artifact,
      0,
      instructionCount,
      instructionRows,
      aggregateCount,
      aggregateRows,
      aggregateIdentity,
      false,
      relocationRows,
      relocationIdentities
    );
    assert(result.valid);
    return result.relocationCount;
  }

  /// Publishes only operands matched by one unique owner-scoped projection.
  /// Unmatched constructors remain outside this filtered product, not implicitly resolved.
  public AggregateOperandProjectionPlan projectAggregateOperandRelocations(
    borrow byteview artifact,
    long moduleOwner,
    long instructionCount,
    borrow mut words instructionRows,
    long projectionCount,
    borrow mut words projectionRows,
    borrow byteview projectionIdentities,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities
  ) {
    requireInstructionColumns(
      instructionCount,
      instructionRows,
      relocationRows,
      relocationIdentities
    );
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < projectionCount);
    assert(projectionCount < MAX_PROJECTIONS + 1);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(projectionIdentities) == PROJECTION_IDENTITIES);
    return relocateOperands(
      artifact,
      moduleOwner,
      instructionCount,
      instructionRows,
      projectionCount,
      projectionRows,
      projectionIdentities,
      true,
      relocationRows,
      relocationIdentities
    );
  }
}
