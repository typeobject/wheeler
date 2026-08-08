//! Validates linked cross-module calls against public callable identities.

module wheeler.compiler.closure.imported_call_relocations;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;

classical class ImportedCallRelocations {
  private const long FUNCTION_IDENTITY_BYTES = 2048;
  private const long IDENTITY_BYTES = 32;
  private const long IMPORTED_IDENTITY_BYTES = 131072;
  private const long IMPORTED_ROWS = 12288;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_FUNCTIONS_PER_MODULE = 64;
  private const long MAX_INSTRUCTIONS_PER_MODULE = 4096;

  private boolean isCall(long opcode) {
    boolean call = false;
    if (opcode == OPCODE_CALL) {
      call = true;
    }

    if (opcode == OPCODE_UNCALL) {
      call = true;
    }

    if (opcode == OPCODE_CALL_VALUE) {
      call = true;
    }

    if (opcode == OPCODE_CALL_VOID) {
      call = true;
    }

    if (opcode == OPCODE_CALL_RESULT_SLOT) {
      call = true;
    }

    if (opcode == OPCODE_UNCALL_RESULT_SLOT) {
      call = true;
    }

    return call;
  }

  /// Publishes linked cross-module targets only after every visibility check passes.
  public long resolveImportedCallRelocations(
    borrow byteview artifact,
    long functionCount,
    long instructionCount,
    borrow mut words instructionRows,
    borrow mut words functionOwners,
    borrow mut words functionVisibilities,
    borrow byteview functionIdentities,
    borrow mut words importedRows,
    borrow mut bytes importedIdentities
  ) {
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS_PER_MODULE + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(functionOwners) == MAX_FUNCTIONS_PER_MODULE);
    assert(bufferLength(functionVisibilities) == MAX_FUNCTIONS_PER_MODULE);
    assert(bufferLength(functionIdentities) == FUNCTION_IDENTITY_BYTES);
    assert(bufferLength(importedRows) == IMPORTED_ROWS);
    assert(bufferLength(importedIdentities) == IMPORTED_IDENTITY_BYTES);

    long importedCount = 0;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long opcode = instructionRows[12288 + instruction];
      if (isCall(opcode)) {
        long caller = instructionRows[instruction];
        assert(caller < functionCount);
        long start = instructionRows[8192 + instruction];
        long target = readUnsigned(artifact, start + 8, 8);
        assert(target < functionCount);
        if (functionOwners[caller] != functionOwners[target]) {
          assert(functionVisibilities[target] == 1);
          importedCount += 1;
        }
      }

      instruction += 1;
    }

    long imported = 0;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long selectedOpcode = instructionRows[12288 + instruction];
      if (isCall(selectedOpcode)) {
        long selectedCaller = instructionRows[instruction];
        long selectedStart = instructionRows[8192 + instruction];
        long selectedTarget = readUnsigned(artifact, selectedStart + 8, 8);
        if (functionOwners[selectedCaller] != functionOwners[selectedTarget]) {
          set(importedRows, imported, instruction);
          set(importedRows, 4096 + imported, selectedTarget);
          set(importedRows, 8192 + imported, functionOwners[selectedTarget]);
          long identityByte = 0;
          while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
            setByte(
              importedIdentities,
              imported * IDENTITY_BYTES + identityByte,
              functionIdentities[selectedTarget * IDENTITY_BYTES + identityByte]
            );
            identityByte += 1;
          }

          imported += 1;
        }
      }

      instruction += 1;
    }

    assert(imported == importedCount);
    return importedCount;
  }
}
