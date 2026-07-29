package com.typeobject.wheeler.core.bytecode;

import java.util.Arrays;

/** Classical Wheeler opcodes. Numeric codes are stable first-format artifact identities. */
public enum Opcode {
  NOP(OpcodeIds.NOP, InstructionForm.NONE, Reversibility.INTRINSIC),
  HALT(OpcodeIds.HALT, InstructionForm.NONE, Reversibility.CHECKED),
  RETURN(OpcodeIds.RETURN, InstructionForm.NONE, Reversibility.CHECKED),

  ADD_CONST(OpcodeIds.ADD_CONST, InstructionForm.GLOBAL_IMMEDIATE, Reversibility.INTRINSIC),
  SUB_CONST(OpcodeIds.SUB_CONST, InstructionForm.GLOBAL_IMMEDIATE, Reversibility.INTRINSIC),
  XOR_CONST(OpcodeIds.XOR_CONST, InstructionForm.GLOBAL_IMMEDIATE, Reversibility.INTRINSIC),
  SWAP(OpcodeIds.SWAP, InstructionForm.GLOBAL_PAIR, Reversibility.INTRINSIC),
  SET_LOGGED(OpcodeIds.SET_LOGGED, InstructionForm.GLOBAL_IMMEDIATE, Reversibility.LOGGED),

  CALL(OpcodeIds.CALL, InstructionForm.FUNCTION, Reversibility.CHECKED),
  UNCALL(OpcodeIds.UNCALL, InstructionForm.FUNCTION, Reversibility.CHECKED),
  CALL_VALUE(OpcodeIds.CALL_VALUE, InstructionForm.CALL_VALUE, Reversibility.CHECKED),
  CALL_VOID(OpcodeIds.CALL_VOID, InstructionForm.CALL_VOID, Reversibility.CHECKED),
  RETURN_VALUE(OpcodeIds.RETURN_VALUE, InstructionForm.RESULT, Reversibility.CHECKED),
  CALL_RESULT_SLOT(
      OpcodeIds.CALL_RESULT_SLOT, InstructionForm.CALL_RESULT_SLOT, Reversibility.CHECKED),
  UNCALL_RESULT_SLOT(
      OpcodeIds.UNCALL_RESULT_SLOT, InstructionForm.CALL_RESULT_SLOT, Reversibility.CHECKED),
  RESULT_FILL_CONSTANT(
      OpcodeIds.RESULT_FILL_CONSTANT, InstructionForm.RESULT_CONSTANT, Reversibility.INTRINSIC),
  RESULT_FILL_SOURCE(
      OpcodeIds.RESULT_FILL_SOURCE, InstructionForm.RESULT_SOURCE, Reversibility.INTRINSIC),
  RESULT_FILL_BINARY(
      OpcodeIds.RESULT_FILL_BINARY, InstructionForm.RESULT_BINARY, Reversibility.INTRINSIC),
  RETURN_RESULT_SLOT(
      OpcodeIds.RETURN_RESULT_SLOT, InstructionForm.RESULT_SLOT, Reversibility.CHECKED),

  EXPECT_EQ(OpcodeIds.EXPECT_EQ, InstructionForm.GLOBAL_IMMEDIATE, Reversibility.CHECKED),
  CHECKPOINT(OpcodeIds.CHECKPOINT, InstructionForm.NONE, Reversibility.INTRINSIC),
  COMMIT(OpcodeIds.COMMIT, InstructionForm.NONE, Reversibility.BARRIER),
  EXPECT_TRUE(OpcodeIds.EXPECT_TRUE, InstructionForm.CONDITION, Reversibility.CHECKED),

