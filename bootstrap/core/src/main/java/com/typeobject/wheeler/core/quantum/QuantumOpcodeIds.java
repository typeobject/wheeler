package com.typeobject.wheeler.core.quantum;

/** Stable identities for provider-neutral quantum instruction families. */
final class QuantumOpcodeIds {
  static final int APPLY_GATE = 1;
  static final int CALL_UNITARY = 2;
  static final int APPLY_SYMBOLIC_GATE = 3;
  static final int PREPARE_REGISTER = 4;
  static final int MEASURE_QUBIT = 5;
  static final int RESET_QUBIT = 6;
  static final int APPLY_CONDITIONAL_GATE = 7;

  private QuantumOpcodeIds() {}
}
