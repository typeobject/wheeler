package com.typeobject.wheeler.core.quantum;

import com.typeobject.wheeler.core.bytecode.BytecodeException;

/** Stable semantic gates. Targets may decompose them into native operations. */
public enum Gate {
  H(1),
  X(1),
  Z(1),
  PHASE(1),
  CPHASE(2),
  CNOT(2),
  CZ(2),
  SWAP(2);

  private final int arity;

  Gate(int arity) {
    this.arity = arity;
  }

  public int arity() {
    return arity;
  }

  public double inverseParameter(double parameter) {
    return this == PHASE || this == CPHASE ? -parameter : parameter;
  }

  public static Gate fromCode(int code) {
    Gate[] values = values();
    if (code < 0 || code >= values.length) {
      throw new BytecodeException("Unknown semantic gate " + code);
    }
    return values[code];
  }
}
