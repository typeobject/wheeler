package com.typeobject.wheeler.core.bytecode;

/** Closed signed operation set carried by {@link Opcode#RESULT_FILL_BINARY}. */
public final class ResultBinaryOperation {
  private ResultBinaryOperation() {}

  public static boolean supported(long code) {
    return code == Opcode.LOCAL_ADD.code()
        || code == Opcode.LOCAL_SUB.code()
        || code == Opcode.LOCAL_MUL.code()
        || code == Opcode.LOCAL_DIV.code()
        || code == Opcode.LOCAL_MOD.code()
        || code == Opcode.LOCAL_XOR.code()
        || code == Opcode.LOCAL_AND.code();
  }

  /** Applies one validated operation with ordinary checked Wheeler arithmetic. */
  public static long apply(long code, long left, long right) {
    if (code == Opcode.LOCAL_ADD.code()) {
      return Math.addExact(left, right);
    }
    if (code == Opcode.LOCAL_SUB.code()) {
      return Math.subtractExact(left, right);
    }
    if (code == Opcode.LOCAL_MUL.code()) {
      return Math.multiplyExact(left, right);
    }
    if (code == Opcode.LOCAL_DIV.code()) {
      if (right == 0 || (left == Long.MIN_VALUE && right == -1)) {
        throw new ArithmeticException("invalid checked division");
      }
      return left / right;
    }
    if (code == Opcode.LOCAL_MOD.code()) {
      if (right == 0) {
        throw new ArithmeticException("invalid checked remainder");
      }
      return left % right;
    }
    if (code == Opcode.LOCAL_XOR.code()) {
      return left ^ right;
    }
    if (code == Opcode.LOCAL_AND.code()) {
      return left & right;
    }
    throw new IllegalArgumentException("Unsupported result binary operation: " + code);
  }
}
