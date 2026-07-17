package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.core.workflow.WorkflowOpcode;
import com.typeobject.wheeler.core.workflow.WorkflowStep;
import com.typeobject.wheeler.runtime.quantum.QuantumJob;
import com.typeobject.wheeler.runtime.quantum.QuantumResult;
import com.typeobject.wheeler.runtime.quantum.QuantumTarget;
import com.typeobject.wheeler.runtime.quantum.QuantumTaskBuilder;
import com.typeobject.wheeler.runtime.quantum.TargetCapability;
import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/** Executes verified classical, quantum, and hybrid Wheeler programs. */
public final class WheelerRuntime {
  private static final Duration DEFAULT_JOB_TIMEOUT = Duration.ofMinutes(5);

  public ExecutionResult execute(Program program, QuantumTarget target) {
    VirtualMachine machine = new VirtualMachine(program);
    if (program.kind() == ProgramKind.CLASSICAL) {
      machine.run();
      return result(program, machine, List.of(), List.of(), machine.snapshot().sequence());
    }
    if (target == null) {
      throw new IllegalArgumentException("A quantum target is required for " + program.kind());
    }
    target.descriptor().require(TargetCapability.STATIC_CIRCUIT);

    List<Long> measurements = new ArrayList<>();
    List<String> jobs = new ArrayList<>();
    Map<Integer, QuantumTaskBuilder> pending = new HashMap<>();
    long steps = 0;
    for (WorkflowStep step : program.workflow()) {
      if (++steps > program.maxSteps()) {
        throw new IllegalStateException("Workflow step limit exceeded");
      }
      switch (step.opcode()) {
        case PREPARE -> pending.put(
            Math.toIntExact(step.first()),
            new QuantumTaskBuilder(program, Math.toIntExact(step.first()), step.second()));
        case APPLY, UNAPPLY -> {
          int circuitId = Math.toIntExact(step.first());
          int registerId = program.quantumCircuit(circuitId).registerId();
          requirePending(pending, registerId).apply(
              circuitId, step.opcode() == WorkflowOpcode.UNAPPLY);
        }
        case MEASURE -> {
          int registerId = Math.toIntExact(step.first());
          QuantumTaskBuilder builder = requirePending(pending, registerId);
          QuantumJob job = target.submit(builder.build(1, measurements.size()));
          QuantumResult result = job.await(DEFAULT_JOB_TIMEOUT);
          validateResult(job, result, target);
          long value = result.firstOutcome();
          jobs.add(job.id());
          measurements.add(value);
          machine.setGlobalFromEffect(Math.toIntExact(step.second()), value);
          pending.remove(registerId);
        }
        case CLASSICAL_CALL, CLASSICAL_UNCALL -> machine.invoke(
            Math.toIntExact(step.first()), step.opcode() == WorkflowOpcode.CLASSICAL_UNCALL);
        case EXPECT -> machine.expectGlobal(Math.toIntExact(step.first()), step.second());
        case COMMIT -> machine.commitHistory();
        case HALT -> {
          if (!pending.isEmpty()) {
            throw new IllegalStateException("Workflow halted with unmeasured prepared registers");
          }
          return result(program, machine, measurements, jobs, steps);
        }
      }
    }
    throw new IllegalStateException("Verified workflow did not halt");
  }

  private static QuantumTaskBuilder requirePending(
      Map<Integer, QuantumTaskBuilder> pending, int registerId) {
    QuantumTaskBuilder builder = pending.get(registerId);
    if (builder == null) {
      throw new IllegalStateException("Quantum register is not prepared: " + registerId);
    }
    return builder;
  }

  private static void validateResult(
      QuantumJob job, QuantumResult result, QuantumTarget target) {
    if (!job.id().equals(result.jobId())) {
      throw new IllegalStateException("Quantum result job identity mismatch");
    }
    if (!target.descriptor().target().equals(result.target())) {
      throw new IllegalStateException("Quantum result target identity mismatch");
    }
  }

  private static ExecutionResult result(
      Program program,
      VirtualMachine machine,
      List<Long> measurements,
      List<String> jobs,
      long steps) {
    return new ExecutionResult(
        program.name(), program.kind(), machine.snapshot().globals(), measurements, jobs, steps);
  }
}
