package com.typeobject.wheeler.core.quantum;

import java.util.List;

/** Provider-neutral semantic fields required by one gate application. */
public enum GateForm {
  FIXED_SINGLE(GateOperandRole.TARGET),
  ANGLE_SINGLE(GateOperandRole.TARGET, GateOperandRole.ANGLE),
  FIXED_PAIR(GateOperandRole.CONTROL, GateOperandRole.TARGET),
  ANGLE_PAIR(GateOperandRole.CONTROL, GateOperandRole.TARGET, GateOperandRole.ANGLE);

  private final List<GateOperandRole> roles;

  GateForm(GateOperandRole... roles) {
    this.roles = List.of(roles);
  }

  public List<GateOperandRole> roles() {
    return roles;
  }

  public int qubitCount() {
    return (int) roles.stream().filter(GateOperandRole::isQubit).count();
  }

  public int parameterCount() {
    return roles.size() - qubitCount();
  }

  /** Stable semantic positions. */
  public enum GateOperandRole {
    CONTROL,
    TARGET,
    ANGLE;

    boolean isQubit() {
      return this != ANGLE;
    }
  }
}
