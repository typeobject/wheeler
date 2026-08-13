//! Joins loop-body call rows to canonical code and relocation products.

module wheeler.compiler.closure.loop_call_products;

import wheeler.compiler.encoding;
import wheeler.compiler.encoding_widths;
import wheeler.compiler.opcodes;
import wheeler.compiler.type_codes;

classical class LoopCallProducts {
  private const long CALL_COUNT_LIMIT = 256;
  private const long CALL_KIND_ROW = 256;
  private const long CALL_LOCAL_BASE_ROW = 512;
  private const long CALL_TARGET_ROW = 768;
  private const long CALL_ROWS = 1024;
  private const long CALL_VOID = 0;
  private const long CALL_VALUE_BOOLEAN = 2;
  private const long CALL_VALUE_SIGNED = 1;
  private const long IDENTITY_BYTES = 32;
  private const long MAX_CODE_BYTES = 262144;
  private const long RELOCATION_IDENTITY_BYTES = 8192;
  private const long RELOCATION_ROWS = 768;
  private const long TARGET_COUNT_LIMIT = 4096;
  private const long TARGET_IDENTITY_BYTES = 131072;
  private const long U64 = ENCODING_WIDTH_U64;

  /// Reports one complete loop call and relocation extent.
  public record LoopCallPlan(
    long instructionCount,
    long length,
    long relocationCount,
    boolean valid
  ) {}

  private boolean validKind(long kind) {
    if (kind == CALL_VOID) {
      return true;
    }

    if (kind == CALL_VALUE_SIGNED) {
      return true;
    }

    return kind == CALL_VALUE_BOOLEAN;
  }

  private long writeCall(
    borrow mut bytes output,
    long cursor,
    long kind,
    long localBase,
    long target
  ) {
    if (kind == CALL_VOID) {
      cursor = writeInstructionHeader(output, cursor, OPCODE_CALL, INSTRUCTION_FORM_UNARY);
      return writeUnsignedLittleEndian(output, cursor, target, U64);
    }

    cursor = writeInstructionHeader(output, cursor, OPCODE_CALL_VALUE, INSTRUCTION_FORM_QUATERNARY);
    cursor = writeUnsignedLittleEndian(output, cursor, target, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* argumentBase= */ 0, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, /* argumentCount= */ 0, U64);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase, U64);
    cursor = writeInstructionHeader(output, cursor, OPCODE_LOCAL_MOVE, INSTRUCTION_FORM_BINARY);
    cursor = writeUnsignedLittleEndian(output, cursor, localBase + 1, U64);
    return writeUnsignedLittleEndian(output, cursor, localBase, U64);
  }

  /// Emits validated zero-argument calls and their stable target identities atomically.
  public LoopCallPlan writeLoopCallProducts(
    long callCount,
    borrow mut words callRows,
    long targetCount,
    borrow byteview targetIdentities,
    long instructionBase,
    borrow mut words relocationRows,
    borrow mut bytes relocationIdentities,
    borrow mut words localTypeRows,
    borrow mut bytes output
  ) {
    assert(-1 < callCount);
    assert(callCount < CALL_COUNT_LIMIT + 1);
    assert(bufferLength(callRows) == CALL_ROWS);
    assert(-1 < targetCount);
    assert(targetCount < TARGET_COUNT_LIMIT + 1);
    assert(bufferLength(targetIdentities) == TARGET_IDENTITY_BYTES);
    assert(-1 < instructionBase);
    assert(bufferLength(relocationRows) == RELOCATION_ROWS);
    assert(bufferLength(relocationIdentities) == RELOCATION_IDENTITY_BYTES);
    assert(bufferLength(localTypeRows) == CALL_COUNT_LIMIT * 2);
    assert(bufferLength(output) == MAX_CODE_BYTES);

    boolean valid = true;
    long length = 0;
    long instructionCount = 0;
    long call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long kind = callRows[CALL_KIND_ROW + call];
      long localBase = callRows[CALL_LOCAL_BASE_ROW + call];
      long target = callRows[CALL_TARGET_ROW + call];
      if (validKind(kind) == false) {
        valid = false;
      }

      if (localBase < 0) {
        valid = false;
      }

      if (255 < localBase) {
        valid = false;
      }

      if (target < 0) {
        valid = false;
      }

      if (targetCount - 1 < target) {
        valid = false;
      }

      if (kind == CALL_VOID) {
        length += 16;
        instructionCount += 1;
      } else {
        if (254 < localBase) {
          valid = false;
        }

        length += 64;
        instructionCount += 2;
      }

      if (MAX_CODE_BYTES < length) {
        valid = false;
      }

      call += 1;
    }

    if (valid == false) {
      return new LoopCallPlan(0, 0, 0, false);
    }

    region staging = new region(/* bytes= */ 280576, /* allocations= */ 4);
    words stagedRelocations = allocate(staging, RELOCATION_ROWS);
    bytes stagedIdentities = allocateBytes(staging, RELOCATION_IDENTITY_BYTES);
    words stagedTypes = allocate(staging, CALL_COUNT_LIMIT * 2);
    bytes stagedCode = allocateBytes(staging, MAX_CODE_BYTES);
    long cursor = 0;
    long emittedInstruction = instructionBase;
    call = 0;
    while (call < callCount) limit CALL_COUNT_LIMIT {
      long emittedKind = callRows[CALL_KIND_ROW + call];
      long emittedLocalBase = callRows[CALL_LOCAL_BASE_ROW + call];
      long emittedTarget = callRows[CALL_TARGET_ROW + call];
      set(stagedRelocations, call, emittedInstruction);
      set(stagedRelocations, CALL_COUNT_LIMIT + call, emittedTarget);
      set(stagedRelocations, CALL_COUNT_LIMIT * 2 + call, callRows[call]);
      long identityByte = 0;
      while (identityByte < IDENTITY_BYTES) limit IDENTITY_BYTES {
        setByte(
          stagedIdentities,
          call * IDENTITY_BYTES + identityByte,
          targetIdentities[emittedTarget * IDENTITY_BYTES + identityByte]
        );
        identityByte += 1;
      }

      cursor = writeCall(stagedCode, cursor, emittedKind, emittedLocalBase, emittedTarget);
      if (emittedKind == CALL_VOID) {
        emittedInstruction += 1;
      } else {
        long type = TYPE_SIGNED;
        if (emittedKind == CALL_VALUE_BOOLEAN) {
          type = TYPE_BOOLEAN;
        }

        set(stagedTypes, call * 2, type);
        set(stagedTypes, call * 2 + 1, type);
        emittedInstruction += 2;
      }

      call += 1;
    }

    long row = 0;
    while (row < RELOCATION_ROWS) limit RELOCATION_ROWS {
      set(relocationRows, row, stagedRelocations[row]);
      row += 1;
    }

    long identityOffset = 0;
    while (identityOffset < RELOCATION_IDENTITY_BYTES) limit RELOCATION_IDENTITY_BYTES {
      setByte(relocationIdentities, identityOffset, stagedIdentities[identityOffset]);
      identityOffset += 1;
    }

    row = 0;
    while (row < CALL_COUNT_LIMIT * 2) limit 512 {
      set(localTypeRows, row, stagedTypes[row]);
      row += 1;
    }

    long codeByte = 0;
    while (codeByte < cursor) limit MAX_CODE_BYTES {
      setByte(output, codeByte, stagedCode[codeByte]);
      codeByte += 1;
    }

    drop(stagedCode);
    drop(stagedTypes);
    drop(stagedIdentities);
    drop(stagedRelocations);
    drop(staging);
    return new LoopCallPlan(instructionCount, cursor, callCount, true);
  }
}
