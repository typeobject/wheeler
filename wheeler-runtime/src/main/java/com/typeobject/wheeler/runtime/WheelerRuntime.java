package com.typeobject.wheeler.runtime;

import com.typeobject.wheeler.core.bytecode.Program;
import com.typeobject.wheeler.core.bytecode.ProgramKind;
import com.typeobject.wheeler.core.vm.VirtualMachine;
import com.typeobject.wheeler.runtime.hybrid.HybridRun;
import com.typeobject.wheeler.runtime.quantum.QuantumTarget;
import java.time.Duration;
import java.util.List;

/** Executes verified classical programs and durable hybrid runs. */
public final class WheelerRuntime {
  private static final Duration DEFAULT_JOB_TIMEOUT = Duration.ofMinutes(5);

  public ExecutionResult execute(Program program, QuantumTarget target) {
    return execute(program, target, null);
  }

  public ExecutionResult execute(Program program, QuantumTarget target, byte[] utf8Input) {
    return execute(program, target, utf8Input, -1);
  }

  public ExecutionResult execute(
      Program program, QuantumTarget target, byte[] utf8Input, int outputBytes) {
    if (program.kind() != ProgramKind.CLASSICAL) {
      if (utf8Input != null || outputBytes >= 0) {
        throw new IllegalArgumentException("Host input/output is currently classical only");
      }
      if (target == null) {
        throw new IllegalArgumentException("A quantum target is required for " + program.kind());
      }
      return HybridRun.start(program, target).runToCompletion(DEFAULT_JOB_TIMEOUT);
    }

    VirtualMachine machine = new VirtualMachine(program, utf8Input, outputBytes);
    machine.run();
    return new ExecutionResult(
        program.name(),
        program.kind(),
        machine.snapshot().globals(),
        List.of(),
        List.of(),
        machine.snapshot().sequence(),
        machine.hostOutput());
  }
}
