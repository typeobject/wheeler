package com.typeobject.wheeler.core.workflow;

import com.typeobject.wheeler.core.bytecode.BytecodeException;

public enum WorkflowOpcode {
  PREPARE,
  APPLY,
  UNAPPLY,
  MEASURE,
  CLASSICAL_CALL,
  CLASSICAL_UNCALL,
  EXPECT,
  COMMIT,
  HALT;

  public static WorkflowOpcode fromCode(int code) {
    WorkflowOpcode[] values = values();
    if (code < 0 || code >= values.length) {
      throw new BytecodeException("Unknown workflow opcode " + code);
    }
    return values[code];
  }
}
