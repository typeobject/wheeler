package com.typeobject.wheeler.core.bytecode;

import java.util.Arrays;

/** Classical Wheeler opcodes. Numeric codes are stable first-format artifact identities. */
public enum Opcode {
  NOP(0x0000, 0, Reversibility.INTRINSIC),
  HALT(0x0001, 0, Reversibility.CHECKED),
  RETURN(0x0002, 0, Reversibility.CHECKED),

  ADD_CONST(0x0100, 2, Reversibility.INTRINSIC),
  SUB_CONST(0x0101, 2, Reversibility.INTRINSIC),
  XOR_CONST(0x0102, 2, Reversibility.INTRINSIC),
  SWAP(0x0103, 2, Reversibility.INTRINSIC),
  SET_LOGGED(0x0104, 2, Reversibility.LOGGED),

  CALL(0x0200, 1, Reversibility.CHECKED),
  UNCALL(0x0201, 1, Reversibility.CHECKED),
  CALL_VALUE(0x0202, 4, Reversibility.CHECKED),
  RETURN_VALUE(0x0203, 1, Reversibility.CHECKED),

  EXPECT_EQ(0x0300, 2, Reversibility.CHECKED),
  CHECKPOINT(0x0301, 0, Reversibility.INTRINSIC),
  COMMIT(0x0302, 0, Reversibility.BARRIER),

  LOCAL_CONST(0x0400, 2, Reversibility.CHECKED),
  LOCAL_LOAD_GLOBAL(0x0401, 2, Reversibility.CHECKED),
  LOCAL_STORE_GLOBAL(0x0402, 2, Reversibility.LOGGED),
  LOCAL_MOVE(0x0403, 2, Reversibility.CHECKED),
  LOCAL_ADD(0x0410, 3, Reversibility.CHECKED),
  LOCAL_SUB(0x0411, 3, Reversibility.CHECKED),
  LOCAL_XOR(0x0412, 3, Reversibility.CHECKED),
  LOCAL_EQ(0x0420, 3, Reversibility.CHECKED),
  LOCAL_LT(0x0421, 3, Reversibility.CHECKED),
  JUMP(0x0430, 1, Reversibility.CHECKED),
  JUMP_IF_ZERO(0x0431, 2, Reversibility.CHECKED),
  LOCAL_LOOP_CHECK(0x0432, 2, Reversibility.CHECKED),

  RECORD_NEW(0x0500, 4, Reversibility.CHECKED),
  RECORD_GET(0x0501, 3, Reversibility.CHECKED),
  VARIANT_NEW(0x0510, 5, Reversibility.CHECKED),
  VARIANT_TAG_EQ(0x0511, 3, Reversibility.CHECKED),
  VARIANT_GET(0x0512, 4, Reversibility.CHECKED),
  ARRAY_NEW(0x0520, 4, Reversibility.CHECKED),
  ARRAY_GET(0x0521, 3, Reversibility.CHECKED),
  SLICE_NEW(0x0530, 5, Reversibility.CHECKED),
  SLICE_GET(0x0531, 3, Reversibility.CHECKED),

  OWNED_MOVE(0x0540, 2, Reversibility.CHECKED),
  REGION_NEW(0x0541, 3, Reversibility.CHECKED),
  WORDS_ALLOC(0x0542, 3, Reversibility.CHECKED),
  WORDS_GET(0x0543, 3, Reversibility.CHECKED),
  WORDS_SET(0x0544, 3, Reversibility.LOGGED),
  BUFFER_DROP(0x0545, 1, Reversibility.CHECKED),
  REGION_DROP(0x0546, 1, Reversibility.CHECKED),
  BYTES_ALLOC(0x0547, 3, Reversibility.CHECKED),
  BYTES_GET(0x0548, 3, Reversibility.CHECKED),
  BYTES_SET(0x0549, 3, Reversibility.LOGGED),
  UTF8_VALID(0x054a, 2, Reversibility.CHECKED),
  UTF8_COUNT(0x054b, 2, Reversibility.CHECKED),
  BUFFER_LENGTH(0x054c, 2, Reversibility.CHECKED),
  UTF8_SCALAR(0x054d, 3, Reversibility.CHECKED),
  UTF8_WIDTH(0x054e, 3, Reversibility.CHECKED),
  MAP_ALLOC(0x054f, 3, Reversibility.CHECKED),
  MAP_PUT(0x0550, 3, Reversibility.LOGGED),
  MAP_GET(0x0551, 3, Reversibility.CHECKED),
  MAP_HAS(0x0552, 3, Reversibility.CHECKED),
  UTF8_FREEZE(0x0553, 2, Reversibility.LOGGED),
  UTF8_BORROW(0x0554, 2, Reversibility.CHECKED),
  MAP_BORROW(0x0555, 2, Reversibility.CHECKED);

  private final int code;
  private final int operandCount;
  private final Reversibility reversibility;

  Opcode(int code, int operandCount, Reversibility reversibility) {
    this.code = code;
    this.operandCount = operandCount;
    this.reversibility = reversibility;
  }

  public int code() {
    return code;
  }

  public int operandCount() {
    return operandCount;
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
      case XOR_CONST, SWAP, NOP, EXPECT_EQ, CHECKPOINT -> this;
      case CALL -> UNCALL;
      case UNCALL -> CALL;
      default -> throw new IllegalStateException(name() + " has no generated language-level inverse");
    };
  }

  public boolean supportsGeneratedInverse() {
    return switch (this) {
      case ADD_CONST, SUB_CONST, XOR_CONST, SWAP, NOP, EXPECT_EQ, CHECKPOINT, CALL, UNCALL -> true;
      default -> false;
    };
  }
}
