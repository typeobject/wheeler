package com.typeobject.wheeler.runtime.hybrid;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import com.typeobject.wheeler.runtime.ExecutionResult;
import com.typeobject.wheeler.runtime.quantum.QuantumTaskBuilder;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Target-free reduction of a workflow from accepted observations. */
final class HybridReplay {
  private final Program program;
  private final HybridEventReducer.HybridReduction reduction;
  private final VirtualMachine machine;
  private final Map<Integer, QuantumTaskBuilder> prepared = new HashMap<>();
  private final List<Long> measurements = new ArrayList<>();
  private final List<String> jobs = new ArrayList<>();

  private HybridReplay(Program program, HybridEventReducer.HybridReduction reduction) {
    this.program = program;
    this.reduction = reduction;
    this.machine = new VirtualMachine(program);
  }

  static ExecutionResult execute(
      Program program, HybridEventReducer.HybridReduction reduction) {
    return new HybridReplay(program, reduction).execute();
  }

  private ExecutionResult execute() {
    int index = 0;
    for (WorkflowStep step : program.workflow()) {
      switch (step.opcode()) {
        case PREPARE -> {
          int register = Math.toIntExact(step.first());
          prepared.put(register, new QuantumTaskBuilder(program, register, step.second()));
        }
        case APPLY, UNAPPLY -> {
          int circuit = Math.toIntExact(step.first());
          int register = program.quantumCircuit(circuit).registerId();
          require(register).apply(circuit, step.opcode() == WorkflowOpcode.UNAPPLY);
        }
        case MEASURE -> applyObservation(index, step);
        case CLASSICAL_CALL, CLASSICAL_UNCALL -> machine.invoke(
            Math.toIntExact(step.first()), step.opcode() == WorkflowOpcode.CLASSICAL_UNCALL);
        case EXPECT -> machine.expectGlobal(Math.toIntExact(step.first()), step.second());
        case COMMIT -> machine.commitHistory();
        case HALT -> {
          if (!prepared.isEmpty()) {
            throw new HybridRunException("Replay halted with prepared registers");
          }
        }
      }
      index++;
    }
    return new ExecutionResult(
        program.name(), program.kind(), machine.snapshot().globals(), measurements, jobs, index);
  }

  private void applyObservation(int index, WorkflowStep step) {
    HybridEventReducer.AppliedObservation observation = reduction.applied().get(index);
    if (observation == null) {
      throw new HybridRunException("Replay lacks observation at workflow edge " + index);
    }
    int register = Math.toIntExact(step.first());
    require(register);
    machine.setGlobalFromEffect(Math.toIntExact(step.second()), observation.value());
    prepared.remove(register);
    measurements.add(observation.value());
    jobs.add(observation.jobId());
  }

  private QuantumTaskBuilder require(int register) {
    QuantumTaskBuilder builder = prepared.get(register);
    if (builder == null) {
      throw new HybridRunException("Replay register is not prepared: " + register);
    }
    return builder;
  }
}
