package com.typeobject.wheeler.core.quantum;

import java.util.List;

/** Regular field groups for provider-neutral quantum instructions. */
public enum QuantumInstructionForm {
  GATE(
      QuantumOperandRole.GATE,
      QuantumOperandRole.QUBIT_WINDOW,
      QuantumOperandRole.PARAMETER_WINDOW),
  SYMBOLIC_GATE(
      QuantumOperandRole.GATE,
      QuantumOperandRole.QUBIT_WINDOW,
      QuantumOperandRole.PARAMETER_NAME,
      QuantumOperandRole.PARAMETER_SCALE),
  UNITARY_CALL(QuantumOperandRole.FUNCTION, QuantumOperandRole.DIRECTION);

  private final List<QuantumOperandRole> roles;

  QuantumInstructionForm(QuantumOperandRole... roles) {
    this.roles = List.of(roles);
  }

  public List<QuantumOperandRole> roles() {
    return roles;
  }

  /** Semantic field groups. Windows have exact lengths supplied by their referenced descriptor. */
  public enum QuantumOperandRole {
    GATE,
    QUBIT_WINDOW,
    PARAMETER_WINDOW,
    PARAMETER_NAME,
    PARAMETER_SCALE,
    FUNCTION,
    DIRECTION
  }
}
