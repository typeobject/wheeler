//! Resolves source-local call operands to stable callable signature identities.

module wheeler.compiler.closure.local_call_relocations;

import wheeler.compiler.opcodes;
import wheeler.core.encoding.binary;

classical class LocalCallRelocations {
  private const long FUNCTION_SIGNATURE_IDENTITY_BYTES = 2048;
  private const long IDENTITY_BYTES = 32;
  private const long INSTRUCTION_ROWS = 24576;
  private const long MAX_FUNCTIONS_PER_MODULE = 64;
  private const long MAX_INSTRUCTIONS_PER_MODULE = 4096;
  private const long RELOCATION_IDENTITY_BYTES = 131072;
  private const long RELOCATION_ROWS = 8192;

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

  /// Publishes local call targets and their stable identities after a complete scan.
  public long resolveLocalCallRelocations(
    borrow byteview artifact,
    long functionCount,
    long instructionCount,
    borrow mut words instructionRows,
    borrow byteview signatureIdentities,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities
  ) {
    assert(0 < functionCount);
    assert(functionCount < MAX_FUNCTIONS_PER_MODULE + 1);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(signatureIdentities) == FUNCTION_SIGNATURE_IDENTITY_BYTES);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITY_BYTES);

    long relocationCount = 0;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long opcode = instructionRows[12288 + instruction];
      if (isCall(opcode)) {
        long instructionStart = instructionRows[8192 + instruction];
        long target = readUnsigned(artifact, instructionStart + 8, 8);
        assert(target < functionCount);
        relocationCount += 1;
      }

      instruction += 1;
    }

    long relocation = 0;
    instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long selectedOpcode = instructionRows[12288 + instruction];
      if (isCall(selectedOpcode)) {
        long selectedStart = instructionRows[8192 + instruction];
        long selectedTarget = readUnsigned(artifact, selectedStart + 8, 8);
        set(relocationRows, relocation, instruction);
        set(relocationRows, 4096 + relocation, selectedTarget);
        long identityByte = 0;
        while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
          setByte(
            relocationIdentities,
            relocation * IDENTITY_BYTES + identityByte,
            signatureIdentities[selectedTarget * IDENTITY_BYTES + identityByte]
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
