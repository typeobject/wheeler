//! Resolves aggregate construction operands through temporary nominal projections.

module wheeler.compiler.closure.aggregate_operand_projections;

import wheeler.compiler.storage_opcodes;
import wheeler.core.encoding.binary;

classical class AggregateOperandProjections {
  private const long IDENTITY_BYTES = 32;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_INSTRUCTIONS = 4096;
  private const long MAX_PROJECTIONS = 16384;
  private const long PROJECTION_IDENTITIES = 524288;
  private const long PROJECTION_ROWS = 65536;
  private const long RELOCATION_IDENTITIES = 131072;
  private const long RELOCATION_ROWS = 12288;
  private const long STAGING_BYTES = 229376;

  /// Reports the projected aggregate operand relocation extent.
  public record AggregateOperandProjectionPlan(long relocationCount, boolean valid) {}

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

  /// Publishes only operands matched by one unique owner-scoped projection.
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
    assert(-1 < moduleOwner);
    assert(moduleOwner < 512);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(-1 < projectionCount);
    assert(projectionCount < MAX_PROJECTIONS + 1);
    assert(bufferLength(projectionRows) == PROJECTION_ROWS);
    assert(bufferLength(projectionIdentities) == PROJECTION_IDENTITIES);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITIES);

    boolean valid = true;
    long projection = 0;
    while (projection < projectionCount) limit MAX_PROJECTIONS {
      long projectionOwner = projectionRows[projection];
      long projectionKind = projectionRows[16384 + projection];
      long projectionTypeId = projectionRows[32768 + projection];
      long projectionTarget = projectionRows[49152 + projection];
      if (projectionOwner < 0) {
        valid = false;
      }

      if (511 < projectionOwner) {
        valid = false;
      }

      if (projectionKind < 1) {
        valid = false;
      }

      if (4 < projectionKind) {
        valid = false;
      }

      if (projectionTypeId < 0) {
        valid = false;
      }

      if (projectionTarget < 0) {
        valid = false;
      }

      if (4095 < projectionTarget) {
        valid = false;
      }

      projection += 1;
    }

    region staging = new region(/* bytes= */ STAGING_BYTES, /* allocations= */ 2);
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

        long selected = -1;
        projection = 0;
        while (projection < projectionCount) limit MAX_PROJECTIONS {
          if (projectionRows[projection] == moduleOwner) {
            if (projectionRows[16384 + projection] == kind) {
              if (projectionRows[32768 + projection] == typeId) {
                if (-1 < selected) {
                  valid = false;
                }

                selected = projection;
              }
            }
          }

          projection += 1;
        }

        if (-1 < selected) {
          set(stagedRows, relocationCount, instruction);
          set(stagedRows, 4096 + relocationCount, projectionRows[49152 + selected]);
          set(stagedRows, 8192 + relocationCount, kind);
          long identityByte = 0;
          while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
            setByte(
              stagedIdentities,
              relocationCount * IDENTITY_BYTES + identityByte,
              projectionIdentities[selected * IDENTITY_BYTES + identityByte]
            );
            identityByte += 1;
          }

          relocationCount += 1;
        }
      }

      instruction += 1;
    }

    if (valid) {
      long row = 0;
      while (row < RELOCATION_ROWS) limit RELOCATION_ROWS {
        set(relocationRows, row, stagedRows[row]);
        row += 1;
      }

      long identity = 0;
      while (identity < RELOCATION_IDENTITIES) limit RELOCATION_IDENTITIES {
        setByte(relocationIdentities, identity, stagedIdentities[identity]);
        identity += 1;
      }
    }

    drop(stagedIdentities);
    drop(stagedRows);
    drop(staging);
    return new AggregateOperandProjectionPlan(relocationCount, valid);
  }
}
