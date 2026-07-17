package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import com.typeobject.wheeler.runtime.quantum.QuantumTarget;
import java.util.ArrayList;
import java.util.List;

/** Executes verified classical, quantum, and hybrid Wheeler programs. */
public final class WheelerRuntime {
  public ExecutionResult execute(Program program, QuantumTarget target) {
    VirtualMachine machine = new VirtualMachine(program);
    if (program.kind() == ProgramKind.CLASSICAL) {
      machine.run();
      return result(program, machine, List.of(), machine.snapshot().sequence());
    }
    if (target == null) {
      throw new IllegalArgumentException("A quantum target is required for " + program.kind());
    }

    List<Long> measurements = new ArrayList<>();
    long steps = 0;
    for (WorkflowStep step : program.workflow()) {
      if (++steps > program.maxSteps()) {
        throw new IllegalStateException("Workflow step limit exceeded");
      }
      switch (step.opcode()) {
        case PREPARE -> target.prepare(
            program.quantumRegister(Math.toIntExact(step.first())), step.second());
        case APPLY, UNAPPLY -> target.apply(
            program,
            program.quantumCircuit(Math.toIntExact(step.first())),
            step.opcode() == WorkflowOpcode.UNAPPLY);
        case MEASURE -> {
          long value = target.measure(program.quantumRegister(Math.toIntExact(step.first())));
          measurements.add(value);
          machine.setGlobalFromEffect(Math.toIntExact(step.second()), value);
        }
        case CLASSICAL_CALL, CLASSICAL_UNCALL -> machine.invoke(
            Math.toIntExact(step.first()),
            step.opcode() == WorkflowOpcode.CLASSICAL_UNCALL);
        case EXPECT -> machine.expectGlobal(Math.toIntExact(step.first()), step.second());
        case COMMIT -> machine.commitHistory();
        case HALT -> {
          return result(program, machine, measurements, steps);
        }
      }
    }
    throw new IllegalStateException("Verified workflow did not halt");
  }

  private static ExecutionResult result(
      Program program, VirtualMachine machine, List<Long> measurements, long steps) {
    return new ExecutionResult(
        program.name(), program.kind(), machine.snapshot().globals(), measurements, steps);
  }
}
