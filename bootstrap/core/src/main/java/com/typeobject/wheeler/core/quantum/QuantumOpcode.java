package com.typeobject.wheeler.core.quantum;

import com.typeobject.wheeler.core.bytecode.BytecodeException;
import java.util.Arrays;

/** Stable provider-neutral quantum instruction families. */
public enum QuantumOpcode {
  APPLY_GATE(QuantumOpcodeIds.APPLY_GATE, QuantumInstructionForm.GATE),
  CALL_UNITARY(QuantumOpcodeIds.CALL_UNITARY, QuantumInstructionForm.UNITARY_CALL),
  APPLY_SYMBOLIC_GATE(
      QuantumOpcodeIds.APPLY_SYMBOLIC_GATE,
      QuantumInstructionForm.SYMBOLIC_GATE);

  private final int code;
  private final QuantumInstructionForm form;

  QuantumOpcode(int code, QuantumInstructionForm form) {
    this.code = code;
    this.form = form;
  }

  public int code() {
    return code;
  }

  public QuantumInstructionForm form() {
    return form;
  }

  public static QuantumOpcode fromCode(int code) {
    return Arrays.stream(values())
        .filter(opcode -> opcode.code == code)
        .findFirst()
        .orElseThrow(() -> new BytecodeException("Unknown quantum opcode " + code));
  }
}
