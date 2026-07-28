package com.typeobject.wheeler.core.quantum;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import java.util.Arrays;

/** Stable provider-neutral gates. Targets may decompose them into native operations. */
public enum Gate {
  H(GateIds.H, GateForm.FIXED_SINGLE),
  X(GateIds.X, GateForm.FIXED_SINGLE),
  Z(GateIds.Z, GateForm.FIXED_SINGLE),
  PHASE(GateIds.PHASE, GateForm.ANGLE_SINGLE),
  CPHASE(GateIds.CPHASE, GateForm.ANGLE_PAIR),
  CNOT(GateIds.CNOT, GateForm.FIXED_PAIR),
  CZ(GateIds.CZ, GateForm.FIXED_PAIR),
  SWAP(GateIds.SWAP, GateForm.FIXED_PAIR);

  private final int code;
  private final GateForm form;

  Gate(int code, GateForm form) {
    this.code = code;
    this.form = form;
  }

  public int code() {
    return code;
  }

  public GateForm form() {
    return form;
  }

  public int arity() {
    return form.qubitCount();
  }

  public boolean parameterized() {
    return form.parameterCount() != 0;
  }

  public double inverseParameter(double parameter) {
    return parameterized() ? -parameter : parameter;
  }

  public static Gate fromCode(int code) {
    return Arrays.stream(values())
        .filter(gate -> gate.code == code)
        .findFirst()
        .orElseThrow(() -> new BytecodeException("Unknown semantic gate " + code));
  }
}
