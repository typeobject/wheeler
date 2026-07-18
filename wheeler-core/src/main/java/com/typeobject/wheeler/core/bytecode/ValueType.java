package com.typeobject.wheeler.core.bytecode;

/** Canonical scalar register types in the bootstrap frame profile. */
public enum ValueType {
  SIGNED(1),
  BOOLEAN(2);

  private final int code;

  ValueType(int code) {
    this.code = code;
  }

  public int code() {
    return code;
  }

  public static ValueType fromCode(int code) {
    return switch (code) {
      case 1 -> SIGNED;
      case 2 -> BOOLEAN;
      default -> throw new BytecodeException("Unsupported local register type " + code);
    };
  }
}
