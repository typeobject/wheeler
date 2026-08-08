//! Binds canonical local and imported call relocations to one function identity.

module wheeler.compiler.closure.relocation_identities;

import wheeler.compiler.opcodes;
import wheeler.crypto.sha256;

classical class RelocationIdentities {
  private const long IDENTITY_BYTES = 32;
  private const long IMPORTED_IDENTITY_BYTES = 131072;
  private const long IMPORTED_ROWS = 12288;
  private const long INPUT_BYTES = 262400;
  private const long INSTRUCTION_ROWS = 24576;
  private const long LOCAL_IDENTITY_BYTES = 131072;
  private const long LOCAL_ROWS = 8192;
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

  private long writeSigned(long value, borrow mut bytes input, long cursor) {
    long remaining = value;
    long index = 0;
    while (index < 8) limit 8 {
      long octet = remaining % 256;
      if (octet < 0) {
        octet += 256;
      }

      setByte(input, cursor + index, octet);
      remaining = (remaining - octet) / 256;
      index += 1;
    }

    return cursor + 8;
  }

  private long copyRelocationIdentity(
    borrow byteview identities,
    long relocation,
    borrow mut bytes input,
    long cursor
  ) {
    long identityByte = 0;
    while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
      setByte(
        input,
        cursor + identityByte,
        identities[relocation * IDENTITY_BYTES + identityByte]
      );
      identityByte += 1;
    }

    return cursor + IDENTITY_BYTES;
  }

  /// Publishes one identity after both ordered relocation tables validate completely.
  public void publishRelocationIdentity(
    long function,
    long instructionCount,
    borrow mut words instructionRows,
    long localCount,
    borrow mut words localRows,
    borrow byteview localIdentities,
    long importedCount,
    borrow mut words importedRows,
    borrow byteview importedIdentities,
    borrow mut bytes identity
  ) {
    assert(-1 < function);
    assert(function < 64);
    assert(-1 < instructionCount);
    assert(instructionCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(-1 < localCount);
    assert(localCount < MAX_INSTRUCTIONS_PER_MODULE + 1);
    assert(-1 < importedCount);
    assert(importedCount < localCount + 1);
    assert(bufferLength(instructionRows) == INSTRUCTION_ROWS);
    assert(bufferLength(localRows) == LOCAL_ROWS);
    assert(bufferLength(localIdentities) == LOCAL_IDENTITY_BYTES);
    assert(bufferLength(importedRows) == IMPORTED_ROWS);
    assert(bufferLength(importedIdentities) == IMPORTED_IDENTITY_BYTES);
    assert(bufferLength(identity) == IDENTITY_BYTES);

    region product = new region(/* bytes= */ INPUT_BYTES, /* allocations= */ 1);
    bytes input = allocateBytes(product, INPUT_BYTES);
    writeAscii(input, 0, "wheeler-callable-relocation-product-1");
    long cursor = 45;
    long selectedCount = 0;
    long local = 0;
    long imported = 0;
    long instruction = 0;
    while (instruction < instructionCount) limit MAX_INSTRUCTIONS_PER_MODULE {
      long opcode = instructionRows[12288 + instruction];
      if (isCall(opcode)) {
        assert(local < localCount);
        assert(localRows[local] == instruction);
        boolean isImported = false;
        if (imported < importedCount) {
          if (importedRows[imported] == instruction) {
            isImported = true;
          }
        }

        if (instructionRows[instruction] == function) {
          cursor = writeSigned(instruction, input, cursor);
          cursor = writeSigned(instructionRows[4096 + instruction], input, cursor);
          if (isImported) {
            cursor = writeSigned(1, input, cursor);
            cursor = writeSigned(importedRows[8192 + imported], input, cursor);
            cursor = copyRelocationIdentity(importedIdentities, imported, input, cursor);
          } else {
            cursor = writeSigned(0, input, cursor);
            cursor = writeSigned(-1, input, cursor);
            cursor = copyRelocationIdentity(localIdentities, local, input, cursor);
          }

          selectedCount += 1;
        }

        local += 1;
        if (isImported) {
          assert(importedRows[4096 + imported] == localRows[4096 + local - 1]);
          imported += 1;
        }
      }

      instruction += 1;
    }

    assert(local == localCount);
    assert(imported == importedCount);
    long countEnd = writeSigned(selectedCount, input, 37);
    assert(countEnd == 45);
    assert(cursor < INPUT_BYTES + 1);
    region hashArena = new region(/* bytes= */ 1200, /* allocations= */ 3);
    hashSha256Range(input, 0, cursor, identity, hashArena);
    drop(hashArena);
    drop(input);
    drop(product);
  }
}
