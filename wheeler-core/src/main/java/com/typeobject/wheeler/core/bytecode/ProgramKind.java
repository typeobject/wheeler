package com.typeobject.wheeler.core.bytecode;

public enum ProgramKind {
  CLASSICAL(0),
  QUANTUM(1),
  HYBRID(2);

  private final int code;

  ProgramKind(int code) {
    this.code = code;
  }

  public int code() {
    return code;
  }

  public static ProgramKind fromCode(int code) {
    for (ProgramKind kind : values()) {
      if (kind.code == code) {
        return kind;
      }
    }
    throw new BytecodeException("Unknown program kind " + code);
  }
}
