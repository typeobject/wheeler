package com.typeobject.wheeler.core.bytecode;

import java.util.Arrays;

/** Version-1 classical Wheeler opcodes. Numeric codes are stable artifact identities. */
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

  EXPECT_EQ(0x0300, 2, Reversibility.CHECKED),
  CHECKPOINT(0x0301, 0, Reversibility.INTRINSIC),
  COMMIT(0x0302, 0, Reversibility.BARRIER);

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
