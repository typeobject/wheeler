package com.typeobject.wheeler.core.workflow;

import java.util.Objects;

/** Fixed-width backend-neutral hybrid workflow edge. */
public record WorkflowStep(WorkflowOpcode opcode, long first, long second, long third) {
  public WorkflowStep {
    Objects.requireNonNull(opcode, "opcode");
  }

  public static WorkflowStep prepare(int registerId, long basisState) {
    return new WorkflowStep(WorkflowOpcode.PREPARE, registerId, basisState, 0);
  }

  public static WorkflowStep apply(int circuitId, boolean inverse) {
    return new WorkflowStep(
        inverse ? WorkflowOpcode.UNAPPLY : WorkflowOpcode.APPLY, circuitId, 0, 0);
  }

  public static WorkflowStep measure(int registerId, int globalId) {
    return new WorkflowStep(WorkflowOpcode.MEASURE, registerId, globalId, 0);
  }

  public static WorkflowStep classicalCall(int functionId, boolean inverse) {
    return new WorkflowStep(
        inverse ? WorkflowOpcode.CLASSICAL_UNCALL : WorkflowOpcode.CLASSICAL_CALL,
        functionId,
        0,
        0);
  }

  public static WorkflowStep expect(int globalId, long value) {
    return new WorkflowStep(WorkflowOpcode.EXPECT, globalId, value, 0);
  }

  public static WorkflowStep halt() {
    return new WorkflowStep(WorkflowOpcode.HALT, 0, 0, 0);
  }
}