  LOCAL_CONST(OpcodeIds.LOCAL_CONST, InstructionForm.LOCAL_IMMEDIATE, Reversibility.CHECKED),
  LOCAL_LOAD_GLOBAL(OpcodeIds.LOCAL_LOAD_GLOBAL, InstructionForm.LOCAL_GLOBAL,
      Reversibility.CHECKED),
  LOCAL_STORE_GLOBAL(OpcodeIds.LOCAL_STORE_GLOBAL, InstructionForm.GLOBAL_LOCAL,
      Reversibility.LOGGED),
  LOCAL_MOVE(OpcodeIds.LOCAL_MOVE, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  LOCAL_ADD(OpcodeIds.LOCAL_ADD, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_SUB(OpcodeIds.LOCAL_SUB, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_XOR(OpcodeIds.LOCAL_XOR, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_MUL(OpcodeIds.LOCAL_MUL, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_DIV(OpcodeIds.LOCAL_DIV, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_MOD(OpcodeIds.LOCAL_MOD, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_AND(OpcodeIds.LOCAL_AND, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_ROTR32(OpcodeIds.LOCAL_ROTR32, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_EQ(OpcodeIds.LOCAL_EQ, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  LOCAL_LT(OpcodeIds.LOCAL_LT, InstructionForm.LOCAL_BINARY, Reversibility.CHECKED),
  JUMP(OpcodeIds.JUMP, InstructionForm.TARGET, Reversibility.CHECKED),
  JUMP_IF_ZERO(OpcodeIds.JUMP_IF_ZERO, InstructionForm.LOCAL_TARGET, Reversibility.CHECKED),
  LOCAL_LOOP_CHECK(OpcodeIds.LOCAL_LOOP_CHECK, InstructionForm.LOOP_CHECK,
      Reversibility.CHECKED),

  RECORD_NEW(OpcodeIds.RECORD_NEW, InstructionForm.RECORD_NEW, Reversibility.CHECKED),
  RECORD_GET(OpcodeIds.RECORD_GET, InstructionForm.RECORD_GET, Reversibility.CHECKED),
  VARIANT_NEW(OpcodeIds.VARIANT_NEW, InstructionForm.VARIANT_NEW, Reversibility.CHECKED),
  VARIANT_TAG_EQ(OpcodeIds.VARIANT_TAG_EQ, InstructionForm.VARIANT_TAG,
      Reversibility.CHECKED),
  VARIANT_GET(OpcodeIds.VARIANT_GET, InstructionForm.VARIANT_GET, Reversibility.CHECKED),
  ARRAY_NEW(OpcodeIds.ARRAY_NEW, InstructionForm.ARRAY_NEW, Reversibility.CHECKED),
  ARRAY_GET(OpcodeIds.ARRAY_GET, InstructionForm.ARRAY_GET, Reversibility.CHECKED),
  SLICE_NEW(OpcodeIds.SLICE_NEW, InstructionForm.SLICE_NEW, Reversibility.CHECKED),
  SLICE_GET(OpcodeIds.SLICE_GET, InstructionForm.SLICE_GET, Reversibility.CHECKED),

  OWNED_MOVE(OpcodeIds.OWNED_MOVE, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  REGION_NEW(OpcodeIds.REGION_NEW, InstructionForm.REGION_NEW, Reversibility.CHECKED),
  WORDS_ALLOC(OpcodeIds.WORDS_ALLOC, InstructionForm.STORAGE_ALLOC, Reversibility.CHECKED),
  WORDS_GET(OpcodeIds.WORDS_GET, InstructionForm.STORAGE_GET, Reversibility.CHECKED),
  WORDS_SET(OpcodeIds.WORDS_SET, InstructionForm.STORAGE_SET, Reversibility.LOGGED),
  BUFFER_DROP(OpcodeIds.BUFFER_DROP, InstructionForm.LOCAL, Reversibility.CHECKED),
  REGION_DROP(OpcodeIds.REGION_DROP, InstructionForm.LOCAL, Reversibility.CHECKED),
  BYTES_ALLOC(OpcodeIds.BYTES_ALLOC, InstructionForm.STORAGE_ALLOC, Reversibility.CHECKED),
  BYTES_GET(OpcodeIds.BYTES_GET, InstructionForm.STORAGE_GET, Reversibility.CHECKED),
  BYTES_SET(OpcodeIds.BYTES_SET, InstructionForm.STORAGE_SET, Reversibility.LOGGED),
  UTF8_VALID(OpcodeIds.UTF8_VALID, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  UTF8_COUNT(OpcodeIds.UTF8_COUNT, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  BUFFER_LENGTH(OpcodeIds.BUFFER_LENGTH, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  UTF8_SCALAR(OpcodeIds.UTF8_SCALAR, InstructionForm.STORAGE_GET, Reversibility.CHECKED),
  UTF8_WIDTH(OpcodeIds.UTF8_WIDTH, InstructionForm.STORAGE_GET, Reversibility.CHECKED),
  MAP_ALLOC(OpcodeIds.MAP_ALLOC, InstructionForm.STORAGE_ALLOC, Reversibility.CHECKED),
  MAP_PUT(OpcodeIds.MAP_PUT, InstructionForm.MAP_PUT, Reversibility.LOGGED),
  MAP_GET(OpcodeIds.MAP_GET, InstructionForm.MAP_GET, Reversibility.CHECKED),
  MAP_HAS(OpcodeIds.MAP_HAS, InstructionForm.MAP_GET, Reversibility.CHECKED),
  UTF8_FREEZE(OpcodeIds.UTF8_FREEZE, InstructionForm.LOCAL_SOURCE, Reversibility.LOGGED),
  UTF8_BORROW(OpcodeIds.UTF8_BORROW, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  MAP_BORROW(OpcodeIds.MAP_BORROW, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  BUFFER_BORROW(OpcodeIds.BUFFER_BORROW, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  REGION_BORROW(OpcodeIds.REGION_BORROW, InstructionForm.LOCAL_SOURCE, Reversibility.CHECKED),
  OUTPUT_LENGTH(OpcodeIds.OUTPUT_LENGTH, InstructionForm.OUTPUT_LENGTH, Reversibility.LOGGED);

  private final int code;
  private final InstructionForm form;
  private final Reversibility reversibility;

  Opcode(int code, InstructionForm form, Reversibility reversibility) {
    this.code = code;
    this.form = form;
    this.reversibility = reversibility;
  }

  public int code() {
    return code;
  }

  public InstructionForm form() {
    return form;
  }

  public int operandCount() {
    return form.operandCount();
  }

  public Reversibility reversibility() {
    return reversibility;
  }

  public static Opcode fromCode(int code) {
    return Arrays.stream(values())
        .filter(opcode -> opcode.code == code)
        .findFirst()
        .orElseThrow(() -> new BytecodeException("Unknown opcode 0x%04x".formatted(code)));
  }

  public Opcode inverse() {
    return switch (this) {
      case ADD_CONST -> SUB_CONST;
      case SUB_CONST -> ADD_CONST;
      case XOR_CONST, SWAP, NOP, EXPECT_EQ, EXPECT_TRUE, CHECKPOINT -> this;
      case CALL -> UNCALL;
      case UNCALL -> CALL;
      case CALL_RESULT_SLOT -> UNCALL_RESULT_SLOT;
      case UNCALL_RESULT_SLOT -> CALL_RESULT_SLOT;
      case RESULT_FILL_CONSTANT -> RESULT_FILL_CONSTANT;
      case RESULT_FILL_SOURCE -> RESULT_FILL_SOURCE;
      case RESULT_FILL_BINARY -> RESULT_FILL_BINARY;
      default -> throw new IllegalStateException(name() + " has no generated language-level inverse");
    };
  }

  public boolean supportsGeneratedInverse() {
    return switch (this) {
      case ADD_CONST, SUB_CONST, XOR_CONST, SWAP, NOP, EXPECT_EQ, EXPECT_TRUE,
          CHECKPOINT, CALL, UNCALL, CALL_RESULT_SLOT, UNCALL_RESULT_SLOT,
          RESULT_FILL_CONSTANT, RESULT_FILL_SOURCE, RESULT_FILL_BINARY -> true;
      default -> false;
    };
  }
}
