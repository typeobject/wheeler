//! Relocates aggregate-construction operands to validated aggregate products.

module wheeler.compiler.closure.aggregate_operand_relocations;

import wheeler.compiler.storage_opcodes;
import wheeler.core.encoding.binary;

classical class AggregateOperandRelocations {
  private const long AGGREGATE_IDENTITY_BYTES = 32;
  private const long AGGREGATE_ROWS = 576;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_AGGREGATES_PER_MODULE = 64;
  private const long MAX_INSTRUCTIONS_PER_MODULE = 4096;
  private const long RELOCATION_IDENTITY_BYTES = 131072;
  private const long RELOCATION_ROWS = 12288;

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

  private long matchingAggregate(
    long kind,
    long typeId,
    long aggregateCount,
    borrow mut words aggregateRows
  ) {
    long selected = -1;
    long aggregate = 0;
    while (aggregate < aggregateCount) limit MAX_AGGREGATES_PER_MODULE {
      if (aggregateRows[aggregate] == kind) {
        if (aggregateRows[128 + aggregate] == typeId) {
          assert(selected == -1);
          selected = aggregate;
        }
      }

      aggregate += 1;
    }

    assert(-1 < selected);
    return selected;
  }

  /// Publishes descriptor rows and product identities after every operand resolves.
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
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(-1 < aggregateCount);
    assert(aggregateCount < MAX_AGGREGATES_PER_MODULE + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(aggregateRows) == AGGREGATE_ROWS);
    assert(bufferLength(aggregateIdentity) == AGGREGATE_IDENTITY_BYTES);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITY_BYTES);

    long relocationCount = 0;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long kind = aggregateKind(instructionRows[12288 + instruction]);
      if (0 < kind) {
        long start = instructionRows[8192 + instruction];
        assert(-1 < start);
        long typeId = readUnsigned(artifact, start + 16, 8);
        long selected = matchingAggregate(kind, typeId, aggregateCount, aggregateRows);
        assert(-1 < selected);
        relocationCount += 1;
      }

      instruction += 1;
    }

    long relocation = 0;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long selectedKind = aggregateKind(instructionRows[12288 + instruction]);
      if (0 < selectedKind) {
        long selectedStart = instructionRows[8192 + instruction];
        long selectedTypeId = readUnsigned(artifact, selectedStart + 16, 8);
        long selectedAggregate = matchingAggregate(
          selectedKind,
          selectedTypeId,
          aggregateCount,
          aggregateRows
        );
        set(relocationRows, relocation, instruction);
        set(relocationRows, 4096 + relocation, selectedAggregate);
        set(relocationRows, 8192 + relocation, selectedKind);
        long identityByte = 0;
        while (identityByte < AGGREGATE_IDENTITY_BYTES) limit AGGREGATE_IDENTITY_BYTES {
          setByte(
            relocationIdentities,
            relocation * AGGREGATE_IDENTITY_BYTES + identityByte,
            aggregateIdentity[identityByte]
          );
          identityByte += 1;
        }

        relocation += 1;
      }

      instruction += 1;
    }

    assert(relocation == relocationCount);
    return relocationCount;
  }
}
